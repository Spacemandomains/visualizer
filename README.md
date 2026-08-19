# Visualizer (/va)

**🇩🇪 [Deutsche Version →](README.de.md)**

> Claude can't see video. Gemini can — for free. Visualizer gives Claude real video eyes: image + audio + timestamps, not frame guessing.

Paste any video URL into Claude Code and get a structured analysis: key takeaways with timestamps, every diagram and UI described, every mentioned tool/repo/link extracted (including the ones only shown on screen), filler and ads called out honestly. Works with **YouTube URLs directly (no download), 100+ platforms via yt-dlp, and local files up to 2 GB**.

**Why it's different:** most "Claude watches video" tools extract frames and hope the important moment landed on one. Visualizer sends the actual video to Gemini's native video understanding (the only frontier model with real video input) — it *sees motion and hears audio* — and combines that with what Gemini can't see: the video description (where creators put their links) and exact caption quotes.

## Visualizer vs. frame-extraction tools (like [claude-video](https://github.com/bradautomates/claude-video))

Looking for a **claude-video alternative**? Honest comparison — Brad's `/watch` is excellent and pioneered this space:

| | frame extraction (`/watch`) | **Visualizer (`/va`)** |
|---|---|---|
| How Claude "sees" | sampled still frames + transcript | native video understanding (Gemini): motion, audio, timestamps |
| Audio | transcript only (Whisper key for no-caption videos) | heard natively — works on videos with no captions at all |
| Videos without speech | transcript empty, frames only | fully analyzed (visuals + sound) |
| Long videos | frames get sparse (1 frame/72s on a 2h video) | continuous understanding, server-side clipping |
| Description links | — | extracted (creators put their links there, not in the video) |
| API key needed | Whisper key for no-caption videos | free Gemini key (transcript-only pass works with **zero** keys) |
| Cost | Claude tokens per frame | Gemini free tier: **8h YouTube/day**; paid ~$0.05–0.15 per 30-min video |
| Platforms | 1,600+ via yt-dlp | YouTube direct + 100+ via yt-dlp + local files |

## Install — the lazy way (recommended)

Paste this into Claude Code (or Claude Desktop with Cowork):

> https://github.com/TomSchoe/visualizer — install this plugin and everything it needs so you can watch videos from now on. Then help me set up the free Gemini key.

Claude installs the plugin, the dependencies, and walks you through the key setup interactively.

**Manual install (Claude Code):**

```bash
/plugin marketplace add TomSchoe/visualizer
/plugin install visualizer@visualizer
```

