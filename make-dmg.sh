#!/bin/bash
#
# make-dmg.sh - Build Cherry (Release) and package a pretty drag-to-install DMG.
# Personal use only (installing on my own Macs). Not for public distribution.
#
# Usage:
#   bash make-dmg.sh                     # build Release, then package
#   bash make-dmg.sh /path/to/Cherry.app # skip build, package an existing app
#
set -euo pipefail
cd "$(dirname "$0")"

APP="${1:-}"
DERIVED=""

if [ -z "$APP" ]; then
  echo "Building Cherry (Release)... this can take a minute."
  DERIVED=$(mktemp -d)
  xcodebuild -project cherry.xcodeproj -scheme Cherry -configuration Release \
    -derivedDataPath "$DERIVED" -quiet build
  APP="$DERIVED/Build/Products/Release/Cherry.app"
fi

[ -d "$APP" ] || { echo "Cherry.app not found at: $APP"; exit 1; }

VOL="Cherry"
OUT="$HOME/Desktop/Cherry.dmg"
BG="dmg-assets/dmg-background.png"
RWDIR=$(mktemp -d)
RW="$RWDIR/rw.dmg"

# Detach any leftover mount from a previous run
hdiutil detach "/Volumes/$VOL" >/dev/null 2>&1 || true

# Blank read-write image, sized to the app + a buffer for the layout metadata
APP_KB=$(du -sk "$APP" | cut -f1)
SIZE_MB=$(( APP_KB / 1024 + 25 ))
hdiutil create -size "${SIZE_MB}m" -fs HFS+ -volname "$VOL" -format UDRW -ov "$RW" >/dev/null

echo "Laying out the window (Finder may ask permission to control itself the first time)..."
hdiutil attach "$RW" -noautoopen >/dev/null
sleep 1

# Contents: app, hidden background, and the Applications shortcut
ditto "$APP" "/Volumes/$VOL/Cherry.app"
mkdir -p "/Volumes/$VOL/.background"
cp "$BG" "/Volumes/$VOL/.background/background.png"
ln -s /Applications "/Volumes/$VOL/Applications"

# Arrange: Cherry on the left, arrow, Applications on the right, over the background
osascript <<EOF
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {400, 200, 1060, 600}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 128
    set text size of opts to 12
    set background picture of opts to file ".background:background.png"
    set position of item "Cherry.app" of container window to {180, 200}
    set position of item "Applications" of container window to {480, 200}
    update without registering applications
    delay 2
    close
  end tell
end tell
EOF
sync
sleep 1

hdiutil detach "/Volumes/$VOL" >/dev/null

# Compress to the final read-only DMG
rm -f "$OUT"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$OUT" >/dev/null

# Cleanup
rm -rf "$RWDIR"
[ -n "$DERIVED" ] && rm -rf "$DERIVED"

echo ""
echo "Done -> $OUT"
echo "Open it to check the layout: Cherry on the left, arrow, Applications on the right."
