# Changelog

## 1.0.0 (unreleased)
- Initial public release: two-pass video analysis (yt-dlp transcript/metadata/links + Gemini native video understanding), frame extraction, 4 analysis modes (talk-summary, design-rebuild, ad-teardown, render-qa), optional dedup check against a notes folder.
- YouTube URLs direct (no download), 100+ platforms via yt-dlp download→upload, local files up to 2 GB.
- Handles Gemini "high demand" and daily quotas via retry + model cascade; YouTube 403/PO-token blocks via player-client fallback loop.
- Works transcript-only with zero API keys; free Gemini key unlocks the video eyes.
