# Changelog

All notable changes to this project will be documented in this file.

This project follows **semantic versioning** and favors stability over feature growth.

---

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
- **Aggressive Scaffolding:** Updated the `--keep` or `-k` logic to ensure `.gitkeep` files are placed in every subdirectory, forcing GitHub to expand "compacted" directory views.

---

## [1.3.0] — 2026-01-29

### Added
- **Directory Scaffolding:** Introduced the `--keep` or `-k` flag to automatically create `.gitkeep` files in empty directories, ensuring complex folder structures are preserved on GitHub.
- **Alias:** Added `--allow-main` as a descriptive alias for the `-s` flag.

---

## [1.2.0] — 2026-01-29

### Added
- **Auto-Sync (Rebase):** The script now automatically pulls and rebases remote changes before pushing. This allows seamless transitions when files are edited directly on GitHub.
- New exit code `14` for rebase conflicts.

### Changed
- **Mental Model Update:** Shifted from "No rebases" to a "Sync-first" workflow to support single developers working across multiple environments.
- Improved commit message logic: Messages now default to "🚀 auto update" if no argument is provided, using a more streamlined bash implementation.

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
- `--strict` mode for scriptable exit codes
- Clear, documented exit codes
- UTF-8 safe commit message handling

### Changed
- Default behavior exits successfully when there is nothing to commit
- Remote checks are timed to avoid blocking on poor connections

### Removed
- Interactive staging (`--patch`)
- Ambiguous flags (`--yes`, `-y`)
- Any implicit force-push behavior

---

## [Unreleased]

### Ideas (Explicitly Non-Goals)
- Amend commits
- Force push support
- Interactive workflows