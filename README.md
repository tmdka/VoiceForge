# VoiceForge

VoiceForge is a local text-to-speech studio with a polished browser interface, generation history, voice previews, WAV export, and optional MP3 export. It runs entirely on your Windows PC using Kokoro through `sherpa-onnx`.

## Features

- Local and private text-to-speech generation
- Kokoro multi-language voice catalogue
- Voice previews with local caching
- Adjustable speech speed
- Live queued/processing/completed generation status
- Persistent generation history
- WAV download and playback
- Optional MP3 export through FFmpeg
- No Python packages required; the backend uses the Python standard library

## Requirements

- Windows 10 or Windows 11
- Python 3.8 or newer available on `PATH`
- Kokoro/sherpa-onnx files, expected by default under `C:\llama.cpp\tts`
- Optional: FFmpeg on `PATH` for MP3 export

Expected default engine files:

```text
C:\llama.cpp\tts\bin\sherpa-onnx-offline-tts.exe
C:\llama.cpp\tts\kokoro-multi-lang-v1_0\model.onnx
C:\llama.cpp\tts\kokoro-multi-lang-v1_0\voices.bin
C:\llama.cpp\tts\kokoro-multi-lang-v1_0\tokens.txt
C:\llama.cpp\tts\kokoro-multi-lang-v1_0\lexicon-us-en.txt
C:\llama.cpp\tts\kokoro-multi-lang-v1_0\espeak-ng-data\
```

## Quick start

1. Download or clone this repository.
2. Double-click `START_VOICEFORGE.bat`.
3. Open `http://localhost:8765` if the browser does not open automatically.
4. Enter text, select a voice, and generate audio.

```powershell
git clone https://github.com/tmdka/VoiceForge.git
cd VoiceForge
.\START_VOICEFORGE.bat
```

## Configuration

On first launch, VoiceForge creates `config.json`. Use it to change the engine location, server address, port, thread count, speed flag, extra engine arguments, or voice-name overrides.

Example:

```json
{
  "tts_root": "C:\\llama.cpp\\tts",
  "exe": null,
  "model_dir": null,
  "lexicon": "lexicon-us-en.txt",
  "num_threads": 4,
  "host": "127.0.0.1",
  "port": 8765,
  "speed_flag": "--kokoro-length-scale",
  "extra_args": [],
  "voices_override": {
    "3": { "name": "Narrator" },
    "19": { "hide": true }
  }
}
```

Generated files are written to `outputs/`, while cached voice previews are stored in `previews/`. Both folders are intentionally excluded from Git.

## Project structure

```text
VoiceForge/
├── START_VOICEFORGE.bat   Windows launcher
├── server.py              Local API, queue, engine integration, and storage
├── web/
│   └── index.html         Complete studio interface
├── config.example.json    Configuration reference
└── README.md
```

## REST API

| Method | Route | Purpose |
|---|---|---|
| `GET` | `/api/health` | Engine readiness, voice count, and MP3 support |
| `GET` | `/api/voices` | Voice catalogue |
| `GET` | `/api/preview/{voiceId}` | Generate or return a cached preview |
| `POST` | `/api/generate` | Queue a speech generation job |
| `GET` | `/api/generations` | List generation history |
| `GET` | `/api/generations/{id}` | Get one generation record and status |
| `GET` | `/api/audio/{id}.wav` | Stream or download WAV audio |
| `GET` | `/api/audio/{id}.mp3` | Stream or download MP3 audio when available |
| `DELETE` | `/api/generations/{id}` | Delete one generation |
| `DELETE` | `/api/generations` | Clear generation history and audio files |

Example:

```powershell
curl.exe -X POST http://localhost:8765/api/generate `
  -H "Content-Type: application/json" `
  -d '{"text":"Hello from VoiceForge.","voiceId":"kokoro-3","speed":1.0,"format":"wav"}'
```

## Troubleshooting

- **Missing files:** update `tts_root`, `exe`, or `model_dir` in `config.json`.
- **Port already in use:** close the other VoiceForge instance or change the configured port.
- **No MP3 option:** install FFmpeg and make sure `ffmpeg` is on `PATH`.
- **A voice fails:** the selected speaker ID may not exist in that model build; hide or rename it using `voices_override`.
- **Speed is ignored:** the installed sherpa-onnx build may not support the configured length-scale flag; VoiceForge retries at normal speed.

## Privacy

VoiceForge binds to `127.0.0.1` by default and processes text locally. Do not change the host to a network-accessible address unless you understand the security implications.

## License

No open-source license has been declared yet. All rights are reserved by the repository owner.
