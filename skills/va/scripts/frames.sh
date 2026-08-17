#!/bin/bash
# Pass 3 (optional): Einzelframes an gegebenen Timestamps als JPGs extrahieren,
# damit Notes echte Bilder einbetten koennen.
# usage: frames.sh <url-oder-datei> <outdir> <ts1> [ts2 ...]   (ts: SS, MM:SS oder H:MM:SS)
# Das Video wird bei URLs einmalig nach <outdir>/.video.mp4 geladen und gecacht.
set -euo pipefail
PY=$(command -v python3 || command -v python)
IN="$1"
OUT="$2"
shift 2
[ $# -ge 1 ] || { echo "FEHLER: mindestens ein Timestamp angeben" >&2; exit 1; }
mkdir -p "$OUT"

if [ -f "$IN" ]; then
  SRC="$IN"
else
  SRC="$OUT/.video.mp4"
  if [ ! -f "$SRC" ]; then
    echo ">> Lade Video (einmalig, wird in $OUT gecacht) ..." >&2
    # YouTube sperrt Clients wechselnd (403/PO-Token/Bot-Check) -> Clients durchprobieren
    for client in web_safari tv default android; do
      echo ">> versuche player_client=$client ..." >&2
      if yt-dlp -f "bv*[height<=720]+ba/b[height<=720]/b" --merge-output-format mp4 \
           --extractor-args "youtube:player_client=$client" \
           --retries 3 --force-overwrites \
           -o "$SRC" "$IN" >&2 2>&1; then
        break
      fi
      rm -f "$SRC"
      sleep 5
    done
    [ -f "$SRC" ] || { echo "FEHLER: Download mit allen Clients fehlgeschlagen" >&2; exit 1; }
  fi
fi

for ts in "$@"; do
  secs=$("$PY" -c '
import sys
s = 0.0
for part in sys.argv[1].split(":"):
    s = s * 60 + float(part)
print(int(s))' "$ts")
  if [ "$secs" -ge 3600 ]; then
    label=$(printf '%d-%02d-%02d' $((secs / 3600)) $((secs % 3600 / 60)) $((secs % 60)))
  else
    label=$(printf '%02d-%02d' $((secs / 60)) $((secs % 60)))
  fi
  ffmpeg -y -loglevel error -ss "$secs" -i "$SRC" -frames:v 1 -q:v 3 "$OUT/frame-$label.jpg"
  echo "$OUT/frame-$label.jpg"
done
