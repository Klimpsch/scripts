#!/usr/bin/env python3
"""
auto_email.py — watch a directory and email any file placed into it.

Drop a file into WATCH_DIR and it gets emailed as an attachment, then
moved to a 'sent' subfolder so it isn't sent twice.

Config via environment variables (see below) or edit the CONFIG block.
Works with plain SMTP+STARTTLS (e.g. Gmail with an App Password).

~/.config/systemd/user/auto-email.service:
[Unit]
Description=Auto-email directory watcher

[Service]
ExecStart=/usr/bin/python3 %h/auto_email.py
Environment=WATCH_DIR=%h/outbox
Environment=SMTP_USER=you@gmail.com
Environment=SMTP_PASS=your-app-password
Environment=MAIL_TO=recipient@example.com
Restart=always

[Install]
WantedBy=default.target
"""

import os
import ssl
import time
import smtplib
import mimetypes
from email.message import EmailMessage
from pathlib import Path

WATCH_DIR   = os.environ.get("WATCH_DIR",  os.path.expanduser("~/outbox"))
SMTP_HOST   = os.environ.get("SMTP_HOST",  "smtp.gmail.com")
SMTP_PORT   = int(os.environ.get("SMTP_PORT", "587"))
SMTP_USER   = os.environ.get("SMTP_USER",  "you@gmail.com")
SMTP_PASS   = os.environ.get("SMTP_PASS",  "")          # use an App Password
MAIL_FROM   = os.environ.get("MAIL_FROM",  SMTP_USER)
MAIL_TO     = os.environ.get("MAIL_TO",    "recipient@example.com")
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "5"))

SENT_DIR = Path(WATCH_DIR) / "sent"


def file_is_stable(path: Path, checks: int = 2, wait: float = 1.0) -> bool:
    """Return True once the file size stops changing (finished copying)."""
    last = -1
    for _ in range(checks):
        try:
            size = path.stat().st_size
        except FileNotFoundError:
            return False
        if size != last:
            last = size
            time.sleep(wait)
        else:
            return True
    return path.stat().st_size == last


def send_file(path: Path) -> None:
    msg = EmailMessage()
    msg["From"] = MAIL_FROM
    msg["To"] = MAIL_TO
    msg["Subject"] = f"Auto-email: {path.name}"
    msg.set_content(f"Attached file: {path.name}\nSize: {path.stat().st_size} bytes")

    ctype, encoding = mimetypes.guess_type(path)
    if ctype is None or encoding is not None:
        ctype = "application/octet-stream"
    maintype, subtype = ctype.split("/", 1)

    with open(path, "rb") as f:
        msg.add_attachment(f.read(), maintype=maintype,
                           subtype=subtype, filename=path.name)

    context = ssl.create_default_context()
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.starttls(context=context)
        server.login(SMTP_USER, SMTP_PASS)
        server.send_message(msg)
    print(f"[sent] {path.name} -> {MAIL_TO}")


def main() -> None:
    watch = Path(WATCH_DIR)
    watch.mkdir(parents=True, exist_ok=True)
    SENT_DIR.mkdir(exist_ok=True)
    print(f"Watching {watch} every {POLL_SECONDS}s. Ctrl-C to stop.")

    while True:
        for entry in watch.iterdir():
            if entry.is_dir() or entry.name.startswith("."):
                continue
            if not file_is_stable(entry):
                continue
            try:
                send_file(entry)
                entry.rename(SENT_DIR / entry.name)
            except Exception as e:
                print(f"[error] {entry.name}: {e}")
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
