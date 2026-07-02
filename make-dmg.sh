#!/bin/bash
#
# make-dmg.sh - Build Cherry (Release, Developer ID), package a pretty
# drag-to-install DMG, then notarize + staple it so Gatekeeper is happy.
#
# One-time setup (see CHERRY-HANDOFF.md "Signing / versions"):
#   1. Xcode > Settings > Accounts > Manage Certificates > + > Developer ID Application
#   2. App-specific password from appleid.apple.com
#   3. xcrun notarytool store-credentials Cherry-Notary \
#        --apple-id <apple-id-email> --team-id VTMKE23N5G --password <app-specific-pw>
#
# Usage:
#   bash make-dmg.sh                     # build Release, then package + notarize
#   bash make-dmg.sh /path/to/Cherry.app # skip build, package + notarize an existing app
#
set -euo pipefail
cd "$(dirname "$0")"

APP="${1:-}"
WORK=""

if [ -z "$APP" ]; then
  if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "No 'Developer ID Application' certificate in your keychain."
    echo "Create one: Xcode > Settings > Accounts > Manage Certificates > + > Developer ID Application"
    exit 1
  fi
  echo "Building Cherry (Release)... this can take a minute."
  WORK=$(mktemp -d)
  xcodebuild -project cherry.xcodeproj -scheme Cherry -configuration Release \
    -archivePath "$WORK/Cherry.xcarchive" -quiet archive
  cat > "$WORK/export-options.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>developer-id</string>
	<key>teamID</key>
	<string>VTMKE23N5G</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
PLIST
  echo "Re-signing for distribution (Developer ID)..."
  xcodebuild -exportArchive -archivePath "$WORK/Cherry.xcarchive" \
    -exportOptionsPlist "$WORK/export-options.plist" -exportPath "$WORK/export" -quiet
  APP="$WORK/export/Cherry.app"
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
hdiutil create -size "${SIZE_MB}m" -fs HFS+ -volname "$VOL" -ov "$RW" >/dev/null

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

# Notarize + staple (needs the one-time Cherry-Notary keychain profile, see header)
echo "Notarizing with Apple... typically 2-5 minutes, don't panic."
xcrun notarytool submit "$OUT" --keychain-profile "Cherry-Notary" --wait
xcrun stapler staple "$OUT"

# Cleanup
rm -rf "$RWDIR"
[ -n "$WORK" ] && rm -rf "$WORK"

echo ""
echo "Done -> $OUT (signed with Developer ID, notarized, stapled)"
echo "Open it to check the layout: Cherry on the left, arrow, Applications on the right."
