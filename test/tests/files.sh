#!/bin/sh

echo "Testing required files..."
echo ""

test_file() {
  local file=$1
  local name=$2
  local required=$3

  if [ -f "$file" ]; then
    success "$name exists"
  else
    if [ "$required" = "true" ]; then
      error "$name does not exist: $file"
    else
      warn "$name does not exist (optional): $file"
    fi
  fi
}

test_file "$HOME/.dotfiles/config/Brewfile" "Brewfile" "true"

echo ""
echo "Testing environment files..."
echo ""

for envfile in aliases.zsh exports.zsh functions.zsh path.zsh zshrc lazy.zsh; do
  test_file "$HOME/.dotfiles/config/env/$envfile" "env/$envfile" "true"
done

echo ""
echo "Testing Claude review system..."
echo ""

for agent in fresh-eyes-reviewer review-verifier; do
  test_file "$HOME/.dotfiles/config/claude/agents/$agent.md" "claude/agents/$agent.md" "true"
done

for skill in pre-merge-review review-scaffold review-eval; do
  test_file "$HOME/.dotfiles/config/claude/skills/$skill/SKILL.md" "claude/skills/$skill/SKILL.md" "true"
done

echo ""
echo "Testing skill layout..."
echo ""

# A skill whose SKILL.md sits at the wrong depth never loads, and the only
# symptom is Claude silently not using it. cran-check hid that way for months.
for dir in "$HOME"/.dotfiles/config/claude/skills/*/; do
  skill=$(basename "$dir")
  [ "$skill" = "synced" ] && continue
  if [ ! -f "$dir/SKILL.md" ]; then
    error "claude/skills/$skill has no SKILL.md at the top level"
  elif find "$dir" -mindepth 2 -name SKILL.md | grep -q .; then
    error "claude/skills/$skill has a nested SKILL.md — that copy will not load"
  else
    success "claude/skills/$skill has SKILL.md at the right depth"
  fi
done

for tmpl in REVIEW.md RISK_TIERS.md ROLLBACK.md pull_request_template.md; do
  test_file "$HOME/.dotfiles/config/claude/templates/review/$tmpl" "claude/templates/review/$tmpl" "true"
done
