#!/bin/bash
# Pass 2 (Meta alternative): Muse Spark watches the video via the Meta Model API.
#   - URL (YouTube or direct video URL): sent as input_video / video_url, no download
#   - local file (.mp4): uploaded via the Meta Files API (purpose=user_data),
#     then referenced as input_file
# usage: meta_watch.sh <url-oder-dateipfad> <prompt> [model]
# key: MODEL_API_KEY env var or ~/.config/va/env (line MODEL_API_KEY=...)
# Gemini path (gemini_watch.sh) is unchanged; this is a parallel backend.
set -euo pipefail
IN="$1"
PROMPT="$2"
MODEL="${3:-muse-spark-1.3}"
BASE="${META_BASE_URL:-https://api.meta.ai/v1}"
PY=$(command -v python3 || command -v python)

if [ -z "${MODEL_API_KEY:-}" ] && [ -f "$HOME/.config/va/env" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/va/env"
fi
[ -n "${MODEL_API_KEY:-}" ] || { echo "FEHLER: MODEL_API_KEY nicht gesetzt (https://dev.meta.ai/)" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [ -f "$IN" ]; then
  # Local file -> Files API upload, then input_file reference
  echo ">> Upload zur Meta Files API ..." >&2
  FILE_ID=$(curl -sS "$BASE/files" \
    -H "Authorization: Bearer $MODEL_API_KEY" \
    -F "purpose=user_data" \
    -F "file=@$IN" | "$PY" -c 'import json,sys; print(json.load(sys.stdin)["id"])')
  MEDIA_JSON=$("$PY" - "$FILE_ID" <<'PY'
import json, sys
print(json.dumps({"type": "input_file", "file_id": sys.argv[1]}))
PY
)
else
  MEDIA_JSON=$("$PY" - "$IN" <<'PY'
import json, sys
print(json.dumps({"type": "input_video", "video_url": sys.argv[1]}))
PY
)
fi

BODY=$("$PY" - "$MEDIA_JSON" "$PROMPT" "$MODEL" <<'PY'
import json, sys
media = json.loads(sys.argv[1])
prompt, model = sys.argv[2], sys.argv[3]
print(json.dumps({
    "model": model,
    "input": [{"role": "user", "content": [
        {"type": "input_text", "text": prompt},
        media,
    ]}],
}))
PY
)

curl -sS --max-time 600 "$BASE/responses" \
  -H "Authorization: Bearer $MODEL_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY" -o "$TMP/resp"

"$PY" - "$TMP/resp" <<'PY'
import json, sys
resp = json.load(open(sys.argv[1]))
if "error" in resp and resp["error"]:
    err = resp["error"]
    print("META:", err.get("message", err) if isinstance(err, dict) else err, file=sys.stderr)
    sys.exit(1)
text = resp.get("output_text", "")
if not text:
    parts = []
    for item in resp.get("output", []) or []:
        for part in item.get("content", []) or []:
            if isinstance(part, dict) and part.get("text"):
                parts.append(part["text"])
    text = "\n".join(parts)
if not text:
    print("META: keine Textantwort", file=sys.stderr)
    sys.exit(1)
print(text)
PY
