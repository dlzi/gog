#!/usr/bin/env bash
# NOTE: File must be UTF-8 encoded

set -e
export LC_ALL=C.UTF-8

# =======================
# CONFIG
# =======================
BLOCKED_BRANCHES=("main" "master")
REMOTE_TIMEOUT=5
VERSION="1.4.3"

# Exit codes
EXIT_NO_COMMIT=10
EXIT_DETACHED_HEAD=11
EXIT_BLOCKED_BRANCH=12
EXIT_REMOTE_ERROR=13
EXIT_REBASE_CONFIRM=14

# =======================
# FLAGS
# =======================
SILENT=true
VERBOSE=false
REMOTE_CHECK=true
SKIP_PROTECTION=false
SCAFFOLD=false
FORCE=false
START=false
ORG=""
EXCLUDE_FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start) START=true ;;
    --org)
      if [[ -z "${2:-}" || "$2" == -* ]]; then
        echo "ERROR: --org requires an organization name"
        exit 1
      fi
      ORG="$2"
      shift
      ;;
    --org=*)
      ORG="${1#--org=}"
      if [[ -z "$ORG" ]]; then
        echo "ERROR: --org requires an organization name"
        exit 1
      fi
      ;;
    --verbose) VERBOSE=true ;;
    -n|--no-remote-check) REMOTE_CHECK=false ;;
    -s|--skip-protection) SKIP_PROTECTION=true ;;
    -k|--keep) SCAFFOLD=true ;;
    -f|--force) FORCE=true ;;
    -e|--exclude)
      EXCLUDE_FILES+=("$2")
      shift 
      ;;
    --version) echo "gog v$VERSION"; exit 0 ;;
    --help)
      cat <<EOF
Usage: gog [options] [commit message]
Options:
  --start               Initialize Git, create .gitignore, and setup GitHub repo
  --org <name>          Create new GitHub repo under a specific organization
  --verbose             Force verbose output
  -n,--no-remote-check  Skip remote availability check
  -s,--skip-protection  Allow committing directly to main/master
  -k,--keep             Auto-add .gitkeep to empty folders
  -f,--force            Force sync/push even if no files are staged
  -e,--exclude <file>   Exclude a file/pattern from the commit
  --version             Show the current gog version
  --help                Show this help
EOF
      exit 0 ;;
    *) break ;;
  esac
  shift
done

if [[ -n "$ORG" ]]; then
  if [[ "$START" == false ]]; then
    echo "ERROR: --org only works with --start"
    exit 1
  fi
  if [[ "$ORG" == */* || "$ORG" =~ [[:space:]] ]]; then
    echo "ERROR: --org must be a single GitHub organization name, not a path"
    exit 1
  fi
fi

# Force interactive output visibility during startup workflows
if [[ "$VERBOSE" == true || "$START" == true ]]; then
  SILENT=false
fi

log() {
  if [[ "$SILENT" == false ]]; then
    echo "$1"
  fi
}

# =======================
# INITIALIZATION FEATURE (--start)
# =======================
if [[ "$START" == true ]]; then
  log "Initializing new project workflow..."
  
  # 1. Ensure GitHub CLI is installed
  if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI ('gh') is required to create a remote repository automatically."
    echo "Please install it (https://cli.github.com/) and authenticate using 'gh auth login'."
    exit 1
  fi

  # 2. Initialize local Git repo if it doesn't exist
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Initializing local Git repository..."
    git init
  fi

  # 3. Optionally create a smart default .gitignore if missing
  if [[ ! -f .gitignore ]]; then
    printf "Create a default .gitignore? (Y/n): "
    read -r CREATE_GITIGNORE
    if [[ ! "$CREATE_GITIGNORE" =~ ^[Nn]$ ]]; then
    log "Creating default .gitignore..."
    cat <<EOF > .gitignore
# Logs
logs
*.log
npm-debug.log*

# OS files
.DS_Store
Thumbs.db

# Common Dependency directories
node_modules/
jspm_packages/
.venv/
venv/
env/

# Build outputs
dist/
build/
.next/
out/

# IDEs and editors
.idea/
.vscode/
*.swp
*.swo

# Local environment variables
.env
.env.local
.env.*.local
EOF
    fi  # end CREATE_GITIGNORE check
  fi

  # 4. Handle GitHub Remote creation
  if git remote get-url origin >/dev/null 2>&1; then
    if [[ -n "$ORG" ]]; then
      echo "ERROR: --org was provided, but remote 'origin' is already configured."
      echo "Remove or change origin before creating a new organization repository."
      exit $EXIT_REMOTE_ERROR
    fi
    log "Remote 'origin' already configured. Skipping GitHub repository creation."
  else
    # Sanitize directory name to be GitHub friendly (replace spaces with hyphens)
    SUGGESTED_NAME=$(basename "$PWD" | tr ' ' '-')
    
    printf "Enter GitHub repository name [default: %s]: " "$SUGGESTED_NAME"
    read -r REPO_NAME
    REPO_NAME=${REPO_NAME:-$SUGGESTED_NAME}

    printf "Make repository Public? (y/N): "
    read -r IS_PUBLIC
    VISIBILITY="--private"
    if [[ "$IS_PUBLIC" =~ ^[Yy]$ ]]; then
      VISIBILITY="--public"
    fi

    REPO_TARGET="$REPO_NAME"

    if [[ -n "$ORG" ]]; then
      if [[ "$REPO_NAME" == */* ]]; then
        echo "ERROR: Do not include OWNER/ in the repository name when using --org."
        echo "Use: gog --start --org $ORG"
        exit 1
      fi

      REPO_TARGET="$ORG/$REPO_NAME"
    fi

    log "Creating GitHub repository '$REPO_TARGET' ($VISIBILITY)..."
    if ! gh repo create "$REPO_TARGET" "$VISIBILITY" --source=. --remote=origin; then
      echo "ERROR: Failed to create GitHub repository via 'gh' CLI."
      exit $EXIT_REMOTE_ERROR
    fi
  fi

  # Bypass branch protection safely for the initial creation push
  SKIP_PROTECTION=true
