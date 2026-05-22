# Changelog

All notable changes to this project will be documented in this file.

This project follows **semantic versioning** and favors stability over feature growth.

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