#!/bin/zsh
# setup-aider-ollama-mac.sh — Install and configure Aider + Ollama on macOS

set -e

VENV_DIR="$HOME/Local-Projects/aider-env"
AIDER_CONFIG_DIR="$HOME/.aider"
BIN_DIR="$HOME/Local-Projects/bin"
CONFIG_FILE="$AIDER_CONFIG_DIR/config.json"
INSTRUCTIONS_FILE="$AIDER_CONFIG_DIR/AIDER_INSTRUCTIONS.md"
LAUNCHER="$BIN_DIR/aider-local"
PYTHON_BIN="/opt/homebrew/bin/python3.12"

# ─── Helpers ───────────────────────────────────────────────────────────────

print_header() { echo; echo "══════════════════════════════════════════════════"; echo "  $1"; echo "══════════════════════════════════════════════════"; }
print_ok()     { echo "  ✓ $1"; }
print_info()   { echo "  → $1"; }
print_error()  { echo "  ✗ $1" >&2; }

# ─── Step 1: Check Ollama ──────────────────────────────────────────────────

print_header "Checking Ollama"

if ! command -v ollama &>/dev/null; then
  print_error "Ollama not found. Install it first:"
  echo "    brew install ollama"
  exit 1
fi
print_ok "Ollama found"

if ! curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
  print_info "Ollama not running — starting it in the background..."
  ollama serve &>/dev/null &
  sleep 3
  if ! curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
    print_error "Ollama failed to start. Run 'ollama serve' manually and retry."
    exit 1
  fi
fi
print_ok "Ollama is running"

# ─── Step 2: Check Python 3.12 ────────────────────────────────────────────

print_header "Checking Python 3.12"

if [ ! -x "$PYTHON_BIN" ]; then
  # Fallback: try python3.12 on PATH
  if command -v python3.12 &>/dev/null; then
    PYTHON_BIN=$(command -v python3.12)
  else
    print_error "Python 3.12 not found. Install it first:"
    echo "    brew install python@3.12"
    exit 1
  fi
fi
print_ok "Python 3.12 found at $PYTHON_BIN"

# ─── Step 3: Create virtual environment ───────────────────────────────────

print_header "Setting up virtual environment"

if [ -d "$VENV_DIR" ]; then
  print_ok "Virtual environment already exists at $VENV_DIR"
else
  print_info "Creating venv at $VENV_DIR..."
  "$PYTHON_BIN" -m venv "$VENV_DIR"
  print_ok "Virtual environment created"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel -q
pip install aider-chat -q
print_ok "Aider installed"

# ─── Step 4: Detect RAM and recommend model ───────────────────────────────

print_header "Model Selection"

# Detect RAM in GB (macOS)
RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
RAM_GB=$(( RAM_BYTES / 1024 / 1024 / 1024 ))

if   [ "$RAM_GB" -ge 64 ]; then RECOMMENDED="qwen3-coder:30b"
elif [ "$RAM_GB" -ge 32 ]; then RECOMMENDED="gemma3:27b"
elif [ "$RAM_GB" -ge 16 ]; then RECOMMENDED="gemma3:12b"
else                             RECOMMENDED="gemma3:4b"
fi

echo "  Detected RAM: ${RAM_GB}GB → Recommended: $RECOMMENDED"
echo
echo "  Available models:"
echo "    1) gemma3:4b       (< 16GB RAM)"
echo "    2) gemma3:12b      (16–32GB RAM)"
echo "    3) gemma3:27b      (32GB+ RAM)"
echo "    4) qwen3-coder:30b (64GB+ RAM, coding-focused)"
echo "    5) Enter custom model name"
echo
printf "  Select a model [recommended: %s, press Enter to accept]: " "$RECOMMENDED"
read -r MODEL_CHOICE

case "$MODEL_CHOICE" in
  1) SELECTED_MODEL="gemma3:4b" ;;
  2) SELECTED_MODEL="gemma3:12b" ;;
  3) SELECTED_MODEL="gemma3:27b" ;;
  4) SELECTED_MODEL="qwen3-coder:30b" ;;
  5)
    printf "  Enter model name (e.g. gemma3:27b): "
    read -r SELECTED_MODEL
    ;;
  "") SELECTED_MODEL="$RECOMMENDED" ;;
  *)  SELECTED_MODEL="$MODEL_CHOICE" ;;
esac