fi

# =======================
# PRE-CHECKS
# =======================
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: Not a Git repository"; exit 1; }

if ! CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null); then
  echo "Detached HEAD state detected"; exit $EXIT_DETACHED_HEAD
fi

if [[ "$SKIP_PROTECTION" == false ]]; then
  for b in "${BLOCKED_BRANCHES[@]}"; do
    if [[ "$CURRENT_BRANCH" == "$b" ]]; then
      echo "Direct commits to '$b' blocked. Use -s to bypass."; exit $EXIT_BLOCKED_BRANCH
    fi
  done
fi

if [[ "$REMOTE_CHECK" == true ]]; then
  git remote get-url origin >/dev/null 2>&1 || { echo "ERROR: Remote 'origin' not configured"; exit $EXIT_REMOTE_ERROR; }
  timeout "$REMOTE_TIMEOUT" git ls-remote origin >/dev/null 2>&1 || { echo "ERROR: Remote 'origin' unreachable"; exit $EXIT_REMOTE_ERROR; }
fi

# =======================
# WORKFLOW
# =======================

if [[ "$SCAFFOLD" == true ]]; then
  log "Scaffolding directory structure..."
  # Null-terminated handling to protect spaces/newlines in filenames
  find . -type d -not -path '*/.*' -print0 | while IFS= read -r -d '' dir; do
    if [ -z "$(ls -A "$dir")" ] || [ "$(ls -A "$dir")" = ".gitkeep" ]; then
       touch "$dir/.gitkeep"
    fi
  done
fi

log "Staging all changes..."
git add -A

if [ ${#EXCLUDE_FILES[@]} -gt 0 ]; then
  log "Excluding specified files..."
  for file in "${EXCLUDE_FILES[@]}"; do
    if git rev-parse HEAD >/dev/null 2>&1; then
      git reset HEAD -- "$file" >/dev/null 2>&1 || true
    else
      git rm --cached -r "$file" >/dev/null 2>&1 || true
    fi
  done
fi

# COMMIT LOGIC
# Production Fix: Use plumbing status check. 'git diff --cached' crashes if HEAD doesn't exist yet.
if ! git status --porcelain | grep -q '^[AMDRC]'; then
  if [[ "$FORCE" == true ]]; then
    log "Nothing to commit, but forcing sync phase..."
  else
    echo "WARNING: Nothing to commit locally. Use -f to force sync anyway."
    exit 0 
  fi
else
  # Polish: set specific default text if it's a fresh repository initialization
  if [[ "$START" == true ]]; then
    COMMIT_MSG="${*:-initial commit}"
  else
    COMMIT_MSG="${*:-auto update}"
  fi
  log "Commit: $COMMIT_MSG"
  git commit -m "$COMMIT_MSG"
fi

# SYNC LOGIC
# Check if the branch exists on the remote (origin)
REMOTE_EXISTS=$(git ls-remote --heads origin "$CURRENT_BRANCH" 2>/dev/null)

if [[ -n "$REMOTE_EXISTS" ]]; then
  log "Syncing with GitHub (rebase)..."
  if ! git pull --rebase origin "$CURRENT_BRANCH"; then
    echo "ERROR: Conflict detected! Resolve manually then run: git rebase --continue"
    exit $EXIT_REBASE_CONFIRM
  fi
  
  log "Pushing to '$CURRENT_BRANCH'..."
  git push origin "$CURRENT_BRANCH"
else
  log "Setting upstream and pushing..."
  git push -u origin "$CURRENT_BRANCH"
fi

log "SUCCESS: gog complete"