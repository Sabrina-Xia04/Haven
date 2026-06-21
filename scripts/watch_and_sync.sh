#!/bin/bash
# =====================================================
# Haven — Auto-commit on file change (fswatch)
# Run once: bash ~/Documents/Haven/scripts/watch_and_sync.sh
# Keeps running in background; Ctrl+C to stop.
# =====================================================

REPO="$HOME/Documents/Haven"
LOG="$REPO/scripts/sync.log"
DEBOUNCE=3   # seconds to wait after last change before committing

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"; }

# Check fswatch is installed
if ! command -v fswatch &>/dev/null; then
    echo "fswatch not found. Install with: brew install fswatch"
    exit 1
fi

log "👀 Watching $REPO for changes..."

# Watch directory, exclude .git and log files
fswatch -o \
    --exclude "\.git/" \
    --exclude "sync\.log" \
    --exclude "\.DS_Store" \
    "$REPO" | while read -r CHANGE_COUNT; do

    # Debounce: wait for writes to settle
    sleep "$DEBOUNCE"

    cd "$REPO" || continue

    # Stage everything
    git add -A

    # Only commit if there are actual changes
    if git diff --cached --quiet; then
        continue
    fi

    CHANGED=$(git diff --cached --name-only | wc -l | tr -d ' ')
    FILES=$(git diff --cached --name-only | head -3 | tr '\n' ' ')
    MSG="Auto: $(date '+%H:%M') · ${FILES}(+$((CHANGED - 3 > 0 ? CHANGED - 3 : 0)) more)"

    git commit -m "$MSG" --quiet
    git push origin main --quiet && log "✓ Pushed: $FILES" \
                                 || log "✗ Push failed"
done