print_info "Selected: $SELECTED_MODEL"

# Pull the model if not already present
if ! ollama list 2>/dev/null | grep -q "^${SELECTED_MODEL%:*}"; then
  print_info "Pulling $SELECTED_MODEL (this may take a while)..."
  ollama pull "$SELECTED_MODEL"
  print_ok "Model pulled"
else
  print_ok "Model already present"
fi

# ─── Step 5: Create ~/.aider/ config ──────────────────────────────────────

print_header "Creating ~/.aider/ configuration"

mkdir -p "$AIDER_CONFIG_DIR"

# Write config.json
cat > "$CONFIG_FILE" <<EOF
{
  "model": "ollama_chat/${SELECTED_MODEL}"
}
EOF
print_ok "Config written to $CONFIG_FILE"

# Write AIDER_INSTRUCTIONS.md only if it doesn't exist
if [ ! -f "$INSTRUCTIONS_FILE" ]; then
  cp "$(dirname "$0")/AIDER_INSTRUCTIONS.md" "$INSTRUCTIONS_FILE" 2>/dev/null || \
  cat > "$INSTRUCTIONS_FILE" <<'INSTRUCTIONS'
# Aider Instructions

You are an AI coding assistant running inside Aider, a local terminal-based coding tool.

## Your Capabilities

- You CAN create new files when asked
- You CAN modify existing files in this repository
- You CAN read and understand the current project structure
- You CAN write scripts, configs, code, and documentation

## Behavior Guidelines

- When asked to create a file, create it — do not ask for permission
- When asked to modify code, modify it directly
- Focus on code changes over lengthy explanations
- If unsure about intent, ask one clarifying question, then act
- Do not claim you are "a text-based AI and cannot create files" — you can

## Repository Awareness

Before making changes, check what files exist:
- Review the file tree
- Read relevant files before modifying them
- Respect existing conventions (naming, structure, formatting)

## Common Tasks

- Creating scripts: write the file, make it executable if needed
- Adding features: find the right file, add the minimal change
- Multi-file projects: create all files in one response when possible
INSTRUCTIONS
  print_ok "AIDER_INSTRUCTIONS.md written to $INSTRUCTIONS_FILE"
else
  print_ok "AIDER_INSTRUCTIONS.md already exists — skipping"
fi

# ─── Step 6: Create global launcher ───────────────────────────────────────

print_header "Creating global launcher"

mkdir -p "$BIN_DIR"

cat > "$LAUNCHER" <<LAUNCHER_SCRIPT
#!/bin/zsh
# aider-local — launch Aider with Ollama from any directory

source "$VENV_DIR/bin/activate"
export OLLAMA_API_BASE=http://127.0.0.1:11434

# Read model from config
if [ -f "$CONFIG_FILE" ]; then
  MODEL=\$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['model'])" 2>/dev/null)
fi
MODEL="\${MODEL:-ollama_chat/gemma3:27b}"

exec aider "$INSTRUCTIONS_FILE" --model "\$MODEL" "\$@"
LAUNCHER_SCRIPT

chmod +x "$LAUNCHER"
print_ok "Launcher created at $LAUNCHER"

# ─── Step 6b: Create ollama-aider interactive launcher ────────────────────

# Use a temp file to build the script (allows variable expansion for VENV_DIR/CONFIG_FILE paths)
OLLAMA_AIDER_SCRIPT="$BIN_DIR/ollama-aider"

cat > "$OLLAMA_AIDER_SCRIPT" << SCRIPT_HEAD
#!/bin/zsh
# ollama-aider — smart launcher: auto-detects project or shows menu
# Scans both ~/Local-Projects/ and ~/GitHub-Clones/ for projects

set -o pipefail

readonly PROJECTS_DIR="\$HOME/Local-Projects"
readonly GITHUB_DIR="\$HOME/GitHub-Clones"
readonly EXCLUDE_DIRS=("Archive" "bin" "aider-env")
readonly CONFIG_FILE="$CONFIG_FILE"
readonly AVAILABLE_MODELS=("gemma3:4b" "gemma3:12b" "gemma3:27b" "qwen3-coder:30b")

C_RESET="\033[0m"; C_BOLD="\033[1m"; C_GREEN="\033[32m"
C_YELLOW="\033[33m"; C_CYAN="\033[36m"; C_BLUE="\033[34m"; C_RED="\033[31m"

