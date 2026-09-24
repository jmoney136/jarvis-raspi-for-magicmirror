Module.register("MMM-Jarvis-Display", {
    defaults: {
        brainHost: "192.168.50.1",
        brainPort: 8765,
        reconnectMs: 2000,
        staleAfterMs: 30000
    },

    start() {
        this.state = {
            status: "offline",
            text: "Waiting for Jarvis",
            timestamp: 0,
            weatherText: "Weather unavailable",
            calendarText: "Calendar unavailable"
        };
        this.sendSocketNotification("JARVIS_CONFIG", {
            brainHost: this.config.brainHost,
            brainPort: this.config.brainPort,
            reconnectMs: this.config.reconnectMs
        });
        this.scheduleUpdate();
    },

    getStyles() {
        return ["MMM-Jarvis-Display.css"];
    },

    getDom() {
        const wrapper = document.createElement("div");
        wrapper.className = "jarvis-display";
        wrapper.setAttribute("role", "status");
        wrapper.setAttribute("aria-live", "polite");

        const indicator = document.createElement("span");
        indicator.className = `jarvis-indicator jarvis-${this.state.status}`;
        indicator.setAttribute("aria-hidden", "true");

        const status = document.createElement("span");
        status.className = "jarvis-status bright medium light";
        status.textContent = this.state.status.toUpperCase();

        const text = document.createElement("div");
        text.className = "jarvis-text normal medium light";
        text.textContent = this.state.text;

        const weather = document.createElement("div");
        weather.className = "jarvis-info small light";
        weather.textContent = `Weather: ${this.state.weatherText}`;

        const calendar = document.createElement("div");
        calendar.className = "jarvis-info small light";
        calendar.textContent = `Calendar: ${this.state.calendarText}`;

        wrapper.append(indicator, status, text, weather, calendar);
        return wrapper;
    },

    socketNotificationReceived(notification, payload) {
        if (notification !== "JARVIS_STATE" || !payload) {
            return;
        }
        const status = ["idle", "listening", "thinking", "speaking", "weather", "calendar", "error", "offline"].includes(payload.status)
            ? payload.status
            : "idle";
        if (payload.status === "weather") {
            this.state.weatherText = typeof payload.text === "string" ? payload.text : this.state.weatherText;
        } else if (payload.status === "calendar") {
            this.state.calendarText = typeof payload.text === "string" ? payload.text : this.state.calendarText;
        }
        this.state = {
            ...this.state,
            status,
            text: typeof payload.text === "string" ? payload.text : "",
            timestamp: Date.parse(payload.timestamp || "") || Date.now()
        };
        this.updateDom(0);
    },

    scheduleUpdate() {
        setInterval(() => {
            if (this.state.timestamp && Date.now() - this.state.timestamp > this.config.staleAfterMs) {
                this.state = { ...this.state, status: "offline", text: "Jarvis connection lost", timestamp: 0 };
                this.updateDom(0);
            }
        }, 5000);
    }
});
