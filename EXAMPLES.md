# Optional Verification Examples

These are optional prompts you can run inside Aider after setup to confirm everything is working. They are not required.

## How to Run

1. Launch Aider from a temporary test directory:
   ```bash
   mkdir ~/tmp-aider-test
   cd ~/tmp-aider-test
   aider-local
   ```

2. Copy one of the example prompts below and paste it into the Aider chat.

3. Observe the result and compare to the expected output.

4. Type `/exit` to leave Aider and clean up:
   ```bash
   cd ~
   rm -rf ~/tmp-aider-test
   ```

---

## Example 1: File Creation

**Prompt:**
```
Create a file named hello.txt containing the text: Hello World.
```

**Expected Result:**
- Aider creates `hello.txt` in the current directory.
- File contains exactly: `Hello World.`
- You can verify:
  ```bash
  cat hello.txt
  ```

---

## Example 2: Repository Awareness

**Prompt:**
```
What files exist in this project?
```

**Expected Result:**
- Aider lists all files in the current directory.
- Since you are in a fresh test directory, it should show `hello.txt` (from Example 1) and any other files you created.
- Response demonstrates Aider can scan the current project.

---

## Example 3: Multi-File Project

**Prompt:**
```
Create a Python project with main.py and a README.md. main.py should print Hello from main.
```

**Expected Result:**
- Two files are created: `main.py` and `README.md`.
- `main.py` contains code that prints "Hello from main" when executed.
- `README.md` contains project documentation.
- You can verify:
  ```bash
  python main.py
  ```
  Output should be: `Hello from main`

---

## Example 4: Script Generation

**Prompt:**
```
Create a shell script named check_disk.sh that prints available disk space.
```

**Expected Result:**
- Aider creates `check_disk.sh` (a shell script).
- Script contains code to display disk space (e.g., using `df` command).
- Script is executable.
- You can verify:
  ```bash
  bash check_disk.sh
  ```
  Output should show your machine's disk space.

---

## Validation

If Aider successfully completes all four examples:
- **File creation works** — Aider can write files to disk.
- **Project awareness works** — Aider reads and understands the current directory.
- **Multi-file workflows work** — Aider can create multiple files in coordination.
- **Scripts work** — Aider generates executable code.

## If Aider Refuses

If Aider refuses to create files or claims it cannot write code, check [TROUBLESHOOTING.md](TROUBLESHOOTING.md). The most common cause is that `AIDER_INSTRUCTIONS.md` is not being loaded correctly by the launcher.