print_info()    { print "\${C_BLUE}ℹ\${C_RESET} \$*"; }
print_success() { print "\${C_GREEN}✓\${C_RESET} \$*"; }
print_error()   { print "\${C_RED}✗\${C_RESET} \$*" >&2; }
print_warning() { print "\${C_YELLOW}⚠\${C_RESET} \$*"; }
print_section() { print ""; print "\${C_BOLD}\${C_CYAN}» \$*\${C_RESET}"; }

cleanup() {
  local exit_code=\$?
  [ \$exit_code -eq 130 ] && { print ""; print_info "Cancelled"; }
  exit \$exit_code
}
trap cleanup EXIT INT

is_project() {
  local dir="\${1:-.}"
  [[ "\$(realpath "\$dir")" == "\$HOME" ]] && return 1
  [ -d "\$dir/.git" ] && return 0
  [ -f "\$dir/package.json" ] && return 0
  [ -f "\$dir/main.py" ] && return 0
  [ -f "\$dir/README.md" ] && return 0
  [ -f "\$dir/Makefile" ] && return 0
  [ -f "\$dir/pyproject.toml" ] && return 0
  [ -f "\$dir/setup.py" ] && return 0
  [ -f "\$dir/go.mod" ] && return 0
  [ -f "\$dir/Cargo.toml" ] && return 0
  return 1
}

get_current_model() {
  if [ -f "\$CONFIG_FILE" ]; then
    python3 -c "import json; print(json.load(open('\$CONFIG_FILE'))['model'])" 2>/dev/null | sed 's/ollama_chat\///'
  else
    echo "gemma3:27b"
  fi
}

