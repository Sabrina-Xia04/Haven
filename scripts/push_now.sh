#!/bin/bash
echo "=== Haven → GitHub SSH Push ==="
cd ~/Documents/Haven || { echo "ERROR: ~/Documents/Haven not found"; exit 1; }

# Switch to SSH remote
git remote set-url origin git@github.com:Sabrina-Xia04/Haven.git
echo "Remote: $(git remote get-url origin)"

# Pull latest scripts from /tmp/haven_git
rsync -a --exclude='.git' /tmp/haven_git/ ~/Documents/Haven/

# Stage and commit
git add -A
if git diff --cached --quiet; then
  echo "Nothing new to commit — pushing existing commits"
else
  git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M')"
fi

# Push via SSH
git push origin main && echo "✓ Push successful" || echo "✗ Push failed — check SSH key"
