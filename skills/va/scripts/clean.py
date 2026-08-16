#!/usr/bin/env python3
"""Wandelt yt-dlp-Output (info.json + VTT) in meta.md, links.md, transcript.md um."""
import json
import re
import sys
from pathlib import Path

out = Path(sys.argv[1])

info_files = sorted(out.glob("*.info.json"))
if not info_files:
    sys.exit("Kein .info.json in " + str(out))
info = json.loads(info_files[0].read_text())

# ---------- meta.md ----------
dur = int(info.get("duration") or 0)
lines = [
    f"# {info.get('title', '?')}",
    "",
    f"- Kanal: {info.get('uploader') or info.get('channel', '?')}",
    f"- Dauer: {dur // 60}:{dur % 60:02d} min",
    f"- Upload: {info.get('upload_date', '?')}",
    f"- Views: {info.get('view_count', '?')}",
    f"- URL: {info.get('webpage_url', '?')}",
]
chapters = info.get("chapters") or []
if chapters:
    lines += ["", "## Kapitel"]
    for c in chapters:
        s = int(c.get("start_time") or 0)
        lines.append(f"- [{s // 60}:{s % 60:02d}] {c.get('title', '')}")
desc = info.get("description") or ""
lines += ["", "## Beschreibung (komplett)", "", desc]
(out / "meta.md").write_text("\n".join(lines))

# ---------- links.md ----------
urls = re.findall(r"https?://[^\s)\]>\"']+", desc)
seen, uniq = set(), []
for u in urls:
    u = u.rstrip(".,;")
    if u not in seen:
        seen.add(u)
        uniq.append(u)
(out / "links.md").write_text(
    "# Links aus der Videobeschreibung\n\n" + "\n".join(f"- {u}" for u in uniq)
    + ("\n" if uniq else "(keine)\n")
)

# ---------- transcript.md ----------
vtts = sorted(out.glob("*.vtt"))
# manuelle Subs vor Auto-Subs, Deutsch vor Englisch
def rank(p: Path) -> int:
    n = p.name
    r = 0
    if ".de" in n:
        r -= 2
    if "-orig" in n or not re.search(r"\.[a-z]{2}(-[A-Za-z]+)?\.vtt$", n):
        r -= 1
    return r

if not vtts:
    (out / "transcript.md").write_text("(keine Captions gefunden — Whisper-Fallback nötig)\n")
    sys.exit(0)

vtt = sorted(vtts, key=rank)[0]
text = vtt.read_text()

cue_re = re.compile(r"(\d+):(\d{2}):(\d{2})\.\d{3} --> ")
tag_re = re.compile(r"<[^>]+>")
entries = []  # (seconds, line)
cur = None
for raw in text.splitlines():
    m = cue_re.match(raw)
    if m:
        h, mnt, s = map(int, m.groups())
        cur = h * 3600 + mnt * 60 + s
        continue
    line = tag_re.sub("", raw).strip()
    if not line or line == "WEBVTT" or line.startswith(("Kind:", "Language:", "NOTE")):
        continue
    if cur is None:
        continue
    # Auto-Captions wiederholen Zeilen rollierend -> dedup gegen die letzten 2 Zeilen
    if any(line == e[1] for e in entries[-2:]):
        continue
    entries.append((cur, line))

# Zu Blöcken je ~30s zusammenfassen, damit das Transkript kompakt bleibt
blocks, block, block_t = [], [], None
for t, line in entries:
    if block_t is None:
        block_t = t
    if t - block_t >= 30 and block:
        blocks.append((block_t, " ".join(block)))
        block, block_t = [], t
    block.append(line)
if block:
    blocks.append((block_t, " ".join(block)))

def ts(t: int) -> str:
    return f"{t // 3600}:{t % 3600 // 60:02d}:{t % 60:02d}" if t >= 3600 else f"{t // 60}:{t % 60:02d}"

md = [f"# Transkript ({vtt.name})", ""]
md += [f"**[{ts(t)}]** {txt}\n" for t, txt in blocks]
(out / "transcript.md").write_text("\n".join(md))
print(f"transcript: {len(blocks)} Blöcke aus {len(entries)} Zeilen ({vtt.name})", file=sys.stderr)