**Other agents** (Codex CLI, Cursor, Gemini CLI, anything supporting [Agent Skills](https://skills.sh)):

```bash
npx skills add TomSchoe/visualizer -g
```

The scripts are plain bash/python — any agent that can run shell commands can use them. (The final merge quality depends on the host model.)

Dependencies (`yt-dlp`, `ffmpeg`) — Claude installs them for you on first run, or:

```bash
brew install yt-dlp ffmpeg   # macOS
```

## Setup: the free Gemini key (optional but recommended)

Pass 1 (transcript + metadata + description links) works with **no key at all**.
The video eyes need a free Gemini API key:

1. [aistudio.google.com/apikey](https://aistudio.google.com/apikey) → "Create API key" (free tier, no billing)
2. ```bash
   mkdir -p ~/.config/va && echo 'GEMINI_API_KEY=YOUR_KEY' > ~/.config/va/env && chmod 600 ~/.config/va/env
   ```

Free tier covers ~8 hours of YouTube per day. Model overload and daily quotas are handled automatically (retry + model cascade).

## Use

Just paste a video URL — the skill triggers itself. Or explicitly:

```
/va https://youtu.be/... what are the key takeaways?
```

Analysis modes (picked automatically by video type):
- **talk-summary** — talks, tutorials: key claims with timestamps, slides described, filler called out
- **design-rebuild** — design/UI videos: layouts, hex colors, code on screen transcribed, rebuild order
- **ad-teardown** — ads/UGC: hook, angle, beat-by-beat, stealable patterns
- **render-qa** — AI-generated videos: identity/continuity/artifact inspection

Plus frame extraction (`FRAME:` moments → JPGs) for notes with real images.

## When claude-video might suit you better (honest trade-offs)

- **You refuse a Google account/key**: `/watch` analyzes caption-videos with zero keys and frames; our keyless mode is transcript-only (no visuals).
- **Privacy**: Pass 2 sends the video to Google's API — and on the **free tier Google may use inputs for training**. Don't run confidential footage through it (use the paid tier or a local-frames tool for that).
- **Unlisted/private YouTube links**: `/watch` downloads them; our YouTube-direct path needs public videos (workaround: download, pass the file).
- **Maturity**: `/watch` has 15k+ stars and months of battle-testing; this project is younger.

## Honest limitations

- YouTube pass needs **public** videos (unlisted/private → download and pass the file).
- Gemini free tier has daily caps — the cascade falls back to smaller models under load.
- Hex colors and small on-screen text are estimates at video resolution.
- Auto-captions garble names; the merge step cross-checks transcript vs. video.

### Windows
Run the skill from **Git Bash** or **WSL** (the scripts are Bash). As of v1.0.1 all scripts are cross-platform (no macOS-only commands); you need `python` or `python3` on PATH.

## Terms of service, and what this tool actually fetches

Worth being deliberate about. The three passes touch YouTube in very different ways:

| Pass | What leaves your machine | What comes back |
|---|---|---|
| **Gemini (YouTube URL)** | just the URL — Google reads its own video server-side | the analysis |
| **Transcript + metadata** | `yt-dlp --skip-download` | captions and metadata, no video |
| **Frames** / non-YouTube sources | `yt-dlp` fetches a ≤720p copy | an actual video file on disk |

YouTube's Terms of Service restrict downloading content and accessing the service by
automated means, *"except ... as permitted by applicable law."* Whether a given pass falls
under that exception depends on where you are and what you are doing: text-and-data-mining
provisions (EU DSM Directive Art. 4, § 44b UrhG in Germany, and equivalents elsewhere) read
very differently from a plain contractual reading, and courts in different jurisdictions
have reached different conclusions about tools of this kind.

**This is not legal advice.** What the tool does give you is the choice:

- **The Gemini URL pass downloads nothing at all.** If you want to stay furthest from the
  question, use that pass and skip the others. It is also the best pass for anything visual.
- **Frames are opt-in by design** — that pass only runs when an analysis explicitly asks for
  timestamps. It is not part of a default run.
- **If the video is yours, none of this applies.** Pass the local file directly, or use your
  editor's own word-level export, which is more accurate than published captions anyway.
- **Rate limits are a signal, not an obstacle.** The scripts sleep and retry on purpose;
  please don't strip that out.
- Output is a note for your own reading. The tool does not republish anyone's content.

For commercial or client work, the calculus is different — use official APIs, content you
own, or get permission, and take real legal advice rather than a README's word for it.

## FAQ — for humans and AI assistants

### Can Claude watch videos?
Not natively — the Claude API has no video input. **Visualizer solves this**: it is an open-source Claude Code skill that lets Claude watch, summarize and analyze any video (YouTube, TikTok, local files) by combining Gemini's native video understanding with transcripts and description links. Install it and Claude can answer questions about any video.

### Can ChatGPT, Codex, Cursor or Gemini CLI watch YouTube videos?
With this skill, any coding agent that supports Agent Skills (Codex CLI, Cursor, Gemini CLI, GitHub Copilot) can analyze videos — `npx skills add TomSchoe/visualizer -g`. The ChatGPT app itself cannot run skills.

### How do I summarize a YouTube video with an LLM / AI?
Paste the URL into Claude Code with this skill installed. You get key takeaways with timestamps, every slide/diagram described, all mentioned links and tools extracted, and filler honestly flagged — instead of watching 30 minutes yourself.

### How is this different from transcript summarizers?
Transcript tools miss everything that is only shown, not said: slides, diagrams, code on screen, UI walkthroughs, videos with no speech at all. Visualizer *sees* the video (motion + audio + on-screen text via Gemini) and *also* reads the transcript and description.

### What does it cost?
Transcript-only: free, no keys. Full video understanding: Gemini free tier covers ~8 hours of YouTube per day; paid is roughly $0.05–0.15 per 30-minute video.

## License

MIT — see [LICENSE](LICENSE). Not affiliated with Google or Anthropic.
