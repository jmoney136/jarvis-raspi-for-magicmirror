from datetime import datetime, timedelta, timezone
import re


_DURATION = re.compile(r"(?:in )?(\d+)\s*(second|seconds|minute|minutes|hour|hours)", re.I)


def parse_schedule(text: str, now: datetime | None = None) -> tuple[str, datetime] | None:
    match = _DURATION.search(text)
    if not match:
        return None
    amount, unit = int(match.group(1)), match.group(2).lower()
    seconds = amount * (3600 if unit.startswith("hour") else 60 if unit.startswith("minute") else 1)
    return text[:match.start()].strip(" ,") or "Reminder", (now or datetime.now(timezone.utc)) + timedelta(seconds=seconds)


def simple_reply(text: str) -> str | None:
    lowered = text.lower().strip()
    if lowered in {"what time is it", "what's the time", "tell me the time"}:
        return datetime.now().astimezone().strftime("It is %I:%M %p.")
    if lowered in {"what day is it", "what is today's date", "what's today's date"}:
        return datetime.now().astimezone().strftime("Today is %A, %B %d, %Y.")
    return None
