---
name: clean-commit
description: Create a commit with strict staging discipline — explicit paths only, no blanket adds, formatter/linter must pass first. Use for any commit, especially when there's pre-existing WIP that must not be swept in.
---

# /clean-commit

Defensive commit flow that prevents accidental staging of unrelated WIP and protects against zsh history-modifier bugs.

## Steps

1. **Inventory**
   - `git status` and `git diff` to see all changes
   - Identify which files belong to the current task vs pre-existing WIP
   - If unsure about any file, ask the user before staging it

2. **Format & lint first**
   - Run the formatter and linter for the language of the changed files
   - Do not proceed if either fails — fix it, then re-inventory

3. **Stage explicitly**
   - List each path as a separate argument: `git add path/one path/two path/three`
   - Never `git add .`, `git add -A`, `git add -u`, or `git add <directory>` unless you've verified every file inside belongs to this commit
   - After staging, run `git diff --cached --stat` and confirm the file list matches the inventory

4. **Compose the message**
   - Conventional commit format: `<type>(<scope>): <subject>`
   - Body explains the WHY (one paragraph), not the WHAT (the diff shows that)
   - Include the Claude Code co-author trailer

5. **Commit with a quoted HEREDOC**
   - Use single-quoted HEREDOC delimiter (`<<'EOF'`) so zsh history modifiers like `!` cannot expand inside the message
   - Example:

     ```bash
     git commit -m "$(cat <<'EOF'
     fix(scheduler): handle overlapping ICS events

     Overlaps were silently dropped because the merge keyed on start-time only.
     Now keys on (start, uid) so distinct events at the same minute survive.

     Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
     EOF
     )"
     ```

6. **Verify before push**
   - `git show --stat HEAD` to confirm the commit contents
   - `git log --oneline -5` to confirm it landed on the right branch
   - Only then push, and only to the branch you expect: `git push -u origin <branch>`

## When this skill is critical

- After a session with many tool edits where some files may be from earlier WIP
- When operating on a repo that has untracked files unrelated to your task
- Any bulk operation (`gh pr close`, `git branch -D`, mass push) — list-then-execute, never one-shot
