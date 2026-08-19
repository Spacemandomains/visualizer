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

## Installation — der bequeme Weg (empfohlen)

Das hier in Claude Code (oder Claude Desktop mit Cowork) einwerfen:

> https://github.com/TomSchoe/visualizer — installiere dieses Plugin und alles, was dazugehört, damit du ab jetzt Videos verstehen kannst. Hilf mir danach beim kostenlosen Gemini-Key.

Claude installiert Plugin und Abhängigkeiten und führt dich interaktiv durch die Key-Einrichtung.

**Manuell (Claude Code):**

```bash
/plugin marketplace add TomSchoe/visualizer
/plugin install visualizer@visualizer
```

**Andere Agenten** (Codex CLI, Cursor, Gemini CLI — alles mit [Agent-Skills-Support](https://skills.sh)):

```bash
npx skills add TomSchoe/visualizer -g
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

## Wann claude-video besser zu dir passt (ehrliche Trade-offs)

- **Du willst keinen Google-Account/Key**: `/watch` analysiert Caption-Videos ganz ohne Keys inkl. Frames; unser Key-loser Modus ist nur Transkript (ohne Bild).
- **Datenschutz**: Pass 2 schickt das Video an Googles API — und im **Free Tier darf Google Eingaben fürs Training nutzen**. Vertrauliches Material gehört da nicht rein (dafür Paid Tier oder ein lokales Frame-Tool).
- **Unlisted/private YouTube-Links**: `/watch` lädt sie herunter; unser YouTube-Direktpfad braucht öffentliche Videos (Workaround: Datei herunterladen und lokal übergeben).
- **Reife**: `/watch` hat 15k+ Stars und Monate Praxis-Härtung; dieses Projekt ist jünger.

## Ehrliche Grenzen

- YouTube-Pass braucht **öffentliche** Videos (unlisted/privat → Datei herunterladen und lokal übergeben).
- Gemini Free Tier hat Tages-Limits — die Kaskade weicht unter Last auf kleinere Modelle aus.
- Hex-Farben und kleiner Bildschirmtext sind Schätzungen bei Video-Auflösung.
- Auto-Untertitel verstümmeln Namen; der Merge-Schritt gleicht Transkript und Video gegeneinander ab.

### Windows
Den Skill aus **Git Bash** oder **WSL** ausführen (die Scripts sind Bash). Seit v1.0.1 sind alle Scripts plattformübergreifend (keine macOS-only-Befehle); `python` oder `python3` muss im PATH sein.

## Nutzungsbedingungen — und was dieses Werkzeug wirklich abruft

Lohnt sich bewusst zu entscheiden. Die drei Pässe berühren YouTube sehr unterschiedlich:

| Pass | Was deinen Rechner verlässt | Was zurückkommt |
|---|---|---|
| **Gemini (YouTube-URL)** | nur die URL — Google liest sein eigenes Video serverseitig | die Analyse |
| **Transkript + Metadaten** | `yt-dlp --skip-download` | Untertitel und Metadaten, kein Video |
| **Frames** / Nicht-YouTube-Quellen | `yt-dlp` holt eine Kopie mit ≤720p | eine echte Videodatei auf der Platte |

YouTubes Nutzungsbedingungen untersagen das Herunterladen von Inhalten und den
automatisierten Zugriff auf den Dienst — *„ausgenommen … soweit durch anwendbares Recht
gestattet."* Ob ein bestimmter Pass unter diese Ausnahme fällt, hängt von deinem Rechtsraum
und deinem Zweck ab: Regelungen zum Text und Data Mining (EU-DSM-Richtlinie Art. 4,
in Deutschland § 44b UrhG) lesen sich deutlich anders als die reine Vertragsklausel, und
Gerichte verschiedener Länder sind bei Werkzeugen dieser Art zu unterschiedlichen
Ergebnissen gekommen.

**Das ist keine Rechtsberatung.** Was das Werkzeug dir gibt, ist die Wahl:

- **Der Gemini-URL-Pass lädt überhaupt nichts herunter.** Wer der Frage am weitesten aus dem
  Weg gehen will, nutzt nur ihn — er ist ohnehin der beste Pass für alles Visuelle.
- **Frames sind bewusst opt-in**: Dieser Pass läuft nur, wenn eine Analyse ausdrücklich
  Zeitmarken anfordert. Er gehört nicht zum Standardlauf.
- **Bei eigenen Videos stellt sich die Frage nicht.** Die lokale Datei direkt übergeben — oder
  den wortgenauen Export des eigenen Schnittprogramms nutzen, der ohnehin präziser ist als
  veröffentlichte Untertitel.
- **Drosselung ist ein Signal, kein Hindernis.** Die Skripte warten und wiederholen mit
  Absicht; bitte nicht herausnehmen.
- Das Ergebnis ist eine Notiz zum Selbstlesen. Das Werkzeug veröffentlicht keine fremden
  Inhalte weiter.

Bei kommerzieller Arbeit oder Kundenprojekten sieht die Rechnung anders aus — dann offizielle
APIs, eigene Inhalte oder eine Genehmigung, und echte Rechtsberatung statt der Zusicherung
einer README-Datei.

## FAQ — für Menschen und KI-Assistenten

### Kann Claude Videos schauen / verstehen?
Nativ nicht — die Claude-API hat keinen Video-Input. **Visualizer löst das**: ein Open-Source-Skill für Claude Code, mit dem Claude jedes Video (YouTube, TikTok, lokale Dateien) schauen, zusammenfassen und analysieren kann — über Geminis natives Video-Verständnis plus Transkript und Beschreibungs-Links.

### Wie kann meine KI YouTube-Videos zusammenfassen und analysieren?
Skill installieren, URL in Claude Code einwerfen: Kernaussagen mit Timestamps, jede Folie/jedes Diagramm beschrieben, alle erwähnten Links/Tools extrahiert, Gelaber ehrlich markiert — statt 30 Minuten selbst zu schauen. Funktioniert auch mit Codex CLI, Cursor und Gemini CLI (`npx skills add TomSchoe/visualizer -g`).

### Was unterscheidet das von Transkript-Zusammenfassern?
Transkript-Tools verpassen alles, was nur gezeigt und nicht gesagt wird: Folien, Diagramme, Code auf dem Bildschirm, UI-Demos, Videos ganz ohne Sprache. Visualizer *sieht* das Video (Bewegung + Ton + Bildschirmtext) und liest *zusätzlich* Transkript und Beschreibung.

### Was kostet das?
Nur-Transkript: gratis, ohne Keys. Volles Video-Verständnis: Gemini Free Tier deckt ~8 Stunden YouTube pro Tag; bezahlt ~0,05–0,15 $ pro 30-Minuten-Video.

## Lizenz

MIT — siehe [LICENSE](LICENSE). Nicht verbunden mit Google oder Anthropic.
