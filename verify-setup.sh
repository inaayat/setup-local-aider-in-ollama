#!/bin/zsh
# verify-setup.sh — Validate Aider + Ollama installation

VENV_DIR="$HOME/aider-env"
AIDER_CONFIG_DIR="$HOME/.aider"
CONFIG_FILE="$AIDER_CONFIG_DIR/config.json"
INSTRUCTIONS_FILE="$AIDER_CONFIG_DIR/AIDER_INSTRUCTIONS.md"
LAUNCHER="$HOME/bin/aider-local"

PASS=0
FAIL=0

check() {
  local label="$1"
  local result="$2"
  if [ "$result" = "ok" ]; then
    echo "  ✓ $label"
    (( PASS++ ))
  else
    echo "  ✗ $label — $result"
    (( FAIL++ ))
  fi
}

echo
echo "Aider + Ollama Setup Verification"
echo "══════════════════════════════════"
echo

# Ollama
if command -v ollama &>/dev/null; then
  check "Ollama installed" "ok"
else
  check "Ollama installed" "not found — run: brew install ollama"
fi

if curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
  check "Ollama running" "ok"
else
  check "Ollama running" "not responding — run: ollama serve"
fi

# Python
if command -v python3.12 &>/dev/null || [ -x /opt/homebrew/bin/python3.12 ]; then
  check "Python 3.12 available" "ok"
else
  check "Python 3.12 available" "not found — run: brew install python@3.12"
fi

# Virtual environment
if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/activate" ]; then
  check "Virtual environment ($VENV_DIR)" "ok"
else
  check "Virtual environment ($VENV_DIR)" "not found — run setup script"
fi

# Aider installed
if source "$VENV_DIR/bin/activate" 2>/dev/null && command -v aider &>/dev/null; then
  check "Aider installed in venv" "ok"
else
  check "Aider installed in venv" "not found — run: pip install aider-chat"
fi

# Config
if [ -f "$CONFIG_FILE" ]; then
  MODEL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['model'])" 2>/dev/null)
  check "Config file ($CONFIG_FILE)" "ok — model: $MODEL"
else
  check "Config file ($CONFIG_FILE)" "not found — run setup script"
fi

# Instructions
if [ -f "$INSTRUCTIONS_FILE" ]; then
  check "AIDER_INSTRUCTIONS.md" "ok"
else
  check "AIDER_INSTRUCTIONS.md" "not found at $INSTRUCTIONS_FILE"
fi

# Launcher
if [ -x "$LAUNCHER" ]; then
  check "Launcher ($LAUNCHER)" "ok"
else
  check "Launcher ($LAUNCHER)" "not found or not executable — run setup script"
fi

# PATH
if echo "$PATH" | grep -q "$HOME/bin"; then
  check "~/bin on PATH" "ok"
else
  check "~/bin on PATH" "not on PATH — add to ~/.zshrc: export PATH=\"\$HOME/bin:\$PATH\""
fi

# Summary
echo
echo "══════════════════════════════════"
echo "  Passed: $PASS   Failed: $FAIL"
echo

if [ "$FAIL" -gt 0 ]; then
  echo "  Some checks failed. See TROUBLESHOOTING.md for fixes."
  exit 1
else
  echo "  All checks passed. Run: cd ~/Projects/your-project && aider-local"
fi
echo
