from datetime import datetime
from pathlib import Path
import sqlite3


class Store:
    def __init__(self, path: Path):
        path.parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(path)
        self.db.row_factory = sqlite3.Row
        self.db.execute("""CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY, kind TEXT NOT NULL, title TEXT NOT NULL,
            due_at TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0)""")
        self.db.commit()

    def add(self, kind: str, title: str, due_at: datetime) -> int:
        cur = self.db.execute("INSERT INTO reminders(kind,title,due_at) VALUES(?,?,?)", (kind, title, due_at.isoformat()))
        self.db.commit()
        return int(cur.lastrowid)

    def upcoming(self, now: datetime, limit: int = 10):
        return self.db.execute("SELECT * FROM reminders WHERE done=0 AND due_at>=? ORDER BY due_at LIMIT ?", (now.isoformat(), limit)).fetchall()

    def due(self, now: datetime):
        return self.db.execute("SELECT * FROM reminders WHERE done=0 AND due_at<=? ORDER BY due_at", (now.isoformat(),)).fetchall()

    def complete(self, reminder_id: int) -> None:
        self.db.execute("UPDATE reminders SET done=1 WHERE id=?", (reminder_id,))
        self.db.commit()
