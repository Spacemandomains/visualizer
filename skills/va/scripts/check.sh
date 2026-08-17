#!/bin/bash
# Pass 0: dedup check - is this video already in your notes library?
# Costs 0 tokens (pure grep; your notes contain their video URL, so they ARE the index).
# usage: check.sh <youtube-url-or-id>   (requires VA_NOTES_DIR to point at your notes folder)
# Exit 0 + paths = already analyzed - Exit 1 = new - Exit 3 = no notes dir configured
set -euo pipefail
PY=$(command -v python3 || command -v python)
IN="$1"
DIR="${VA_NOTES_DIR:-}"
[ -n "$DIR" ] && [ -d "$DIR" ] || { echo "No VA_NOTES_DIR configured - skipping dedup."; exit 3; }
ID=$(printf '%s' "$IN" | "$PY" -c '
import re, sys
s = sys.stdin.read().strip()
m = re.search(r"(?:youtu\.be/|v=|shorts/|embed/)([A-Za-z0-9_-]{11})", s)
print(m.group(1) if m else (s if re.fullmatch(r"[A-Za-z0-9_-]{11}", s) else ""))
')
[ -n "$ID" ] || { echo "ERROR: no YouTube ID found in: $IN" >&2; exit 2; }
FOUND=$(grep -rl --include='*.md' "$ID" "$DIR" 2>/dev/null || true)
if [ -n "$FOUND" ]; then echo "ALREADY IN LIBRARY ($ID):"; echo "$FOUND"; exit 0
else echo "NEW: $ID not in library yet."; exit 1; fi
