#!/bin/bash
# Weekly rebuild & deploy of County.app
# Logs to ~/Library/Logs/county-rebuild.log
#
# Create a .env file from .env.example and fill in your SMTP settings.

LOG=~/Library/Logs/county-rebuild.log
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$PROJECT_DIR/County.xcodeproj"
APP_NAME="County"
DEST="/Applications/${APP_NAME}.app"

exec >> "$LOG" 2>&1
echo "========================================"
echo "Rebuild started: $(date)"
echo "========================================"

# Clean build
xcodebuild clean build \
  -project "$PROJECT" \
  -scheme "$APP_NAME" \
  -configuration Debug \
  -derivedDataPath /tmp/CountyBuild \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO

if [ $? -ne 0 ]; then
  echo "ERROR: Build failed"
  osascript -e 'display notification "County rebuild failed — check log" with title "County"'
  exit 1
fi

# Deploy
rm -rf "$DEST"
cp -R /tmp/CountyBuild/Build/Products/Debug/${APP_NAME}.app "$DEST"
xattr -cr "$DEST"
codesign --force --deep --sign - "$DEST"

# Restart widget system
killall NotificationCenter 2>/dev/null

# Cleanup
rm -rf /tmp/CountyBuild

echo "SUCCESS: Deployed to $DEST at $(date)"
osascript -e 'display notification "County rebuilt & deployed to /Applications" with title "County"'
