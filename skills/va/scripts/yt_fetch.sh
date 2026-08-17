#!/bin/bash
# Pass 1: Metadaten + Beschreibung + Captions holen und bereinigen.
# usage: yt_fetch.sh <url> <outdir>
set -euo pipefail
PY=$(command -v python3 || command -v python)
URL="$1"
OUT="${2:-.}"
mkdir -p "$OUT"

# Schritt 1: Metadaten/Beschreibung IMMER zuerst sichern (eigener billiger Call) —
# damit liefert Pass 1 auch dann meta.md + links.md, wenn die Untertitel 429en.
yt-dlp --skip-download --write-info-json --no-write-subs \
  --retries 5 --retry-sleep 5 \
  -o "$OUT/video.%(ext)s" "$URL" >&2

# Schritt 2: Untertitel-Endpoint von YouTube ist 429-empfindlich: nur EINE Sprache
# ziehen (Original-Sprache bevorzugt), mit Pausen und Retries. Scheitern ist ok.
fetch_subs() {
  yt-dlp --skip-download \
    --write-subs --write-auto-subs \
    --sub-langs "$1" --sub-format vtt \
    --sleep-subtitles 3 --retries 5 --retry-sleep 10 \
    -o "$OUT/video.%(ext)s" \
    "$URL" >&2
}
fetch_subs "en-orig,en.*" || true
ls "$OUT"/*.vtt >/dev/null 2>&1 || { sleep 10; fetch_subs "de,de-orig"; } || true

"$PY" "$(cd "$(dirname "$0")" && pwd)/clean.py" "$OUT"
echo "OK: $OUT/meta.md $OUT/links.md $OUT/transcript.md"
