# gog — Go Git 🚀

`gog` is a **fast, silent, non-interactive Git workflow helper**. 

It is designed to remove friction from daily Git usage by doing **the obvious, safe thing** — or stopping early if it cannot do so safely.

> If you need fine-grained control, use Git directly.

---

## ✨ What `gog` Does

When you run `gog`, it performs the following steps:

1.  **Initialization**: (Optional) If run with `--start`, it initializes a local Git repo, creates a standard `.gitignore`, prompts to create a public/private GitHub repository via the `gh` CLI, and configures the remote origin automatically.
2.  **Environment Check**: Verifies you are inside a Git repository.
3.  **State Check**: Ensures you are on a branch (not detached HEAD).
4.  **Branch Protection**: Blocks direct commits to `main` / `master` unless bypassed (automatically bypassed during `--start`).
5.  **Remote Check**: (Optional) verifies the remote `origin` is reachable.
6.  **Scaffolding**: (Optional) adds `.gitkeep` to all subdirectories to preserve folder structure on GitHub.
7.  **Staging**: Stages **all changes across the entire repository** (`git add -A`).
8.  **Exclusion**: (Optional) unstages specific files or patterns provided via the `-e` flag.
9.  **Committing**: Commits with a provided message, a default "auto update", or "initial commit" if initializing.
10. **Auto-Sync**: Pulls remote changes via `rebase` to handle edits made directly on GitHub.
11. **Pushing**: Pushes to the current branch and sets upstream if needed.

---

## 📦 Installation

```bash
chmod +x gog.sh
sudo mv gog.sh /usr/local/bin/gog

```

Verify:

```bash
gog --help

```

---

## 🚀 Usage

### Basic usage

```bash
gog

```

*Note: `gog` is silent by default. It will only output text if an error occurs.*

### New Project Initialization

To completely set up a brand-new local directory and sync it to GitHub instantly:

```bash
gog --start

```

This command will seamlessly:

1. Initialize a local Git repository if one does not already exist.
2. Generate a robust, production-ready `.gitignore` covering common development environments (Node, Python, IDEs, logs, and local `.env` files).
3. Interactively prompt you for a GitHub repository name (auto-suggesting your current folder name with sanitized hyphens) and visibility (`Public` vs `Private`).
4. Execute `gh repo create` behind the scenes to provision the remote repo, set up `origin`, override temporary initial branch protection, and execute the core staging/sync pipeline.

### Custom commit message

```bash
gog "Refactor auth logic"

```

### Excluding files or patterns

To stage everything *except* specific files (e.g., config files or logs), use the `-e` or `--exclude` flag. To exclude multiple items, use the flag for each one:

```bash
gog -e "config.json" -e "*.log" "Update core logic"

```

> **Note**: Always place flags *before* the commit message to ensure correct processing.

### Directory Scaffolding

To ensure your full folder structure (including empty or intermediate folders) is visible on GitHub and not "compacted":

```bash
gog --keep "Initial structure"

```

### Bypass branch protection

To allow committing directly to `main` or `master`:

```bash
gog -s
# OR
gog --skip-protection

```

### Verbose mode

To see detailed output (staging, rebase status, push confirmation):

```bash
gog --verbose

```

---

## 🧠 Mental Model

`gog` operates in **momentum mode**, not precision mode.

* **Whole-Repo Staging**: Everything changed is staged; specific file paths don't matter, though you can now exclude outliers.
* **Linear History**: Uses `rebase` during sync to keep your commit history clean and straight.
* **Safety First**: Stops immediately if a merge conflict occurs, requiring manual resolution.

---

## 🔐 Safety Guarantees

* **Protected Branches**: Blocks `main/master` by default to prevent accidents.
* **Safe Rebase**: Will not overwrite local work; if GitHub and local changes conflict, it exits for safety.
* **Network Aware**: Fails fast if the remote is unreachable.
* **No Force Pushes**: Never uses `--force`, ensuring you don't delete remote history.

---

## 📟 Exit Codes

| Code | Meaning |
| --- | --- |
| `0` | Success / Nothing to commit |
| `10` | Nothing to commit |
| `11` | Detached HEAD |
| `12` | Blocked branch (use `-s` to bypass) |
| `13` | Remote/network error |
| `14` | Rebase conflict (Manual intervention required) |

---

## 📜 License

MIT