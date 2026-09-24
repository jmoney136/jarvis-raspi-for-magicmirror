from dataclasses import dataclass
from pathlib import Path
import os


@dataclass(frozen=True)
class Config:
    data_dir: Path
    calendar_file: Path
    stt_bin: Path
    stt_model: Path
    tts_bin: Path
    tts_model: Path
    llm_bin: Path
    llm_model: Path
    ollama_bin: str = "ollama"
    ollama_model: str = "qwen2.5:0.5b"
    mirror_host: str = "0.0.0.0"
    mirror_port: int = 8765
    calendar_url: str = ""
    bom_geohash: str = "r3d80t"
    bom_api_base: str = "https://api.weather.bom.gov.au/v1"
    sync_hours: int = 24
    wake_word: str = "jarvis"
    record_seconds: int = 8
    max_tokens: int = 160

    @classmethod
    def from_env(cls, root: Path | None = None) -> "Config":
        root = root or Path.cwd()
        env_file = root / ".env"
        if env_file.exists():
            for line in env_file.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    name, value = line.split("=", 1)
                    os.environ.setdefault(name.strip(), value.strip().strip('"').strip("'"))
        data_dir = Path(os.getenv("JARVIS_DATA_DIR", root / "data"))
        def path(name: str, default: str) -> Path:
            value = Path(os.getenv(name, default))
            return value if value.is_absolute() else root / value
        return cls(
            data_dir=data_dir if data_dir.is_absolute() else root / data_dir,
            calendar_file=path("JARVIS_CALENDAR_FILE", "data/calendar.ics"),
            stt_bin=path("JARVIS_STT_BIN", "/opt/whisper.cpp/build/bin/whisper-cli"),
            stt_model=path("JARVIS_STT_MODEL", "models/ggml-tiny.en.bin"),
            tts_bin=path("JARVIS_TTS_BIN", "/usr/local/bin/piper"),
            tts_model=path("JARVIS_TTS_MODEL", "models/en_US-lessac-medium.onnx"),
            llm_bin=path("JARVIS_LLM_BIN", "/opt/llama.cpp/build/bin/llama-cli"),
            llm_model=path("JARVIS_LLM_MODEL", "models/qwen2.5-0.5b-instruct-q4_k_m.gguf"),
            ollama_bin=os.getenv("JARVIS_OLLAMA_BIN", "ollama"),
            ollama_model=os.getenv("JARVIS_OLLAMA_MODEL", "qwen2.5:0.5b"),
            mirror_host=os.getenv("JARVIS_MIRROR_HOST", "0.0.0.0"),
            mirror_port=int(os.getenv("JARVIS_MIRROR_PORT", "8765")),
            calendar_url=os.getenv("JARVIS_CALENDAR_URL", ""),
            bom_geohash=os.getenv("JARVIS_BOM_GEOHASH", "r3d80t"),
            bom_api_base=os.getenv("JARVIS_BOM_API_BASE", "https://api.weather.bom.gov.au/v1").rstrip("/"),
            sync_hours=int(os.getenv("JARVIS_SYNC_HOURS", "24")),
            wake_word=os.getenv("JARVIS_WAKE_WORD", "jarvis").lower(),
            record_seconds=int(os.getenv("JARVIS_RECORD_SECONDS", "8")),
            max_tokens=int(os.getenv("JARVIS_MAX_TOKENS", "160")),
        )
