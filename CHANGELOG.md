# Changelog

All notable changes to this project will be documented in this file.

This project follows **semantic versioning** and favors stability over feature growth.

---

## [2.0.0] — Unreleased

### Fixed
- `--attach` refuses to run from a child folder of another Git repository, uses the remote's advertised default branch when available, and does not echo the remote URL in progress messages.
- Staged file-type changes are now committed, including regular files changed to symlinks.
- Remote branch checks run before ignored-file cleanup, so a failed reachability check cannot leave that cleanup staged.
- Normal commits, pulls, and pushes use Git's quiet mode while preserving failure output.
- A rebase conflict now lists the affected files and offers Manual (default), Prefer local, or Prefer remote. A preference retries the rebase and stops before pushing for review (exit `17`); unresolved retries and autostash conflicts still stop for manual resolution.

### Breaking Changes
- **Attach checkout failures:** `--attach` now stops when Git cannot check out the remote branch, shows Git's error, and removes the `origin` remote it added for that attempt. If remote cleanup fails, it tells the user to remove `origin` manually. Removed `--prefer-local` and `--prefer-remote`; `gog` no longer force-pushes or resets local state during attach.
- **Directory scaffolding:** Removed `-k` / `--keep`, which added `.gitkeep` files automatically.
- **Sync option:** Replaced `-f` / `--force` with `--sync`. It still runs the normal pull/push phase when there is nothing new to commit; it does not force-push.
- **Branch-protection alias:** Removed `--allow-main`; use `-s` or `--skip-protection`.

### Ideas (Explicitly Non-Goals)
- Amend commits
- Force-push recovery workflows
- General-purpose interactive staging or per-file conflict-resolution workflows

---

## [1.8.0] — 2026-11-03

### Added
- **`-p` / `--pull`:** Pull the current branch from `origin` with rebase and autostash, without staging, committing, or pushing. Works on protected branches and rejects unrelated workflow options.

### Fixed
- Detect conflicts left by Git while reapplying an autostash, even when `git pull` exits successfully. Stop with exit `14` instead of reporting success or continuing to push.

---

## [1.7.0] — 2026-10-31

A bug-fix and documentation-accuracy release. One behavior change is noted under **Changed**.

