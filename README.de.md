# Visualizer (/va)

**🇬🇧 [English version →](README.md)**

> Claude kann kein Video sehen. Gemini schon — gratis. Visualizer gibt Claude echte Video-Augen: Bild + Ton + Timestamps statt Frame-Raterei.

Beliebige Video-URL in Claude Code einwerfen und eine strukturierte Analyse bekommen: Kernaussagen mit Timestamps, jedes Diagramm und UI beschrieben, jedes erwähnte Tool/Repo (auch nur eingeblendete) extrahiert, Gelaber und Werbung ehrlich markiert. Funktioniert mit **YouTube-URLs direkt (ohne Download), 100+ Plattformen via yt-dlp und lokalen Dateien bis 2 GB**.

**Der Unterschied:** Die meisten „Claude schaut Video"-Tools extrahieren Einzelbilder und hoffen, dass der wichtige Moment auf einem landet. Visualizer schickt das echte Video an Geminis natives Video-Verständnis (das einzige Frontier-Modell mit echtem Video-Input) — es *sieht Bewegung und hört den Ton* — und kombiniert das mit dem, was Gemini nicht sieht: der Videobeschreibung (da stehen die Links) und exakten Untertitel-Zitaten.

## Visualizer vs. Frame-Extraktion (z. B. [claude-video](https://github.com/bradautomates/claude-video))

Auf der Suche nach einer **claude-video-Alternative**? Ehrlicher Vergleich — Brads `/watch` ist exzellent und hat die Kategorie begründet:

| | Frame-Extraktion (`/watch`) | **Visualizer (`/va`)** |
|---|---|---|
| Wie Claude „sieht" | gesampelte Standbilder + Transkript | natives Video-Verständnis (Gemini): Bewegung, Ton, Timestamps |
| Audio | nur Transkript (Whisper-Key ohne Captions) | nativ gehört — auch Videos ganz ohne Untertitel |
| Videos ohne Sprache | Transkript leer, nur Frames | voll analysiert (Bild + Ton) |
| Lange Videos | Frames werden dünn (1 Frame/72 s bei 2 h) | durchgehendes Verständnis, serverseitiges Clipping |
| Beschreibungs-Links | — | extrahiert (Creator verlinken dort, nicht im Video) |
| API-Key nötig | Whisper-Key ohne Captions | gratis Gemini-Key (Transkript-Pass läuft mit **null** Keys) |
| Kosten | Claude-Tokens pro Frame | Gemini Free Tier: **8 h YouTube/Tag**; bezahlt ~0,05–0,15 $ pro 30-min-Video |
| Plattformen | 1.600+ via yt-dlp | YouTube direkt + 100+ via yt-dlp + lokale Dateien |

## Installation (Claude Code)

```bash
/plugin marketplace add tomschonamsgruber/visualizer
/plugin install visualizer@visualizer
```

**Andere Agenten** (Codex CLI, Cursor, Gemini CLI — alles mit [Agent-Skills-Support](https://skills.sh)):

```bash
npx skills add tomschonamsgruber/visualizer -g
```

Die Scripts sind reines Bash/Python — jeder Agent mit Shell-Zugriff kann sie nutzen. (Die Qualität des finalen Merge hängt vom Host-Modell ab.)

Abhängigkeiten (`yt-dlp`, `ffmpeg`) installiert Claude beim ersten Lauf für dich, oder:

```bash
brew install yt-dlp ffmpeg   # macOS
```

## Setup: der kostenlose Gemini-Key (optional, aber empfohlen)

Pass 1 (Transkript + Metadaten + Beschreibungs-Links) läuft **ganz ohne Key**.
Die Video-Augen brauchen einen kostenlosen Gemini-API-Key:

1. [aistudio.google.com/apikey](https://aistudio.google.com/apikey) → „Create API key" (Free Tier, kein Billing)
2. ```bash
   mkdir -p ~/.config/va && echo 'GEMINI_API_KEY=DEIN_KEY' > ~/.config/va/env && chmod 600 ~/.config/va/env
   ```

Der Free Tier deckt ~8 Stunden YouTube pro Tag. Überlastung und Tages-Quotas werden automatisch abgefangen (Retry + Modell-Kaskade).

## Nutzung

Einfach eine Video-URL einwerfen — der Skill triggert von selbst. Oder explizit:

```
/va https://youtu.be/... was sind die Kernaussagen?
```

Analyse-Modi (automatisch nach Videotyp gewählt): **talk-summary** (Talks/Tutorials) · **design-rebuild** (Design/UI, Hex-Farben, Code wörtlich) · **ad-teardown** (Werbung/UGC) · **render-qa** (KI-Renders auf Konsistenz prüfen). Dazu Frame-Extraktion für Notizen mit echten Bildern.

## Ehrliche Grenzen

- YouTube-Pass braucht **öffentliche** Videos (unlisted/privat → Datei herunterladen und lokal übergeben).
- Gemini Free Tier hat Tages-Limits — die Kaskade weicht unter Last auf kleinere Modelle aus.
- Hex-Farben und kleiner Bildschirmtext sind Schätzungen bei Video-Auflösung.
- Auto-Untertitel verstümmeln Namen; der Merge-Schritt gleicht Transkript und Video gegeneinander ab.

## Lizenz

MIT — siehe [LICENSE](LICENSE). Nicht verbunden mit Google oder Anthropic.