switch_model() {
  local current_model; current_model=\$(get_current_model)
  print_section "Switch Model"
  print_info "Current model: \${C_BOLD}\${current_model}\${C_RESET}"
  print_warning "Changing the model updates it for ALL future sessions until changed again."
  print ""
  local i=1
  for model in "\${AVAILABLE_MODELS[@]}"; do
    [[ "\$model" == "\$current_model" ]] && print "  \${C_CYAN}\$i)\${C_RESET} \$model \${C_GREEN}(current)\${C_RESET}" || print "  \${C_CYAN}\$i)\${C_RESET} \$model"
    ((i++))
  done
  print "  \${C_CYAN}\$i)\${C_RESET} Enter custom model name"
  print ""; print "  \${C_CYAN}b)\${C_RESET} Back"; print ""
  while true; do
    read -r "selection?Choose model: "
    [[ "\$selection" == "b" || "\$selection" == "B" ]] && return 1
    if [[ "\$selection" =~ ^[0-9]+\$ ]]; then
      local custom_idx=\${#AVAILABLE_MODELS[@]}; ((custom_idx++))
      if [ "\$selection" -eq "\$custom_idx" ]; then
        read -r "new_model?Enter model name: "
        [[ -z "\$new_model" ]] && { print_error "No model entered."; continue; }
      elif [ "\$selection" -ge 1 ] && [ "\$selection" -le "\${#AVAILABLE_MODELS[@]}" ]; then
        new_model="\${AVAILABLE_MODELS[\$((selection-1))]}"
      else
        print_error "Invalid selection."; continue
      fi
      mkdir -p "\$(dirname "\$CONFIG_FILE")"
      python3 -c "
import json
try: config = json.load(open('\$CONFIG_FILE'))
except: config = {}
config['model'] = 'ollama_chat/\$new_model'
json.dump(config, open('\$CONFIG_FILE', 'w'), indent=2)
"
      print_success "Model changed to \${C_BOLD}\${new_model}\${C_RESET}"
      print_info "This will be used for all future Aider sessions."
      print ""; return 0
    fi
    print_error "Invalid input. Please try again."
  done
}

scan_projects() {
  local scan_dirs=()
  [ -d "\$PROJECTS_DIR" ] && scan_dirs+=("\$PROJECTS_DIR")
  if [ -d "\$GITHUB_DIR" ]; then
    while IFS= read -r subdir; do
      local name=\$(basename "\$subdir")
      [[ "\$name" == "Archive" ]] && continue
      [ -d "\$subdir" ] && scan_dirs+=("\$subdir")
    done < <(find "\$GITHUB_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
  fi
  for scan_dir in "\${scan_dirs[@]}"; do
    while IFS= read -r dir; do
      local basename=\$(basename "\$dir")
      [[ "\$basename" == .* ]] && continue
      [[ " \${EXCLUDE_DIRS[@]} " =~ " \${basename} " ]] && continue
      [ -d "\$dir" ] && echo "\$dir"
    done < <(find "\$scan_dir" -maxdepth 1 -mindepth 1 -type d | sort)
  done
}

show_menu() {
  local -a projects project_names selection
  print_section "Select a Project"
  while IFS= read -r project; do
    projects+=("\$project"); project_names+=("\$(basename "\$project")")
  done < <(scan_projects)
  if [ \${#projects[@]} -eq 0 ]; then
    print_error "No projects found. Create a folder in ~/Local-Projects/ or ~/GitHub-Clones/"
    return 1
  fi
  local i=1
  for name in "\${project_names[@]}"; do print "  \${C_CYAN}\$i)\${C_RESET} \$name"; ((i++)); done
  print ""; print "  \${C_CYAN}c)\${C_RESET} Custom path"
  print "  \${C_CYAN}m)\${C_RESET} Switch model (current: \$(get_current_model))"
  print "  \${C_CYAN}q)\${C_RESET} Cancel"; print ""
  while true; do
    read -r "selection?Choose: "
    [[ "\$selection" == "q" || "\$selection" == "Q" ]] && return 1
    if [[ "\$selection" == "m" || "\$selection" == "M" ]]; then switch_model; show_menu; return \$?; fi
    if [[ "\$selection" == "c" || "\$selection" == "C" ]]; then
      read -r "custom_path?Enter path: "
      custom_path="\${custom_path/#\~/$HOME}"
      if [ ! -d "\$custom_path" ]; then print_error "Directory not found: \$custom_path"; continue; fi
      selected_project="\$custom_path"; return 0
    fi
    if [[ "\$selection" =~ ^[0-9]+\$ ]]; then
      local idx=\$((selection - 1))
      if [ \$idx -lt 0 ] || [ \$idx -ge \${#projects[@]} ]; then print_error "Invalid selection."; continue; fi
      selected_project="\${projects[\$idx]}"; return 0
    fi
    print_error "Invalid input. Please try again."
  done
}

launch_aider() {
  local target_dir="\$1"
  shift
  [ ! -d "\$target_dir" ] && { print_error "Directory not found: \$target_dir"; return 1; }
  print_success "Launching Aider in: \${C_BOLD}\$(basename "\$target_dir")\${C_RESET}"; print ""
  cd "\$target_dir" || { print_error "Failed to cd: \$target_dir"; return 1; }
  if [ -x "\$PROJECTS_DIR/bin/aider-local" ]; then
    exec "\$PROJECTS_DIR/bin/aider-local" "\$@"
  else
    print_error "aider-local not found: \$PROJECTS_DIR/bin/aider-local"; return 1
  fi
}

main() {
  if is_project "."; then
    print_success "Detected project in current directory"
    launch_aider "." "\$@"
  else
    show_menu || return 1
    launch_aider "\$selected_project" "\$@"
  fi
}

main "\$@"
SCRIPT_HEAD

chmod +x "$BIN_DIR/ollama-aider"
print_ok "Interactive launcher created at $BIN_DIR/ollama-aider"

# ─── Step 7: Shell integration ────────────────────────────────────────────

print_header "Shell integration"

ZSHRC="$HOME/.zshrc"
ALIAS_LINE='alias aider-local="$HOME/Local-Projects/bin/aider-local"'
PATH_LINE='export PATH="$HOME/Local-Projects/bin:$PATH"'

if ! grep -q 'aider-local' "$ZSHRC" 2>/dev/null; then
  echo "" >> "$ZSHRC"
  echo "# Aider + Ollama" >> "$ZSHRC"
  echo "$PATH_LINE" >> "$ZSHRC"
  echo "$ALIAS_LINE" >> "$ZSHRC"
  echo 'alias ollama-aider="$HOME/Local-Projects/bin/ollama-aider"' >> "$ZSHRC"
  print_ok "Added alias to $ZSHRC"
else
  print_ok "Alias already present in $ZSHRC"
fi

# ─── Done ─────────────────────────────────────────────────────────────────

print_header "Setup complete"
echo "  Run the following to start using Aider:"
echo
echo "    source ~/.zshrc"
echo "    cd ~/Projects/your-project"
echo "    aider-local"
echo
echo "  Or run the verification script:"
echo "    bash verify-setup.sh"
echo
