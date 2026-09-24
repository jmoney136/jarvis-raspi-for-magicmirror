import argparse
import asyncio
from datetime import datetime, timezone
from .assistant import Assistant
from .config import Config
from .mirror import run_mirror_server, send_to_mirror
from .calendar import read_events
from .sync import DailySync
from .voice import Voice


async def run_mock_mirror() -> None:
    await send_to_mirror("listening", "Listening...")
    await asyncio.sleep(1)
    await send_to_mirror("thinking", "Thinking...")
    await asyncio.sleep(1)
    await send_to_mirror("speaking", "Hello from Jarvis on the Brain Pi.")
    await asyncio.sleep(2)
    await send_to_mirror("idle", "")


async def run_voice_loop(assistant: Assistant, voice: Voice) -> None:
    while True:
        for reminder in assistant.store.due(datetime.now(timezone.utc)):
            message = f"Reminder: {reminder['title']}"
            await send_to_mirror("speaking", message)
            await asyncio.to_thread(voice.say, message)
            assistant.store.complete(reminder["id"])
        await send_to_mirror("listening", "Listening...")
        heard = await asyncio.to_thread(voice.listen)
        if assistant.config.wake_word not in heard.lower():
            continue
        request = heard.lower().split(assistant.config.wake_word, 1)[1].strip(" ,")
        if not request:
            await send_to_mirror("speaking", "Yes?")
            await asyncio.to_thread(voice.say, "Yes?")
            await send_to_mirror("listening", "Listening...")
            request = await asyncio.to_thread(voice.listen)
        await send_to_mirror("thinking", request)
        response = await asyncio.to_thread(assistant.respond, request)
        await send_to_mirror("speaking", response)
        await asyncio.to_thread(voice.say, response)
        await send_to_mirror("idle", "")


def _weather_text(weather: dict) -> str:
    if not weather or weather.get("temperature") is None:
        return "Weather unavailable"
    return f"Brogo {weather['temperature']}°C · {weather.get('description', '')} · high {weather.get('high', '?')}°C · low {weather.get('low', '?')}°C · rain {weather.get('rain_chance', '?')}%"


async def run_daily_sync(config: Config) -> None:
    sync = DailySync(
        config.calendar_url,
        config.calendar_file,
        config.bom_geohash,
        config.bom_api_base,
        config.data_dir / "weather.json",
    )
    while True:
        result = await asyncio.to_thread(sync.refresh)
        if result["weather"]:
            await send_to_mirror("weather", _weather_text(result["weather"]))
        events = read_events(config.calendar_file)
        calendar_text = " · ".join(event.title for event in events[:3]) or "No upcoming events"
        await send_to_mirror("calendar", calendar_text)
        if result["error"]:
            await send_to_mirror("error", "Calendar/weather sync unavailable; using cached data")
        await asyncio.sleep(max(1, config.sync_hours) * 3600)


async def run(config: Config, text: str | None, mock_mirror: bool) -> None:
    assistant = Assistant(config)
    if text:
        print(assistant.respond(text))
        return
    await run_mirror_server(config.mirror_host, config.mirror_port)
    sync_task = asyncio.create_task(run_daily_sync(config))
    if mock_mirror:
        await run_mock_mirror()
        sync_task.cancel()
        return
    voice = Voice(config.stt_bin, config.stt_model, config.tts_bin, config.tts_model, config.record_seconds)
    print(f"Jarvis offline mode. Say '{config.wake_word}' or press Ctrl-C to stop.")
    try:
        await run_voice_loop(assistant, voice)
    except KeyboardInterrupt:
        await send_to_mirror("idle", "Goodbye.")
        print("\nGoodbye.")
    except (OSError, RuntimeError) as error:
        await send_to_mirror("error", f"Audio error: {error}")
        print(f"Audio error: {error}")
    finally:
        sync_task.cancel()


def main() -> None:
    parser = argparse.ArgumentParser(description="Offline Raspberry Pi voice assistant")
    parser.add_argument("--text", help="run one text command without a microphone")
    parser.add_argument("--mock-mirror", action="store_true", help="send a short demo state sequence")
    args = parser.parse_args()
    config = Config.from_env()
    asyncio.run(run(config, args.text, args.mock_mirror))


if __name__ == "__main__":
    main()
