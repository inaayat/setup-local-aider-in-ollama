# Troubleshooting

## Python dependency issues / install failures

**Symptom:** Setup script fails with "Python version not supported" or pip install errors.

**Cause:** Using system Python or Python 3.11 instead of Python 3.12.

**Fix:** Install Python 3.12 explicitly:
```bash
brew install python@3.12
bash setup-aider-ollama-mac.sh
```
The setup script should detect and use Python 3.12 automatically.

---

## Ollama not responding

**Symptom:** Aider says "Connection refused" or "Cannot connect to http://127.0.0.1:11434".

**Cause:** Ollama server is not running.

**Fix:** Start Ollama in a dedicated terminal:
```bash
ollama serve
```
Keep this terminal open. You should see "Listening on 127.0.0.1:11434". Verify it is reachable:
```bash
curl http://127.0.0.1:11434/api/tags
```
This should return a JSON list of available models.

---

## Aider says "I am a text-based AI and cannot create files"

**Symptom:** Aider refuses to write files or claims it has no file creation ability.

**Cause:** System instructions (AIDER_INSTRUCTIONS.md) are not being loaded. The launcher may not be reading the instructions file, or it is not found.

**Fix:** Verify the instructions file exists:
```bash
cat ~/.aider/AIDER_INSTRUCTIONS.md
```
If missing, re-run the setup script. Then verify the launcher is loading it:
```bash
cat ~/bin/aider-local
```
Look for a line containing `--read` and `AIDER_INSTRUCTIONS.md`. If it is there, restart Aider.

---

## Model menu appeared twice during setup

**Symptom:** During setup, you see the model selection menu twice or setup exits unexpectedly.

**Cause:** Duplicate conditional block in the setup script.

**Fix:** Re-download the repository and run setup again:
```bash
cd ~/setup-local-aider-in-ollama
git pull origin main
bash setup-aider-ollama-mac.sh
```

---

## `bash: syntax error near unexpected token fi`

**Symptom:** Setup script exits with a bash syntax error during execution.

**Cause:** Broken if/fi structure in the script.

**Fix:** Validate the script syntax:
```bash
bash -n setup-aider-ollama-mac.sh
```
If it reports errors, the script file may be corrupted. Re-download it:
```bash
cd ~/setup-local-aider-in-ollama
git pull origin main
```

---

## Git 403 permission error on push

**Symptom:** When pushing to GitHub, you get "fatal: HTTP/2 403" or "permission denied".

**Cause:** Missing GitHub SSH keys or incorrect authentication.

**Fix:** Use one of:
1. **SSH keys (recommended):** Set up GitHub SSH keys ([https://docs.github.com/en/authentication/connecting-to-github-with-ssh](https://docs.github.com/en/authentication/connecting-to-github-with-ssh))
2. **HTTPS with token:** Use a personal access token instead of your password ([https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens))

---

## `aider-local` command not found

**Symptom:** Terminal says "`aider-local: command not found`".

**Cause:** `~/bin` is not on your PATH.

**Fix:** Add this line to your shell config (~/.zshrc):
```bash
export PATH="$HOME/bin:$PATH"
```
Then reload:
```bash
source ~/.zshrc
```
Verify the launcher exists:
```bash
ls -la ~/bin/aider-local
```

---

## Model not found / pull fails

**Symptom:** Setup or Aider says "Model not found" or "Failed to pull model".

**Cause:** Model not yet downloaded, or insufficient disk space.

**Fix:** Download the model manually:
```bash
ollama pull gemma3:4b
```
(Replace with your chosen model.) Check available disk space:
```bash
df -h
```
Aider models range from 4 GB to 30 GB; ensure you have enough space.

---

## Ollama starts but Aider can't connect

**Symptom:** Ollama is running, but Aider says "Cannot connect to Ollama".

**Cause:** `OLLAMA_API_BASE` environment variable is not set.

**Fix:** Verify the launcher exports the API base:
```bash
cat ~/bin/aider-local | grep OLLAMA_API_BASE
```
You should see:
```
export OLLAMA_API_BASE=http://127.0.0.1:11434
```
If missing, re-run setup. Then test connectivity from command line:
```bash
curl http://127.0.0.1:11434/api/tags
```

---

## `git index.lock` error

**Symptom:** Git operations fail with "fatal: Unable to create '.git/index.lock': File exists".

**Cause:** Stale lock file from a previous interrupted git operation.

**Fix:** Remove the lock file:
```bash
rm -f .git/index.lock
```
Then retry your git command.

---

## Quick Diagnostic Commands

Run these to diagnose setup issues:

```bash
# List available models in Ollama
ollama list

# Start Ollama server (if not running)
ollama serve

# Test Ollama API connectivity
curl http://127.0.0.1:11434/api/tags

# Validate setup script syntax
bash -n setup-aider-ollama-mac.sh

# Run full verification
bash verify-setup.sh

# Check if launcher exists and is executable
ls -la ~/bin/aider-local
```
