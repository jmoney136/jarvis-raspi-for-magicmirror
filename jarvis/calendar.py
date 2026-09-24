from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import re


@dataclass(frozen=True)
class Event:
    title: str
    starts: datetime
    location: str = ""


def _unescape(value: str) -> str:
    return value.replace("\\n", " ").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\")


def _date(value: str) -> datetime:
    value = value.rstrip("Z")
    if len(value) == 8:
        return datetime.strptime(value, "%Y%m%d").replace(tzinfo=timezone.utc)
    return datetime.strptime(value[:15], "%Y%m%dT%H%M%S").replace(tzinfo=timezone.utc)


def read_events(path: Path, now: datetime | None = None) -> list[Event]:
    if not path.exists():
        return []
    lines = path.read_text(encoding="utf-8").replace("\r\n", "\n").splitlines()
    events: list[Event] = []
    current: dict[str, str] = {}
    in_event = False
    for line in lines + ["END:VEVENT"]:
        if line == "BEGIN:VEVENT":
            current = {}
            in_event = True
        elif line == "END:VEVENT" and current:
            if "DTSTART" in current and "SUMMARY" in current:
                events.append(Event(_unescape(current["SUMMARY"]), _date(current["DTSTART"]), _unescape(current.get("LOCATION", ""))))
            current = {}
            in_event = False
        elif in_event and ":" in line:
            key, value = line.split(":", 1)
            current[key.split(";", 1)[0]] = value
    cutoff = now or datetime.now(timezone.utc)
    return sorted((event for event in events if event.starts >= cutoff), key=lambda event: event.starts)