### Fixed
- **`-e`/`--exclude` on a modified tracked file:** The excluded file was left with uncommitted changes, so `git pull --rebase` refused to run and `gog` reported a misleading "network, auth, or diverged history" failure (exit `13`) after already creating the commit. The sync now uses `git pull --rebase --autostash`; excluded files stay modified in the working directory.
- **Branch-exists check matched by suffix:** `git ls-remote --heads origin dev` also matched `feature/dev`, so a new local branch `dev` tried to `pull --rebase` a remote branch that doesn't exist (exit `13`). The check now uses the exact ref `refs/heads/<branch>`.
- **False "nothing to commit" (exit `10`) on large change sets:** `git status --porcelain | grep -q …` under `pipefail` could be killed by SIGPIPE once the status output exceeded the pipe buffer (several thousand files). `grep` now reads all of its input. The same pattern was removed from the `--attach --prefer-local` path.
- **`--start` prompts:** The `.gitignore` prompt only treated `n` as "no" (so `no` still created the file) and the visibility prompt only treated `y` as "yes" (so `yes` created a private repo). Both now accept `n`/`no` and `y`/`yes`, case-insensitive.
- **`--attach` on an empty folder exited `10`:** A successful attach with nothing to commit is no longer reported as "nothing to commit"; it syncs and exits `0`.
- **`--attach` fetch timeout:** The whole `git fetch` was bounded by the 5-second reachability timeout, so a large repository failed with a misleading "check the URL" error. Only the reachability check is timed now; the fetch is not.
- **`--attach --prefer-remote` could silently discard commits:** Commits that existed only on the local branch were orphaned by `git reset --hard`. They are now saved on a `gog-backup/<branch>-<timestamp>` branch first (and the run stops if that backup can't be created).
- **`--keep` did not cover folders that hold only subfolders**, so chains like `a/b/c` could still be collapsed on GitHub. Every folder without files of its own now gets a `.gitkeep`. Folders matched by Git ignore rules (for example `node_modules/`) are skipped.
- **`--allow-main` alias:** Documented since 1.3.0 but missing from the script; restored.

### Changed
- **Unknown options are rejected.** Previously an unrecognized flag such as `--verbos` or `-sk` ended option parsing and was committed and pushed as the commit message. It now fails with exit `1`. **Behavior change:** a commit message that starts with `-` must now be preceded by `--` (`gog -- "-1 crash fix"`).
- **Errors and warnings go to stderr.** Previously older messages went to stdout and newer ones to stderr. Progress output, `--version` and `--help` stay on stdout.
- **Startup requirement check:** `gog` now exits with a clear message if Bash is older than 4.4 or `timeout` is missing, instead of failing partway through.
- **Help text:** `--start` no longer claims to always create a `.gitignore`; `--org` says it needs `--start`; `-k` describes the real behavior; `--allow-main` and `--` are listed.

### Documentation
- README: added a Requirements section and a full option table; documented `-n`, `-f`, `--version`, `--allow-main`, `--`, exit code `1`, stderr/stdout behavior, the nested-repository guard, non-interactive `--start` defaults, and that a successful `--attach` bypasses branch protection.
- README: corrected the ignored-file prompt text, the description of the generated `.gitignore` (it is small and covers Python virtualenv folders but not `__pycache__`/`*.pyc`), the `--keep` description, the "network aware" statement (it now matches the `--attach` behavior), and the `--prefer-remote` description. Removed stale "now" wording.
- README: stated plainly that the tracked-ignored-file prompt has no bypass option and stops unattended runs with exit `16`. This is unchanged by design.

### Notes
- **Previously unrecorded features.** These exist in the script but were never listed in this changelog; the release that introduced each is not known: `--attach`, `--branch`, `--prefer-local`, `--prefer-remote`; `-e`/`--exclude`; `-f`/`--force`; `-n`/`--no-remote-check`; `--version`; the guard that refuses `--start` inside another Git repository; the "initial commit" default message for `--start`/`--attach`.
- **Version gaps.** This changelog has no entries for 1.4.0, 1.6.0 or 1.6.1. If those versions were released, their changes are not recorded here.

---

## [1.6.3] — 2026-10-08

### Changed
- **Interactive ignored-file cleanup:** When tracked files match Git ignore rules, `gog` lists them and asks for approval (`[y/N]`) rather than requiring manual cleanup. On `y`/`yes`, it runs `git rm --cached` for the affected files, preserving local copies, and continues the normal commit and push.
- **Safe decline and non-interactive behavior:** `n`, Enter, any other response, or missing stdin cancels without changing tracking (exit `16`). A failed `git rm --cached` stops with exit `15`.

### Notes
- This removes files only from future tracking; existing commits and published history are not rewritten.
- The check runs in the normal commit path. `--attach --prefer-local` has a separate early force-push path.

---

## [1.6.2] — 2026-10-08

### Added
- **Tracked-ignored-file detection:** Warned when already-tracked files matched standard Git ignore rules and blocked commits until they were manually untracked (exit `16`). Superseded by v1.6.3's confirmation-based cleanup.

---

## [1.5.0] — 2026-09-19

### Added
- **`--remote-timeout <seconds>`:** New flag to override the default 5-second remote reachability timeout, so slow connections no longer misreport an unreachable remote. Applies to both the initial reachability check and the pre-sync branch-existence check.
- New exit code `15` for local Git operation failures (`git add -A` or `git commit`).

### Fixed
- **Rebase failure diagnosis:** A failed `git pull --rebase` is no longer always reported as a conflict. `gog` now checks whether a rebase is actually in progress: genuine conflicts still exit `14` with the "resolve manually" message, while other failures (network, auth, diverged history) exit `13` with an accurate message instead.
- **`--org` validation:** Broadened beyond a bare slash/whitespace check to a proper GitHub org/user name format — rejects leading, trailing, or consecutive hyphens, spaces, and slashes.
- **Repository name slash check:** Now applied at the `--start` prompt regardless of whether `--org` is used, closing a gap where a `/` in the repository name could silently retarget the new repo to a different GitHub owner.
- **Non-interactive `--start`:** The `.gitignore`, repository name, and visibility prompts no longer crash the script on EOF/non-interactive stdin; they now fall back to their existing interactive defaults (create `.gitignore`, use the folder name, private repo).
- **`git add -A` / `git commit` failures:** Both are now caught with a clear error message and exit code `15` instead of letting the script terminate on raw Git output.
- **Branch-existence check timeout:** The pre-sync `git ls-remote --heads` call is now bounded by `--remote-timeout` like the initial reachability check, instead of being able to hang indefinitely.

---

## [1.4.3] — 2026-06-06

### Added
- **Organization repository creation (`--org`):** Added `--org <name>` and `--org=<name>` for `gog --start`, allowing new GitHub repositories to be created under a specific organization via GitHub CLI `OWNER/REPO` targeting.

### Changed
- `--org` now fails fast when used without `--start`, when given an invalid organization path, or when `origin` is already configured, preventing silent no-op behavior.

---

## [1.4.2] — 2026-05-22

### Changed
- **Optional `.gitignore` generation:** During `--start`, the script now prompts the user before creating a default `.gitignore`. Previously it was created automatically if absent. Defaults to yes if the prompt is skipped.

---

## [1.4.1] — 2026-05-22

### Added
- **Repository Initialization Workflow (`--start`):** A flag to automate the absolute baseline workspace configuration for new directories. It sets up local git systems, injects a standard default `.gitignore`, matches folder names to create an upstream repository using the GitHub CLI (`gh`), and securely hands off the initial workspace commit directly into the native synchronization loop.
- Introduced a porcelain-based plumbing verification status pipeline (`git status --porcelain`) to guarantee a smooth exit trajectory for empty states when no commit history (`HEAD`) is structurally present yet.
- Patched standard loop mechanics within the directory scaffolding tracker logic (`-k`) to process subdirectories as null-terminated strings (`-print0`), ensuring complete isolation for file structures containing unexpected spaces or line breaks.


---

## [1.3.1] — 2026-01-29

### Fixed
- **Flag Parsing Logic:** Improved flag handling to be more robust.
- **Aggressive Scaffolding:** Updated the `--keep` or `-k` logic to ensure `.gitkeep` files are placed in every subdirectory, forcing GitHub to expand "compacted" directory views. *(As of 1.6.3 only empty folders actually received one; corrected in 1.7.0.)*

---

## [1.3.0] — 2026-01-29

### Added
- **Directory Scaffolding:** Introduced the `--keep` or `-k` flag to automatically create `.gitkeep` files in empty directories, ensuring complex folder structures are preserved on GitHub.
- **Alias:** Added `--allow-main` as a descriptive alias for the `-s` flag. *(Missing from the script as of 1.6.3; restored in 1.7.0.)*

---

## [1.2.0] — 2026-01-29

### Added
- **Auto-Sync (Rebase):** The script now automatically pulls and rebases remote changes before pushing. This allows seamless transitions when files are edited directly on GitHub.
- New exit code `14` for rebase conflicts.

### Changed
- **Mental Model Update:** Shifted from "No rebases" to a "Sync-first" workflow to support single developers working across multiple environments.
- Improved commit message logic: Messages now default to "🚀 auto update" if no argument is provided, using a more streamlined bash implementation. *(The emoji prefix was later dropped; the default is now plain "auto update". That change was not recorded.)*

---

## [1.1.0] — 2026-01-17

### Added
- `-s` / `--skip-protection` flag to allow committing directly to `main` and `master`.

### Changed
- **Default behavior is now silent.** Output is now suppressed by default and only appears on errors or if `--verbose` is used.

### Removed
- `--silent` flag (redundant as silence is now the default).

---

## [1.0.0] — 2026-01-02

### Added
- One-command Git workflow (`add → commit → push`)
- Automatic upstream setup for new branches
- Safe branch protection (`main`, `master`)
- Detached HEAD detection
- Optional remote availability check with timeout
- `--silent` mode for CI and automation
- `--verbose` mode for explicit output
- `--strict` mode for scriptable exit codes *(Not present in current releases; its removal was never recorded.)*
- Clear, documented exit codes
- UTF-8 safe commit message handling

### Changed
- Default behavior exits successfully when there is nothing to commit *(As of 1.6.3 this exits `10` unless `-f` is used; the change was not recorded.)*
- Remote checks are timed to avoid blocking on poor connections

### Removed
- Interactive staging (`--patch`)
- Ambiguous flags (`--yes`, `-y`)
- Any implicit force-push behavior

---
