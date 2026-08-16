---
name: va
description: Visualizer - truly understand videos. Two-pass analysis (yt-dlp transcript/metadata/links + Gemini as native video eyes) distilled into a structured answer. Use whenever a video is involved, even without an explicit /va call - when the user pastes a YouTube/TikTok/Loom/Vimeo URL or a video file (.mp4/.mov/.webm/.mkv), wants a video watched/summarized/analyzed, asks what is said or shown in a video, wants key takeaways from a talk/tutorial, wants links/tools/repos extracted from a video, or wants to rebuild UI/design shown in a video.
---

# Visualizer (/va) — truly understand videos

All scripts and prompt templates live in `scripts/` and `prompts/` next to this file —
resolve their paths from this skill's base directory (shown when the skill loads).

Two passes run by default (both, whenever a Gemini key is available), then YOU merge
the results into one answer. Without a key, Pass 1 alone still works (transcript-only).

## Pass 0 — Dedup check (0 tokens, only if the user keeps a notes folder)
If `VA_NOTES_DIR` is set (or the user has told you where their video notes live), grep
that folder for the video ID before analyzing. Hit → point to the existing note instead
of re-analyzing. No notes folder → skip this pass.

## Pass 1 — yt-dlp (free, seconds, no API key needed)

```bash
<skill-dir>/scripts/yt_fetch.sh "<URL>" "<outdir>"
```

Writes to `<outdir>`:
- `meta.md` — title, channel, duration, date, chapters, **full video description**
- `links.md` — every URL from the description (the main source for mentioned tools/repos — Gemini never sees the description!)
- `transcript.md` — cleaned transcript with `[MM:SS]` timestamps

Use a temp/scratch directory. For videos >1h, read the transcript in sections.

## Pass 2 — Gemini as video eyes (free tier: 8h YouTube/day)

```bash
<skill-dir>/scripts/gemini_watch.sh "<URL-or-file>" "<prompt>" > "<outdir>/gemini.md"
```

ALWAYS redirect output to a file (it is long and gets truncated otherwise), then read the file.

- Accepts YouTube URLs (direct, no download), **any other platform URL** (yt-dlp download ≤720p → Files API upload) and **local files** up to 2 GB (upload).
- Key: `GEMINI_API_KEY` env var or `~/.config/va/env` (line `GEMINI_API_KEY=...`).
  Get one free at https://aistudio.google.com/apikey — no key? Run Pass 1 only and tell
  the user what the key would unlock (visuals, audio, OCR).
- Model override as 3rd argument. Default cascade handles "high demand" and daily quotas
  automatically (retries + model fallback).
- YouTube: **public videos only** (unlisted/private → obtain the file and pass a local path).
- Shorts URLs: pass to Gemini in `watch?v=` form.
- **Analysis modes** in `prompts/`: pick by video type and append the user's actual question:
  - `talk-summary.md` — talks, tutorials, lectures (default for knowledge videos)
  - `design-rebuild.md` — website/UI/design videos, goal: rebuild
  - `ad-teardown.md` — ads, UGC, viral shorts, competitor analysis
  - `render-qa.md` — AI-generated renders, consistency/artifact QA
  Each mode ends by requesting a `FRAME: MM:SS — description` list (input for Pass 3).
- For segments: prefix the prompt with `Analyze only MM:SS to MM:SS`.

## Pass 3 (optional) — frames as images

```bash
<skill-dir>/scripts/frames.sh "<URL-or-file>" "<outdir>" 2:42 7:37 ...
```

Take timestamps from Pass 2's `FRAME:` list. Writes `frame-MM-SS.jpg`; for URLs the
video is cached once as `<outdir>/.video.mp4` (delete after). View the frames yourself
(Read) before using them — keep only the ones that carry real content.

## Merge — your actual job

Default output is a structured ANSWER IN CHAT:
- TL;DR (3-5 sentences)
- Key takeaways with `[MM:SS]`, most important first — never a chronological retelling
- Visuals (diagrams/slides/UI from Pass 2, with timestamps)
- Links & mentioned tools (description + transcript + OCR merged, deduplicated)
- Honest verdict: what is genuinely useful, what is filler/ads (call it out, with time ranges)

Rules:
- Contradictions: the transcript wins on exact wording, Gemini wins on visuals.
- ALWAYS merge links from all three sources (description, spoken, on-screen OCR).
- **Saving notes is opt-in**: only write a markdown note to disk when the user asks
  (or has a standing notes folder). Then: one file per video, named
  `YYYY-MM-DD Creator - Title.md`, images beside it.

## Fallbacks
- No captions → Pass 2 alone is enough (Gemini hears the audio natively); additionally
  request a timestamped transcript of the key statements in the prompt.
- No Gemini key → Pass 1 only (transcript, description links, metadata) — still covers
  most talk-style videos.
- Local files / non-YouTube → `gemini_watch.sh` handles download/upload automatically.
