#!/bin/bash
# Pass 2: Gemini schaut das Video.
#   - YouTube-URL:            direkt, ohne Download
#   - andere Plattform-URL:   yt-dlp-Download (<=720p) -> Gemini Files API
#   - lokale Datei:           Gemini Files API (bis 2 GB)
# usage: gemini_watch.sh <url-oder-dateipfad> <prompt> [model]
set -euo pipefail
IN="$1"
PROMPT="$2"
MODEL="${3:-gemini-3.7-flash}"
BASE="https://generativelanguage.googleapis.com"

if [ -z "${GEMINI_API_KEY:-}" ] && [ -f "$HOME/.config/va/env" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/va/env"
fi
[ -n "${GEMINI_API_KEY:-}" ] || { echo "FEHLER: GEMINI_API_KEY fehlt (env oder ~/.config/video-brain/env)" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FILE_URI=""
MIME=""
if [[ "$IN" == *youtube.com/* || "$IN" == *youtu.be/* ]]; then
  FILE_URI="$IN"   # YouTube: Gemini streamt selbst, kein Download
else
  if [ -f "$IN" ]; then
    FILE="$IN"
  else
    echo ">> Kein YouTube: lade Video per yt-dlp herunter ..." >&2
    yt-dlp -f "bv*[height<=720]+ba/b[height<=720]/b" --merge-output-format mp4 \
      -o "$TMP/video.%(ext)s" "$IN" >&2
    FILE=$(find "$TMP" -name 'video.*' -type f | head -1)
    [ -n "$FILE" ] || { echo "FEHLER: Download fehlgeschlagen" >&2; exit 1; }
  fi
  MIME=$(file -b --mime-type "$FILE")
  case "$MIME" in video/*|audio/*) ;; *) MIME="video/mp4" ;; esac
  NUM_BYTES=$(stat -f%z "$FILE")
  echo ">> Upload zur Gemini Files API ($((NUM_BYTES / 1024 / 1024)) MB) ..." >&2

  UPLOAD_URL=""
  for attempt in 1 2 3; do
    curl -sS "$BASE/upload/v1beta/files" -D "$TMP/hdrs" -o "$TMP/body" \
      -H "x-goog-api-key: $GEMINI_API_KEY" \
      -H "X-Goog-Upload-Protocol: resumable" \
      -H "X-Goog-Upload-Command: start" \
      -H "X-Goog-Upload-Header-Content-Length: $NUM_BYTES" \
      -H "X-Goog-Upload-Header-Content-Type: $MIME" \
      -H "Content-Type: application/json" \
      -d '{"file":{"display_name":"va-upload"}}' || true
    UPLOAD_URL=$(grep -i '^x-goog-upload-url: ' "$TMP/hdrs" 2>/dev/null | awk '{print $2}' | tr -d '\r' || true)
    [ -n "$UPLOAD_URL" ] && break
    echo ">> Upload-Start fehlgeschlagen (Versuch $attempt/3):" >&2
    head -1 "$TMP/hdrs" >&2 2>/dev/null || true
    cat "$TMP/body" >&2 2>/dev/null || true
    sleep $((attempt * 10))
  done
  [ -n "$UPLOAD_URL" ] || { echo "FEHLER: keine Upload-URL von der Files API (3 Versuche)" >&2; exit 1; }

  INFO=$(curl -sS "$UPLOAD_URL" \
    -H "Content-Length: $NUM_BYTES" \
    -H "X-Goog-Upload-Offset: 0" \
    -H "X-Goog-Upload-Command: upload, finalize" \
    --data-binary "@$FILE")
  FILE_URI=$(printf '%s' "$INFO" | python3 -c 'import json,sys;print(json.load(sys.stdin)["file"]["uri"])')
  FILE_NAME=$(printf '%s' "$INFO" | python3 -c 'import json,sys;print(json.load(sys.stdin)["file"]["name"])')

  echo ">> Warte auf Verarbeitung ..." >&2
  for _ in $(seq 1 120); do
    STATE=$(curl -sS "$BASE/v1beta/$FILE_NAME" -H "x-goog-api-key: $GEMINI_API_KEY" \
      | python3 -c 'import json,sys;print(json.load(sys.stdin).get("state","?"))')
    [ "$STATE" = "ACTIVE" ] && break
    [ "$STATE" = "FAILED" ] && { echo "FEHLER: Gemini-Verarbeitung fehlgeschlagen" >&2; exit 1; }
    sleep 5
  done
  [ "$STATE" = "ACTIVE" ] || { echo "FEHLER: Timeout beim Warten auf ACTIVE" >&2; exit 1; }
fi

BODY=$(python3 - "$FILE_URI" "$PROMPT" "$MIME" <<'PY'
import json, sys
uri, prompt, mime = sys.argv[1], sys.argv[2], sys.argv[3]
fd = {"file_uri": uri}
if mime:
    fd["mime_type"] = mime
print(json.dumps({"contents": [{"parts": [{"file_data": fd}, {"text": prompt}]}]}))
PY
)

# Modell-Kaskade mit Retries: Überlastung ("high demand", 429/503) -> warten und
# nochmal; anderer Modellfehler -> nächstes Modell probieren.
try_model() {
  local model="$1" rc
  curl -sS --max-time 600 \
    "$BASE/v1beta/models/${model}:generateContent" \
    -H "x-goog-api-key: $GEMINI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$BODY" -o "$TMP/resp" || return 2
  python3 - "$TMP/resp" <<'PY'
import json, sys
resp = json.load(open(sys.argv[1]))
if "error" in resp:
    msg = str(resp["error"].get("message", resp["error"]))
    code = resp["error"].get("code", 0)
    print("GEMINI:", msg, file=sys.stderr)
    sys.exit(2 if code in (429, 503) or "high demand" in msg or "overloaded" in msg.lower() else 3)
got = False
for cand in resp.get("candidates", []):
    for part in cand.get("content", {}).get("parts", []):
        if "text" in part:
            print(part["text"])
            got = True
sys.exit(0 if got else 3)
PY
  rc=$?
  return $rc
}

for model in "$MODEL" gemini-3.6-flash gemini-3.5-flash gemini-3-flash-preview; do
  for attempt in 1 2 3; do
    rc=0; try_model "$model" || rc=$?
    if [ "$rc" -eq 0 ]; then
      exit 0
    elif [ "$rc" -eq 2 ]; then
      echo ">> $model überlastet (Versuch $attempt/3), warte ..." >&2
      sleep $((attempt * 20))
    else
      echo ">> $model nicht nutzbar, probiere nächstes Modell ..." >&2
      break
    fi
  done
done
echo "FEHLER: kein Gemini-Modell hat geantwortet (alle überlastet oder nicht verfügbar)" >&2
exit 1
