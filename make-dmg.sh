#!/bin/bash
#
# make-dmg.sh - Build Cherry (Release) and package a drag-to-install DMG.
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

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || echo dev)

STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/Cherry.app"
ln -s /Applications "$STAGE/Applications"

OUT="$HOME/Desktop/Cherry-$VERSION.dmg"
rm -f "$OUT"
echo "Packaging $OUT ..."
hdiutil create -volname "Cherry" -srcfolder "$STAGE" -ov -format UDZO "$OUT" >/dev/null

rm -rf "$STAGE"
[ -n "$DERIVED" ] && rm -rf "$DERIVED"

echo ""
echo "Done -> $OUT"
echo "Open it, drag Cherry into Applications, then launch and grant Accessibility + Screen Recording once."
