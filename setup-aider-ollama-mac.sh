#!/bin/zsh
# setup-aider-ollama-mac.sh — Install and configure Aider + Ollama on macOS

set -e

VENV_DIR="$HOME/aider-env"
AIDER_CONFIG_DIR="$HOME/.aider"
BIN_DIR="$HOME/bin"
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

# ─── Step 7: Shell integration ────────────────────────────────────────────

print_header "Shell integration"

ZSHRC="$HOME/.zshrc"
ALIAS_LINE='alias aider-local="$HOME/bin/aider-local"'
PATH_LINE='export PATH="$HOME/bin:$PATH"'

if ! grep -q 'aider-local' "$ZSHRC" 2>/dev/null; then
  echo "" >> "$ZSHRC"
  echo "# Aider + Ollama" >> "$ZSHRC"
  echo "$PATH_LINE" >> "$ZSHRC"
  echo "$ALIAS_LINE" >> "$ZSHRC"
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
