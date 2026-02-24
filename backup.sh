#!/bin/sh

# Configuration
workspace_folder="$HOME/workspace"
log_file="push_errors.log"
info_file="config/git/workspace"
six_months_ago=$(date -v-6m +"%Y-%m-%d")

# Parse command line arguments
DRY_RUN=false
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run]"
            exit 1
            ;;
    esac
done

# ----------------------------
# DO NOT EDIT BELOW THIS LINE
# ----------------------------

# Check if mackup is installed
if ! command -v mackup &> /dev/null; then
    echo "mackup is not installed. Please install it before proceeding."
    exit 1
fi

echo "Running mackup backup..."
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would run: mackup backup"
else
    mackup backup
fi

# Backup VSCode/Positron settings
if command -v positron >/dev/null 2>&1; then
    echo "Backing up Positron extensions..."
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would save extensions to vscode/extensions.txt"
    else
        positron --list-extensions > config/vscode/extensions.txt
    fi
fi

# Create or overwrite the logs
script_dir=$(dirname "$(realpath "$0")")
log_file="$script_dir/$log_file"
info_file="$script_dir/$info_file"

echo "path\tremote" > "$info_file"
echo "repo\tbranch" > "$log_file"

# Get the current date (for branch naming)
current_date=$(date +"backup-%Y-%m-%d")

# Find all Git repositories within the workspace folder that were modified in the last 6 months
repos=$(find "$workspace_folder" -type d -name ".git" 2>/dev/null | while read -r repo; do
    repo_folder=$(dirname "$repo")
    last_commit_date=$(git -C "$repo_folder" log -1 --format="%ci" 2>/dev/null | awk '{print $1}')

    if [ -n "$last_commit_date" ] && [ "$last_commit_date" \> "$six_months_ago" ]; then
        echo "$repo"
    fi
done)

if [ -z "$repos" ]; then
    echo "No repositories found with commits in the last 6 months"
    exit 0
fi

# Loop through each repository found
for repo in $repos; do
    # Extract the parent directory (repository folder) from the .git path
    repo_folder=$(dirname "$repo")
    repo_base=$(basename "$repo_folder")
    repo_rel=$(echo "$repo_folder" | sed "s|$workspace_folder/||")

    # Navigate to the repository folder
    cd "$repo_folder" || continue
    
    # Get the remote URL of the repository
    if remote_url=$(git remote get-url origin 2>/dev/null); then
        echo "${repo_rel}\t${remote_url}" >> "$info_file"
    else
        echo "No remote found for repository: $repo_base. Skipping."
        continue
    fi

    # Fetch remote changes and prune deleted branches
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would fetch and prune: $repo_base"
    else
        git fetch --prune 2>/dev/null
    fi

    echo "Processing repository: $repo_base..."

    # Commit any uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would commit changes in: $repo_base"
            git status --short
        else
            git add -A
            git commit -m "Auto-backup on $current_date"
        fi
    fi

    # Create (or update) a branch with the current date
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would checkout branch: $current_date"
    else
        git checkout -B "$current_date" 2>/dev/null
    fi

    # Push branch to remote with date-based naming
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would push branch: $current_date"
    else
        if ! git push --set-upstream origin "$current_date" 2>&1 >/dev/null; then
            echo "${repo_base}\t${current_date}" >> "$log_file"
        fi
    fi

    echo "Repository $repo_base backed up to branch '$current_date'."
    echo
done

# Handle log file
if [ $(wc -l < "$log_file") -gt "1" ]; then
    echo "Some branches failed to push. See $log_file for details."
    cat "$log_file"
else
    rm "$log_file"
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "DRY RUN complete. No changes were made."
fi
