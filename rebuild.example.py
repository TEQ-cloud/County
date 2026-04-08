#!/usr/bin/env python3
"""
County rebuild & deploy.
1. Clean builds County via xcodebuild
2. Deploys to /Applications
3. Sends email report via SMTP

Usage:
    python3 rebuild.py

Create a .env file from .env.example and fill in your SMTP settings.
"""

import shutil
import smtplib
import subprocess
import sys
from datetime import datetime
from email.mime.text import MIMEText
from pathlib import Path

# ── Config ──────────────────────────────────────────────────────────
PROJECT = Path.home() / "Documents/[01] TEQcloud/County/County.xcodeproj"
APP_NAME = "County"
DEST = Path("/Applications") / f"{APP_NAME}.app"
BUILD_DIR = Path("/tmp/CountyBuild")


def load_env():
    """Load .env file into a dict."""
    env_path = Path(__file__).parent / ".env"
    if not env_path.exists():
        print(f"Error: {env_path} not found. Copy .env.example to .env and fill in your settings.")
        sys.exit(1)
    env = {}
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            env[key.strip()] = value.strip()
    return env


ENV = load_env()
SMTP_HOST = ENV["SMTP_HOST"]
SMTP_PORT = int(ENV["SMTP_PORT"])
SMTP_USER = ENV["SMTP_USER"]
SMTP_PASS = ENV["SMTP_PASS"]
FROM_USER = ENV["FROM_USER"]
MAIL_TO   = ENV["MAIL_TO"]
# ────────────────────────────────────────────────────────────────────


def notify(title, message):
    """Send a macOS notification."""
    subprocess.run([
        "osascript", "-e",
        f'display notification "{message}" with title "{title}"',
    ])


def send_mail(subject, body):
    """Send an email via SMTP."""
    msg = MIMEText(body, "plain", "utf-8")
    msg["Subject"] = subject
    msg["From"] = FROM_USER
    msg["To"] = MAIL_TO

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.starttls()
        server.login(SMTP_USER, SMTP_PASS)
        server.send_message(msg)


def build():
    """Clean build via xcodebuild. Returns (success, output)."""
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)

    result = subprocess.run([
        "xcodebuild", "clean", "build",
        "-project", str(PROJECT),
        "-scheme", APP_NAME,
        "-configuration", "Debug",
        "-derivedDataPath", str(BUILD_DIR),
        "CODE_SIGN_IDENTITY=-",
        "CODE_SIGNING_ALLOWED=YES",
        "CODE_SIGNING_REQUIRED=NO",
    ], capture_output=True, text=True)

    return result.returncode == 0, result.stdout + result.stderr


def deploy():
    """Copy build to /Applications, clear attrs, sign."""
    built_app = BUILD_DIR / "Build/Products/Debug" / f"{APP_NAME}.app"

    if DEST.exists():
        shutil.rmtree(DEST)

    shutil.copytree(built_app, DEST)
    subprocess.run(["xattr", "-cr", str(DEST)])
    subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(DEST)])

    # Restart widget system so it picks up the new build
    subprocess.run(["killall", "NotificationCenter"], capture_output=True)

    # Cleanup
    shutil.rmtree(BUILD_DIR, ignore_errors=True)


def main():
    now = datetime.now()
    print(f"County rebuild started: {now:%Y-%m-%d %H:%M}")

    success, output = build()

    if not success:
        report = (
            f"County Rebuild FAILED - {now:%Y-%m-%d %H:%M}\n"
            f"{'=' * 50}\n\n"
            f"Build output (last 50 lines):\n"
            f"{'-' * 50}\n"
            f"{chr(10).join(output.splitlines()[-50:])}"
        )
        print(report)
        try:
            send_mail(f"County Rebuild FAILED - {now:%Y-%m-%d}", report)
            notify("County Rebuild", "Build mislukt — check mail.")
        except Exception as e:
            print(f"Mail failed: {e}", file=sys.stderr)
            notify("County Rebuild", f"Build mislukt, mail ook: {e}")
        sys.exit(1)

    deploy()

    report = (
        f"County Rebuild OK - {now:%Y-%m-%d %H:%M}\n"
        f"{'=' * 50}\n\n"
        f"Deployed to: {DEST}\n"
        f"Signed: ad-hoc\n"
    )
    print(report)

    try:
        send_mail(f"County Rebuild OK - {now:%Y-%m-%d}", report)
        print("Mail sent!")
        notify("County Rebuild", "Gelukt! App opnieuw gebuild en gedeployed.")
    except Exception as e:
        print(f"Mail failed: {e}", file=sys.stderr)
        notify("County Rebuild", f"Rebuild gelukt, mail mislukt: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
