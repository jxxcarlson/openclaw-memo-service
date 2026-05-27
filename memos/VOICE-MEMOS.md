# Voice Memos Workflow

Convert voice memos to text and add them to your daily memo file.

## Setup

Audio files are processed by the local Whisper transcriber (no API keys needed).

**Directories:**
- `memos/audio-inbox/` — drop audio files here
- `memos/audio-archive/` — processed files go here

**Supported formats:** MP3, M4A, WAV, OGG, FLAC, and more

## Process

1. **Drop audio file** into `memos/audio-inbox/`
   - Via Finder, command line, or sync service
   
2. **Run transcription:**
   ```bash
   ./memos/transcribe.sh
   ```
   
3. **Result:**
   - Audio transcribed with Whisper
   - Text added to today's memo file with timestamp
   - Original audio moved to `memos/audio-archive/`

## Example

```bash
# Drop a file named "morning-thoughts.m4a" into audio-inbox/
# Then:
./memos/transcribe.sh

# Result in 2026-05-26.md:
## 05:10 — Voice Memo

This is my morning thought. I'm thinking about the project...
```

## Telegram Integration

Audio you send via Telegram gets transcribed automatically and added to your memo.

If you want to manually process Voice Memos from your iPhone:

1. Export from Voice Memos app
2. Send to yourself via iCloud, email, or AirDrop
3. Save to `memos/audio-inbox/`
4. Run `./transcribe.sh`

---

**Future:** Could set up a watcher to run transcription automatically as files arrive.
