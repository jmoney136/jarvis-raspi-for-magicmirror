const NodeHelper = require("node_helper");
const WebSocket = require("ws");

module.exports = NodeHelper.create({
    start() {
        this.config = { reconnectMs: 2000 };
        this.socket = null;
        this.reconnectTimer = null;
    },

    socketNotificationReceived(notification, payload) {
        if (notification === "JARVIS_CONFIG") {
            this.config = { ...this.config, ...payload };
            this.connect();
        }
    },

    connect() {
        if (this.socket && [WebSocket.OPEN, WebSocket.CONNECTING].includes(this.socket.readyState)) {
            return;
        }
        const url = this.config.url || `ws://${this.config.brainHost}:${this.config.brainPort}`;
        this.socket = new WebSocket(url);
        this.socket.on("open", () => this.sendSocketNotification("JARVIS_STATE", {
            status: "idle",
            text: "Mirror connected",
            timestamp: new Date().toISOString()
        }));
        this.socket.on("message", (data) => {
            try {
                const state = JSON.parse(data.toString());
                this.sendSocketNotification("JARVIS_STATE", state);
            } catch (error) {
                console.error("MMM-Jarvis-Display invalid payload", error.message);
            }
        });
        this.socket.on("close", () => this.scheduleReconnect());
        this.socket.on("error", () => this.socket.close());
    },

    scheduleReconnect() {
        if (this.reconnectTimer) {
            return;
        }
        this.reconnectTimer = setTimeout(() => {
            this.reconnectTimer = null;
            this.connect();
        }, this.config.reconnectMs);
    },

    stop() {
        clearTimeout(this.reconnectTimer);
        if (this.socket) {
            this.socket.close();
        }
    }
});
