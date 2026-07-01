# Aider + Ollama on macOS

Run an AI coding assistant entirely offline on your Mac using Aider and Ollama.

## What This Is

Aider is an AI coding assistant that runs in your terminal. Ollama runs LLMs locally on your machine. Together they give you a private, offline AI coding setup — no API keys, no internet dependency, full control.

## Quick Install (One Command)

If you have Homebrew, Ollama, and Python 3.12 already installed, you can run the full setup with a single curl command:

```bash
curl -fsSL https://raw.githubusercontent.com/inaayat/setup-local-aider-in-ollama/main/setup-aider-ollama-mac.sh | bash
```

Then reload your shell:
```bash
source ~/.zshrc
```

> **New to this?** Follow the step-by-step instructions below instead — they walk you through installing the prerequisites first.

---

## Prerequisites

- **macOS** (Apple Silicon or Intel)
- **Homebrew** installed ([https://brew.sh](https://brew.sh))

## First-Time Installation (Step by Step)

1. **Install Ollama**
   ```bash
   brew install ollama
   ```

2. **Start Ollama**
   ```bash
   ollama serve
   ```
   This command starts the Ollama server and must be running in the background. Leave this terminal tab open while you use Aider.

3. **Install Python 3.12**
   ```bash
   brew install python@3.12
   ```

4. **Clone This Repo**
   ```bash
   git clone https://github.com/inaayat/setup-local-aider-in-ollama.git
   cd setup-local-aider-in-ollama
   ```

5. **Run the Setup Script**
   ```bash
   bash setup-aider-ollama-mac.sh
   ```
   This script will:
   - Create a Python virtual environment
   - Install Aider and dependencies
   - Prompt you to select a model to use
   - Set up the global launcher at `~/bin/aider-local`

6. **Reload Your Shell**
   ```bash
   source ~/.zshrc
   ```

7. **Verify Your Setup**
   ```bash
   bash verify-setup.sh
   ```
   This confirms all components are installed and reachable.

## Starting Aider Each Time You Use It

1. Open a terminal.

2. Make sure Ollama is running:
   ```bash
   ollama serve
   ```
   If it is already running in another terminal tab or as a background service, you do not need to run this again. Aider needs Ollama to be active to function.

3. Navigate to your project:
   ```bash
   cd ~/Projects/your-project
   ```

4. Launch Aider:
   ```bash
   aider-local
   ```
   The launcher will load your saved instructions, connect to Ollama, and enter an interactive chat session.

5. Type prompts to edit code. Aider will read files, propose changes, and apply them.

6. Exit Aider by typing `/exit` or pressing Ctrl+C.

## Architecture

```
~/
├── aider-env/                    # Python virtual environment (created by installer)
├── .aider/
│   ├── AIDER_INSTRUCTIONS.md     # System instructions for Aider behavior
│   └── config.json               # Stores your selected model
├── bin/
│   └── aider-local               # Global launcher script
└── Projects/                     # Your code projects live here
```

## Choosing a Model

Select a model based on available RAM:

| RAM              | Recommended Model   | Notes                          |
|------------------|---------------------|--------------------------------|
| < 16 GB          | `gemma3:4b`         | Compact; fast; lower accuracy  |
| 16–32 GB         | `gemma3:12b`        | Good balance                   |
| 32–64 GB         | `gemma3:27b`        | Stronger reasoning             |
| 64+ GB           | `qwen3-coder:30b`   | Specialized for code           |

You can re-run the setup script at any time to switch models:
```bash
bash setup-aider-ollama-mac.sh
```

## Verify Your Setup

Run the verification script to confirm all components are working:
```bash
bash verify-setup.sh
```

This will check:
- Python and Aider are installed
- Ollama server is reachable
- Configuration file is in place

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions to common issues.
