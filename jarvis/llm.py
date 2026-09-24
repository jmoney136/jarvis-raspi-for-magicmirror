from pathlib import Path
import shutil
import subprocess


class LocalModel:
    def __init__(self, binary: Path, model: Path, max_tokens: int = 160, ollama_bin: str = "ollama", ollama_model: str = "qwen2.5:0.5b"):
        self.binary, self.model, self.max_tokens = binary, model, max_tokens
        self.ollama_bin, self.ollama_model = ollama_bin, ollama_model

    def answer(self, question: str) -> str | None:
        if shutil.which(self.ollama_bin):
            prompt = f"You are Jarvis, a concise offline assistant. Answer safely and clearly.\nUser: {question}\nAssistant:"
            try:
                result = subprocess.run([self.ollama_bin, "run", self.ollama_model, prompt], capture_output=True, text=True, timeout=120, check=True)
            except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
                result = None
            if result is not None:
                return result.stdout.strip() or None
        if not self.binary.exists() or not self.model.exists():
            return None
        prompt = f"You are Jarvis, a concise offline assistant. Answer safely and clearly.\nUser: {question}\nAssistant:"
        result = subprocess.run([str(self.binary), "-m", str(self.model), "-p", prompt, "-n", str(self.max_tokens), "--no-display-prompt", "--no-context-shift"], capture_output=True, text=True, check=True)
        return result.stdout.strip() or None
