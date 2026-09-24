from pathlib import Path
import subprocess
import tempfile


class Voice:
    def __init__(self, stt_bin: Path, stt_model: Path, tts_bin: Path, tts_model: Path, seconds: int = 8):
        self.stt_bin, self.stt_model = stt_bin, stt_model
        self.tts_bin, self.tts_model, self.seconds = tts_bin, tts_model, seconds

    def listen(self) -> str:
        with tempfile.TemporaryDirectory() as directory:
            wav = Path(directory) / "input.wav"
            subprocess.run(["arecord", "-q", "-d", str(self.seconds), "-f", "S16_LE", "-r", "16000", "-c", "1", str(wav)], check=True)
            result = subprocess.run([str(self.stt_bin), "-m", str(self.stt_model), "-f", str(wav), "--no-timestamps", "-nt"], capture_output=True, text=True, check=True)
            return result.stdout.strip()

    def say(self, text: str) -> None:
        if not self.tts_bin.exists() or not self.tts_model.exists():
            print(f"Jarvis: {text}")
            return
        with tempfile.TemporaryDirectory() as directory:
            wav = Path(directory) / "reply.wav"
            subprocess.run([str(self.tts_bin), "--model", str(self.tts_model), "--output_file", str(wav)], input=text, text=True, check=True)
            subprocess.run(["aplay", "-q", str(wav)], check=True)
