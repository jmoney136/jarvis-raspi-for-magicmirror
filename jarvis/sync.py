"""Occasional non-AI network synchronization for calendar and weather."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import URLError
from urllib.request import Request, urlopen


class DailySync:
    def __init__(self, calendar_url: str, calendar_file: Path, bom_geohash: str, bom_api_base: str, cache_file: Path, timeout: int = 15):
        self.calendar_url = calendar_url
        self.calendar_file = calendar_file
        self.bom_geohash = bom_geohash
        self.bom_api_base = bom_api_base.rstrip("/")
        self.cache_file = cache_file
        self.timeout = timeout

    def _get(self, url: str) -> bytes:
        request = Request(url, headers={"User-Agent": "Jarvis-Pi/1.0", "Accept": "application/json,text/calendar"})
        with urlopen(request, timeout=self.timeout) as response:
            return response.read()

    def refresh_calendar(self) -> bool:
        if not self.calendar_url:
            return False
        data = self._get(self.calendar_url)
        if b"BEGIN:VCALENDAR" not in data:
            raise ValueError("calendar response is not an ICS calendar")
        self.calendar_file.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.calendar_file.with_suffix(".tmp")
        temporary.write_bytes(data)
        temporary.replace(self.calendar_file)
        return True

    def refresh_weather(self) -> dict:
        if not self.bom_geohash:
            return {}
        observations = json.loads(self._get(f"{self.bom_api_base}/locations/{self.bom_geohash}/observations").decode("utf-8")).get("data", {})
        daily = json.loads(self._get(f"{self.bom_api_base}/locations/{self.bom_geohash}/forecasts/daily").decode("utf-8")).get("data", [])
        forecast = next((day for day in daily if day.get("temp_min") is not None), daily[0] if daily else {})
        weather = {
            "location": "Brogo",
            "temperature": observations.get("temp"),
            "feels_like": observations.get("temp_feels_like"),
            "wind_speed": (observations.get("wind") or {}).get("speed_kilometre"),
            "wind_direction": (observations.get("wind") or {}).get("direction"),
            "high": forecast.get("temp_max"),
            "low": forecast.get("temp_min"),
            "description": forecast.get("short_text") or forecast.get("icon_descriptor", ""),
            "rain_chance": (forecast.get("rain") or {}).get("chance"),
            "uv": (forecast.get("uv") or {}).get("max_index"),
            "updated": datetime.now(timezone.utc).isoformat(),
        }
        self.cache_file.parent.mkdir(parents=True, exist_ok=True)
        self.cache_file.write_text(json.dumps(weather), encoding="utf-8")
        return weather

    def refresh(self) -> dict:
        result = {"calendar": False, "weather": {}, "error": ""}
        try:
            result["calendar"] = self.refresh_calendar()
            result["weather"] = self.refresh_weather()
        except (OSError, URLError, ValueError, json.JSONDecodeError) as error:
            result["error"] = str(error)
        return result

    def cached_weather(self) -> dict:
        try:
            return json.loads(self.cache_file.read_text(encoding="utf-8"))
        except (FileNotFoundError, OSError, json.JSONDecodeError):
            return {}
