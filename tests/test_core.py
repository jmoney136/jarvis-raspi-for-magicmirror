from datetime import datetime, timezone
from pathlib import Path
from jarvis.assistant import Assistant
from jarvis.config import Config
from jarvis.commands import parse_schedule


def config(tmp_path: Path) -> Config:
    return Config(tmp_path, tmp_path / "calendar.ics", Path("missing"), Path("missing"), Path("missing"), Path("missing"), Path("missing"), Path("missing"))


def test_parse_schedule():
    now = datetime(2026, 1, 1, tzinfo=timezone.utc)
    title, due = parse_schedule("homework in 10 minutes", now)
    assert title == "homework"
    assert (due - now).total_seconds() == 600


def test_time_reply(tmp_path):
    assert "It is" in Assistant(config(tmp_path)).respond("what time is it")


def test_timer_is_persisted(tmp_path):
    assistant = Assistant(config(tmp_path))
    assert "set a timer" in assistant.respond("set a timer in 2 minutes").lower()
    assert len(assistant.store.upcoming(datetime.now(timezone.utc))) == 1
