# gog — Go Git 🚀

`gog` is a **fast, mostly silent Git workflow helper**. Normal commits run without prompts; initialization and safety checks may ask for confirmation.

It is designed to remove friction from daily Git usage by doing **the obvious, safe thing** — or stopping early if it cannot do so safely.

> If you need fine-grained control, use Git directly.

---

## ✨ What `gog` Does

When you run `gog`, it performs the following steps:

1.  **Setup**: (Optional) `--start` initializes a repository and creates a new GitHub remote; `--attach` connects to an existing remote repository.
2.  **Environment Check**: Verifies you are inside a Git repository.
3.  **State Check**: Ensures you are on a branch (not detached HEAD).
4.  **Branch Protection**: Blocks direct commits to `main` / `master` unless bypassed. Protection is bypassed automatically only for a run that actually does something new: a `--start` run that creates the local repo and/or the GitHub remote (re-running `--start` against an already-initialized repo does not bypass it), and a `--attach` run that successfully attaches.
5.  **Ignored-File Safety Check**: Detects tracked files that match Git ignore rules. If found, asks whether to stop tracking them while retaining the local copies.
6.  **Remote Check**: (Optional) verifies the remote `origin` is reachable.
7.  **Scaffolding**: (Optional) adds `.gitkeep` to folders that contain no files of their own.
8.  **Staging**: Stages **all changes across the repository** (`git add -A`), including any approved removals from tracking.
9.  **Exclusion**: (Optional) unstages specific files or patterns provided via `-e`.
10. **Committing**: Commits with a provided message, a default "auto update", or "initial commit" if initializing or attaching.
11. **Auto-Sync**: Pulls remote changes via `rebase` (with `--autostash`, so files you left out with `-e` don't block it) to handle edits made directly on GitHub.
12. **Pushing**: Pushes to the current branch and sets upstream if needed.

---

## 🧰 Requirements

- **Git**
- **Bash 4.4 or newer** (the script uses `mapfile -d` and `${var,,}`). macOS ships Bash 3.2 — install a newer one (`brew install bash`). `gog` checks the version at startup and exits with a clear message if it is too old.
- **`timeout`** (GNU coreutils). On macOS: `brew install coreutils` and make sure `timeout` resolves on your `PATH`. Also checked at startup.
- **GitHub CLI (`gh`)**, authenticated with `gh auth login` — only for `--start`.

Developed and tested with Bash 5.2 and Git 2.43.

---

## 📦 Installation

```bash
chmod +x gog
sudo install -m 755 gog /usr/local/bin/gog

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

*Note: `gog` is quiet by default on normal runs. It still displays warnings, errors and confirmation prompts; use `--verbose` for detailed output.*

### Options

| Option | Description |
| --- | --- |
| `--start` | Initialize Git (if needed), optionally create a `.gitignore`, create a GitHub repo, and push. |
| `--org <name>` | With `--start`: create the repo under an organization. |
| `--attach <url>` | Attach the current folder to an existing remote repository. |
| `--branch <name>` | With `--attach`: branch to check out (default: auto-detect `main` / `master`). |
| `--prefer-local` | With `--attach`: keep local files and force-push (see below). |
| `--prefer-remote` | With `--attach`: overwrite conflicting local files with the remote's (see below). |
| `-e`, `--exclude <path>` | Leave a file or pattern out of this commit. Repeatable. |
| `-k`, `--keep` | Add `.gitkeep` to folders that contain no files of their own. |
| `-s`, `--skip-protection`, `--allow-main` | Allow committing directly to `main` / `master`. |
| `-f`, `--force` | Run the sync phase even if there is nothing to commit. |
| `-n`, `--no-remote-check` | Skip the initial remote reachability check. |
| `--remote-timeout <seconds>` | Override the 5-second reachability timeout. |
| `--verbose` | Show detailed output. |
| `--version`, `--help` | Print the version / usage. |
| `--` | End of options. Needed only for a commit message that starts with `-`. |

Anything else that starts with `-` is rejected with an error (exit `1`) rather than being used as a commit message.

### New Project Initialization

To completely set up a brand-new local directory and sync it to GitHub instantly:

```bash
gog --start

```

This command will seamlessly:

1. Refuse to run if the folder is inside another Git repository (move it out, or run `git init` yourself if you really want a nested one).
2. Initialize a local Git repository if one does not already exist.
3. Ask `Create a default .gitignore? (Y/n)` if there is none yet. `n` or `no` (any case) skips it; anything else, including Enter, creates a basic one covering logs, OS files, `node_modules/`, Python virtualenv folders (`.venv/`, `venv/`, `env/`), build outputs, editor folders and local `.env` files. It is deliberately small — add language-specific rules (for example `__pycache__/`) yourself.
4. Ask for a GitHub repository name (default: the current folder name with spaces turned into hyphens) and `Make repository Public? (y/N)`. `y` or `yes` (any case) makes it public; anything else, including Enter, makes it private.
5. Execute `gh repo create` behind the scenes to provision the remote repo, set up `origin`, override temporary initial branch protection, and execute the core staging/sync pipeline.

With no input available (closed stdin), every prompt falls back to its default: create the `.gitignore`, use the folder name, private repository.

To create the new GitHub repository inside a specific organization instead of your personal account:

```bash
gog --start --org my-organization

```

When `--org` is used, enter only the repository name at the prompt. `gog` builds the GitHub target as `my-organization/repository-name`. `--org` without `--start` is an error, and it also exits if `origin` already exists instead of being ignored. The organization name is validated as a proper GitHub org/user name (letters, digits, single hyphens between them; no leading, trailing, or consecutive hyphens, and no spaces or slashes). A `/` in the repository name itself is also rejected at the prompt, whether or not `--org` is used, since it would otherwise silently retarget the repo to a different owner.

### Attach to an existing remote

To link an existing directory to a remote repository:

```bash
gog --attach https://github.com/owner/repo.git
```

By default, `gog` looks for the remote `main` or `master` branch; use `--branch <name>` to specify another branch. Attaching an empty folder simply checks out the remote branch and exits `0` — there is nothing to commit. A successful attach also bypasses branch protection for that run.

The remote's reachability is checked within the `--remote-timeout` limit (default 5 seconds); the fetch that follows is not timed out.

If local files conflict with the remote, the operation stops (exit `1`) and offers these **explicit, potentially destructive** alternatives:

- `--prefer-local`: Keeps local state and may use `git push --force-with-lease` to replace the remote branch history. Review the remote carefully before using it.
- `--prefer-remote`: Uses a forced checkout and `git reset --hard` to the remote branch, discarding conflicting uncommitted local changes. If the local branch has commits that exist only locally, `gog` first saves them on a backup branch named `gog-backup/<branch>-<timestamp>` and tells you its name.

`--attach` cannot be combined with `--start`. Normal commits do not force-push.

### Overriding the remote timeout

Remote reachability checks default to a 5-second timeout. On slow connections this can misreport an unreachable remote — override it with:

```bash
gog --remote-timeout 15

```

### Custom commit message

```bash
gog "Refactor auth logic"

```

For a message that starts with `-`, put `--` before it:

```bash
gog -- "-1 server crash fix"

```

### Excluding files or patterns

To stage everything *except* specific files (e.g., config files or logs), use the `-e` or `--exclude` flag. To exclude multiple items, use the flag for each one:

```bash
gog -e "config.json" -e "*.log" "Update core logic"

```

Excluded files stay exactly as they are in your working directory — a modified file remains modified (and uncommitted) afterwards, and `gog` stashes and restores it around the rebase.

> **Note**: Always place flags *before* the commit message to ensure correct processing. `-e`/`--exclude` requires a value — omitting it (e.g. `gog -e "commit message"`) is treated as a missing argument and errors out rather than silently consuming your commit message.

### Already-tracked files matching `.gitignore`

Adding a file to `.gitignore` does **not** stop Git from tracking it if it was already committed. Before a normal commit, `gog` checks tracked files against Git's standard ignore rules (including `.gitignore`, `.git/info/exclude`, and global excludes). It asks only if it finds a match:

```text
WARNING: 2 tracked file(s) match Git ignore rules:
  .env
  config.local.php

Stop tracking these files? [y/N]:
```

Names are printed shell-quoted, so unusual characters in a file name are visible.

- **`y` or `yes`** (case-insensitive): `gog` runs `git rm --cached -- <files>` for the detected paths, leaving the local files in place. It then stages the index removals and continues the normal commit and sync.
- **`n`, Enter, or any other answer**: Cancels the commit without changing which files are tracked (exit code `16`).
- **No input / closed stdin**: Also cancels safely (exit code `16`); it does not silently approve the removal. This means an unattended run (cron, CI) stops with exit `16` in any repository that has such a file.
- **Git refuses the index removal**: Cancels with exit code `15`; it does not force the operation.

There is no option to skip this check, and `-n` / `-e` do not affect it. This confirmation is separate from `-e`/`--exclude`, which excludes paths from the **current commit** rather than permanently untracking them. If you intentionally track a file that an ignore rule matches, add a negation rule for it (for example `!config.local.php`) or use Git directly.

**Important:** Removing a file from the index removes it from future commits, not past Git history. If a previously published file contained secrets, revoke or rotate the credentials and address any historical exposure separately. The normal safety check does not run on the early force-push path of `--attach --prefer-local`.

### Directory Scaffolding

To make sure folders with no files of their own (empty folders, or folders holding only subfolders) are kept and shown as separate rows on GitHub rather than "compacted" into `a/b/c`:

```bash
gog --keep "Initial structure"

```

`gog` adds a `.gitkeep` to every such folder. Folders that already contain files, hidden folders, and folders matched by your ignore rules (for example `node_modules/`) are left alone.

### Bypass branch protection

To allow committing directly to `main` or `master`:

```bash
gog -s
# OR
gog --skip-protection
# OR
gog --allow-main

```

### Verbose mode

To see detailed output (staging, rebase status, push confirmation):

```bash
gog --verbose

```

---

## 🧠 Mental Model

`gog` operates in **momentum mode**, not precision mode.

* **Whole-Repo Staging**: Everything changed is staged; specific file paths don't matter, though you can exclude outliers with `-e`.
* **Linear History**: Uses `rebase` during sync to keep your commit history clean and straight.
* **Safety First**: Stops on rebase conflicts and requires explicit approval before untracking ignored files in the normal commit workflow.

---

## 🔐 Safety Guarantees

* **Protected Branches**: Blocks `main/master` by default to prevent accidents. This protection is only bypassed for a `--start` run that actually initializes the local repo or creates the GitHub remote, or a `--attach` run that attaches successfully — running `--start` again afterward behaves like a normal `gog` invocation and respects branch protection as usual.
* **Safe Rebase**: Will not overwrite local work; if GitHub and local changes conflict, it exits for safety.
* **Network Aware**: Fails fast (configurable via `--remote-timeout`, default 5s) on every remote *reachability check* — the initial check, the pre-sync branch check, and the reachability check at the start of `--attach`. The actual `git fetch` / `git pull --rebase` / `git push` transfers are not artificially timed out, so a slow-but-working transfer on a large repo won't be killed early.
* **Preserves Ignored Local Files**: With confirmation, removes ignored files only from the Git index (`--cached`), not the working directory.
* **Normal Pushes Are Not Forced**: Standard commits do not force-push. The explicitly requested `--attach --prefer-local` recovery path can use `--force-with-lease` and change remote history.
* **No Silent Loss of Local Commits**: `--attach --prefer-remote` saves local-only commits on a `gog-backup/...` branch before resetting.

---

## 📟 Exit Codes

| Code | Meaning |
| --- | --- |
| `0` | Success (commit and/or sync completed, a successful `--attach` with nothing to commit, or `--help`/`--version`) |
| `1` | Usage or environment error: unknown or invalid option, option combination not allowed, not a Git repository, `--attach` validation or branch-detection failure or file conflict, nested repository for `--start`, missing `gh`, Bash older than 4.4, missing `timeout` |
| `10` | Nothing to commit locally (use `-f` to force sync anyway) |
| `11` | Detached HEAD |
| `12` | Blocked branch (use `-s` to bypass) |
| `13` | Remote/network error (unreachable origin, failed `gh repo create`, failed push, or a `pull --rebase` failure that isn't an actual conflict) |
| `14` | Rebase conflict — a rebase is actually in progress; resolve and run `git rebase --continue` |
| `15` | Local Git operation failed (`git add -A`, `git commit`, or untracking an ignored file) |
| `16` | Ignored tracked-file cleanup declined or not confirmed (including EOF/non-interactive input) |

A few Git commands in `--start` and `--attach` (`git init`, and the checkout/reset used by `--prefer-remote`) are not individually guarded; if one of them fails, `gog` exits with Git's own exit status.

**Output streams:** errors, warnings and the ignored-file prompt go to stderr. Progress messages (shown with `--verbose`, `--start` or `--attach`), `--version` and `--help` go to stdout.

---

## 📜 License

MIT
