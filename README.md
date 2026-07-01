# Aider + Ollama on macOS

Run an AI coding assistant entirely offline on your Mac using Aider and Ollama.

## What This Is

Think of this as ChatGPT for code, but running entirely on your computer.

**Ollama** is a tool that downloads and runs AI models (like ChatGPT or Claude) on your Mac. They run in the background and you can talk to them without sending anything to the internet.

**Aider** is a terminal application that acts as your coding assistant. You describe what you want to do, and it reads your code, makes the changes, and saves them directly to your files. No copy-pasting code snippets — it edits files in place.

Together, Ollama + Aider let you use AI to help write code — privately, offline, with no API bills. Everything stays on your machine.

## Why Use This?

- **Private:** Your code never leaves your computer
- **Free:** No API keys, no monthly charges
- **Offline:** Works without internet (after initial model download)
- **Fast:** No round-trip to a cloud API
- **Control:** Choose which AI model to use based on your Mac's RAM

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

## How It Works (Detailed)

When you type `aider-local`:

1. **Your terminal** runs the `aider-local` command
2. **Aider activates** by loading the Python virtual environment (this includes the Aider application)
3. **Aider connects to Ollama** at `http://127.0.0.1:11434` — this is Ollama's address on your computer
4. **Your AI model loads** into RAM (e.g., gemma3:27b), which is why RAM matters
5. **Aider loads your instructions** from `~/.aider/AIDER_INSTRUCTIONS.md` — this tells the model it's OK to edit your files
6. **You type a prompt**, e.g., "Create a function that checks if a number is prime"
7. **Aider sends your prompt + your current code to the model** (still on your Mac)
8. **The model thinks through your code** and suggests changes
9. **Aider applies those changes** directly to your files and shows you what changed
10. **You can ask follow-up questions** or type `/exit` to quit

Everything in steps 7–10 stays on your machine. No internet request, no trace.

## Limitations

Local AI models are good at coding, but not as smart as cloud-based models:
- They may miss edge cases you'd catch manually
- They sometimes over-explain simple changes
- Complex refactors might need multiple rounds of conversation

**Use it like:** "Aider, help me write this feature" — not "Aider, write my entire app."

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions to common issues.
