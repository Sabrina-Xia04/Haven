#!/bin/bash
# =============================================================
# Haven → GitHub Auto-Sync (SSH)
# Runs via launchd every 2 hours.
# Only commits when there are actual changes.
# =============================================================

REPO="$HOME/Documents/Haven"
LOG="$REPO/scripts/sync.log"
MAX_LOG_LINES=500

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

# ── Rotate log so it doesn't grow forever ────────────────────
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt "$MAX_LOG_LINES" ]; then
    tail -n 200 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi

log "──────── sync started ────────"

# ── Ensure SSH agent has keys loaded ─────────────────────────
if ! ssh-add -l &>/dev/null; then
    # Try the default Ed25519 key first, then RSA fallback
    for KEY in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa"; do
        if [ -f "$KEY" ]; then
            ssh-add "$KEY" 2>/dev/null && log "SSH key loaded: $KEY" && break
        fi
    done
fi

# ── Verify SSH access to GitHub ──────────────────────────────
if ! ssh -T git@github.com -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new 2>&1 \
    | grep -q "successfully authenticated"; then
    log "ERROR: SSH auth to GitHub failed — skipping push"
    exit 1
fi

cd "$REPO" || { log "ERROR: Cannot find $REPO"; exit 1; }

# ── Switch remote to SSH (idempotent) ────────────────────────
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null)
SSH_REMOTE="git@github.com:Sabrina-Xia04/Haven.git"
if [ "$CURRENT_REMOTE" != "$SSH_REMOTE" ]; then
    git remote set-url origin "$SSH_REMOTE"
    log "Remote updated to SSH: $SSH_REMOTE"
fi

# ── Stage everything ──────────────────────────────────────────
git add -A

# ── Only commit if something changed ─────────────────────────
if git diff --cached --quiet; then
    log "No changes — nothing to commit"
    exit 0
fi

CHANGED=$(git diff --cached --name-only | wc -l | tr -d ' ')
COMMIT_MSG="Auto-sync: $(date '+%Y-%m-%d %H:%M') · ${CHANGED} file(s)"
git commit -m "$COMMIT_MSG"

# ── Push ──────────────────────────────────────────────────────
if git push origin main 2>> "$LOG"; then
    log "Pushed successfully — ${CHANGED} file(s)"
else
    log "ERROR: Push failed — check log above for SSH/network details"
    exit 1
fi
