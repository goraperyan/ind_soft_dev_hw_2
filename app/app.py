import json
import os
import socket
import time
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, Response, jsonify, request

app = Flask(__name__)

POD_NAME = socket.gethostname()
CONFIG_PATH = Path("/app/config/app-config.json")
LOG_DIR = Path("/app/logs")
LOG_FILE = LOG_DIR / "app.log"


def load_config():
    config = {
        "welcome_message": "Welcome to the custom app",
        "log_level": "INFO",
    }

    if CONFIG_PATH.exists():
        try:
            with CONFIG_PATH.open("r", encoding="utf-8") as f:
                file_config = json.load(f)
                config.update(file_config)
        except Exception as e:
            print(f"APP_CONFIG_ERROR {e}", flush=True)

    return config


def append_log(message: str):
    config = load_config()
    log_level = config.get("log_level", "INFO").upper()

    LOG_DIR.mkdir(parents=True, exist_ok=True)

    line = f"{datetime.now(timezone.utc).isoformat()} [{POD_NAME}] {message}"

    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(line + "\n")

    print(f"APP_LOGFILE level={log_level} {line}", flush=True)


@app.after_request
def add_headers(response):
    response.headers["X-Pod-Name"] = POD_NAME
    return response


@app.route("/", methods=["GET"])
def root():
    config = load_config()
    return Response(
        config.get("welcome_message", "Welcome to the custom app"),
        mimetype="text/plain",
    )


@app.route("/status", methods=["GET"])
def status():
    return jsonify({"status": "ok"})


@app.route("/log", methods=["POST"])
def write_log():
    data = request.get_json(silent=True)

    if not data or "message" not in data:
        return jsonify({"error": "JSON body must contain 'message'"}), 400

    delay_header = request.headers.get("X-Delay-Seconds")
    if delay_header:
        try:
            delay = float(delay_header)
            if delay > 0:
                time.sleep(delay)
        except ValueError:
            pass

    append_log(str(data["message"]))
    return jsonify({"status": "logged"}), 201


@app.route("/logs", methods=["GET"])
def get_logs():
    if not LOG_FILE.exists():
        return Response("", mimetype="text/plain")

    with LOG_FILE.open("r", encoding="utf-8") as f:
        content = f.read()

    return Response(content, mimetype="text/plain")


if __name__ == "__main__":
    port = int(os.getenv("APP_PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
