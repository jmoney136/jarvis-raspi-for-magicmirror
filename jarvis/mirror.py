"""Low-latency WebSocket bridge from the Jarvis brain to MagicMirror."""

from __future__ import annotations

import asyncio
import json
import logging
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import Any

import websockets
from websockets.asyncio.server import Server, ServerConnection, serve

LOGGER = logging.getLogger(__name__)


@dataclass(frozen=True)
class MirrorState:
    status: str
    text: str
    timestamp: str


class MirrorBridge:
    def __init__(self, host: str = "0.0.0.0", port: int = 8765):
        self.host = host
        self.port = port
        self._clients: set[ServerConnection] = set()
        self._server: Server | None = None
        self._states: dict[str, MirrorState] = {"idle": MirrorState("idle", "", self._now())}
        self._lock = asyncio.Lock()

    @staticmethod
    def _now() -> str:
        return datetime.now(timezone.utc).isoformat()

    async def _handler(self, websocket: ServerConnection) -> None:
        self._clients.add(websocket)
        LOGGER.info("Mirror connected from %s", websocket.remote_address)
        try:
            for state in self._states.values():
                await websocket.send(json.dumps(asdict(state), separators=(",", ":")))
            await websocket.wait_closed()
        finally:
            self._clients.discard(websocket)
            LOGGER.info("Mirror disconnected")

    async def start(self) -> None:
        self._server = await serve(self._handler, self.host, self.port, max_size=4096, compression=None)
        LOGGER.info("Mirror WebSocket listening on %s:%d", self.host, self.port)

    async def stop(self) -> None:
        if self._server is not None:
            self._server.close()
            await self._server.wait_closed()
            self._server = None
        self._clients.clear()

    async def send_to_mirror(self, state: str, message: str) -> None:
        """Broadcast a compact state update to all connected mirrors."""
        payload: dict[str, Any] = {
            "status": state,
            "text": message,
            "timestamp": self._now(),
        }
        encoded = json.dumps(payload, separators=(",", ":"))
        async with self._lock:
            self._states[state] = MirrorState(**payload)
            if not self._clients:
                return
            results = await asyncio.gather(
                *(client.send(encoded) for client in tuple(self._clients)),
                return_exceptions=True,
            )
            for client, result in zip(tuple(self._clients), results):
                if isinstance(result, Exception):
                    self._clients.discard(client)


async def send_to_mirror(state: str, message: str) -> None:
    """Send through the process-wide bridge configured by ``run_mirror_server``."""
    if _active_bridge is not None:
        await _active_bridge.send_to_mirror(state, message)


_active_bridge: MirrorBridge | None = None


async def run_mirror_server(host: str = "0.0.0.0", port: int = 8765) -> MirrorBridge:
    global _active_bridge
    bridge = MirrorBridge(host, port)
    await bridge.start()
    _active_bridge = bridge
    return bridge
