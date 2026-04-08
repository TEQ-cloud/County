# County

A macOS countdown app with widget support. Create countdowns with a name and date, see how many days are left at a glance.

## Features

- Create and manage countdowns (name + date)
- Days-left counter, split into upcoming and past sections
- macOS widget (small, medium, large) showing your upcoming countdowns
- Right-click to delete individual countdowns

## Requirements

- macOS 26 Tahoe (tested on 26.4)
- Xcode 15+
- Apple Developer account (free/personal team works)
- Python 3 (tested on 3.13)

## Setup

1. Open `County.xcodeproj` in Xcode
2. Select your team under **Signing & Capabilities** for both the **County** and **CountyWidgetExtension** targets
3. Build and run (Cmd+R)

### Widget

The widget requires the app to be in `/Applications` for macOS to register it. After building in Xcode, deploy with the rebuild script (see below).

## Auto-rebuild

Free developer certificates expire after 7 days. The included rebuild scripts automate weekly rebuilds and deploys to `/Applications`.

### Setup

1. Copy `.env.example` to `.env` and fill in your SMTP credentials
2. Copy `rebuild.example.py` to `rebuild.py` (or `rebuild.example.sh` to `rebuild.sh`)
3. Add a cron job:

```
crontab -e
```

```
0 7 * * 1  /path/to/python3 /path/to/County/rebuild.py
```

The script will:
- Clean build the project via `xcodebuild`
- Deploy to `/Applications`
- Ad-hoc sign the app
- Restart the widget system
- Send a notification + email report

## Data sharing

The app writes countdown data as JSON to the widget extension's sandbox container. The widget reads this file directly — no App Groups required (works with free developer accounts).
