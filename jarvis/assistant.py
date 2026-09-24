from datetime import datetime, timezone
from pathlib import Path
from .calendar import read_events
from .commands import parse_schedule, simple_reply
from .config import Config
from .llm import LocalModel
from .storage import Store


class Assistant:
    def __init__(self, config: Config):
        self.config = config
        self.store = Store(config.data_dir / "jarvis.db")
        self.model = LocalModel(config.llm_bin, config.llm_model, config.max_tokens, config.ollama_bin, config.ollama_model)

    def respond(self, text: str) -> str:
        text = text.strip()
        if not text:
            return "I didn't hear a question."
        lowered = text.lower()
        now = datetime.now(timezone.utc)
        if any(word in lowered for word in ("remind", "timer", "alarm")):
            scheduled = parse_schedule(text, now)
            if scheduled:
                title, due = scheduled
                kind = "timer" if "timer" in lowered else "alarm" if "alarm" in lowered else "reminder"
                self.store.add(kind, title, due)
                return f"Okay, I set a {kind} for {due.astimezone().strftime('%I:%M %p')}."
            return "Tell me how long, for example: set a timer for 10 minutes."
        if "calendar" in lowered or "schedule" in lowered or "appointments" in lowered:
            events = read_events(self.config.calendar_file, now)
            if not events:
                return "Your local calendar has no upcoming events."
            return "Upcoming: " + "; ".join(f"{e.title} at {e.starts.astimezone().strftime('%a %I:%M %p')}" for e in events[:5])
        reply = simple_reply(text)
        return reply or self.model.answer(text) or "I can manage your local calendar, reminders, timers, and alarms, or answer questions when a local language model is installed."
