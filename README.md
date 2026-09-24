# Jarvis Pi — fully offline voice assistant

A small Python assistant for a Raspberry Pi 4B with 4 GB RAM. AI inference remains entirely local. An optional daily sync uses the internet only for the configured ICS calendar and the Australian Bureau of Meteorology weather API, then caches the results locally.

## Features

- Wake-word-gated voice loop (`Jarvis`)
- Offline speech recognition through `whisper.cpp`
- Offline speech output through Piper
- Local `.ics` calendar reading
- Optional daily calendar refresh from an ICS URL
- Optional daily BOM weather refresh for Brogo with local cache
- Persistent reminders, timers, and alarms in SQLite
- Basic time/date questions without a model
- Homework and general questions through a small local Ollama model
- Text mode for testing: `python -m jarvis --text "set a timer in 2 minutes"`

## Pi setup

Use Raspberry Pi OS 64-bit and a heatsink/fan. Install Python 3.11+ and ALSA. The installer installs Ollama and pulls `qwen2.5:0.5b`, a small model suitable for a 4 GB Pi. It does require internet during setup; runtime remains local-only.

Run `./install.sh` on the Pi to create the virtual environment, install ALSA utilities, install Ollama, pull the model, and install the Python package. Use `./install.sh --no-apt` when system packages are already installed, or `./install.sh --no-ollama` to skip Ollama/model setup. Add `--enable-service` to install and start the offline boot service.

1. `whisper.cpp` with a small English GGML model. `ggml-tiny.en.bin` is the lowest-memory choice; `base.en` is more accurate but slower.
2. Piper with a local English voice, such as `en_US-lessac-medium.onnx`.
3. `llama.cpp` is optional; it remains available as a fallback if Ollama is skipped.

Set `JARVIS_OLLAMA_MODEL` in `.env` if you want a different locally pulled model. Set `JARVIS_CALENDAR_URL` to your private calendar's ICS URL. Weather defaults to Brogo, NSW through BOM geohash `r3d80t`; change `JARVIS_BOM_GEOHASH` only if you move location. Only the configured calendar URL and BOM API are contacted; no AI request leaves the Brain Pi.

The daily sync runs once at startup and then every `JARVIS_SYNC_HOURS` hours (24 by default). If the internet is unavailable, the existing local calendar and cached weather remain available. Keep the calendar URL private if it contains an access token; `.env` is local configuration and should not be committed.

From this directory:

- Create a virtual environment and install this package locally.
- Copy `.env.example` to `.env` and adjust paths.
- Put your exported calendar at `data/calendar.ics`.
- Run `python -m jarvis --text "what time is it"` to test without audio.
- Run `python -m jarvis` for the microphone loop.

The audio format is 16 kHz, mono, 16-bit PCM. A USB microphone and a small powered speaker are recommended.

## Voice examples

- “Jarvis, what is on my calendar?”
- “Jarvis, set a timer for 10 minutes.”
- “Jarvis, remind me to do homework in 30 minutes.”
- “Jarvis, explain photosynthesis.”

## Start on boot

Copy `deploy/jarvis.service` to `/etc/systemd/system/`, change its `User` and `WorkingDirectory`, then enable it. The service needs outbound networking for the configured daily calendar/weather sync; AI inference still uses the local Ollama service and no AI endpoint is configured.

## Connect the second Raspberry Pi

Use a static direct-link address, for example Pi #1 `192.168.50.1/24` and Pi #2 `192.168.50.2/24`. On Pi #2, copy `magicmirror/MMM-Jarvis-Display` into MagicMirror's `modules/` directory and install its one Node dependency from that directory:

Configure the network on both Pis with `deploy/configure-network.sh`:

The script expects NetworkManager/`nmcli` (the default on current Raspberry Pi OS Bookworm). If `nmcli` is missing, install and enable NetworkManager before running it.

	sudo ./deploy/configure-network.sh --role brain --ip 192.168.50.1 --ssid "Your Wi-Fi"
	sudo ./deploy/configure-network.sh --role face --ip 192.168.50.2 --ssid "Your Wi-Fi"

The script prompts for the Wi-Fi password without putting it in the command line. Use `--no-wifi` on the Face Pi if only the Brain Pi needs internet. Ethernet is deliberately configured without a default route, so the Brain Pi's Wi-Fi remains the route used for BOM and calendar synchronization.

	npm install --omit=dev

Add this object to MagicMirror's `config/config.js`:

	{
		module: "MMM-Jarvis-Display",
		position: "top_left",
		config: {
			brainHost: "192.168.50.1",
			brainPort: 8765,
			reconnectMs: 2000,
			staleAfterMs: 30000
		}
	},

Start Jarvis on Pi #1 after assigning the static address. The MagicMirror module reconnects automatically if Jarvis restarts. To test the wire and UI without a microphone, run `python -m jarvis --mock-mirror` on Pi #1; the mirror should show Listening, Thinking, and Speaking in sequence.

## Resource choices

The assistant intentionally avoids a Python ML stack: audio/model inference runs in native local binaries, while orchestration is standard-library Python. Keep the LLM context and output short, use a fan, and avoid running desktop workloads alongside inference.
