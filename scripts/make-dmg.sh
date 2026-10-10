#!/usr/bin/env bash
# Packages build/MacTalk.app into build/MacTalk-<version>.dmg with an Applications shortcut.
#   MACTALK_NOTARY_PROFILE  notarytool keychain profile. If set, the DMG is notarized and stapled.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/MacTalk.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
DMG="build/MacTalk-$VERSION.dmg"
RW="build/MacTalk-rw.dmg"
[ -d "$APP" ] || { echo "run scripts/bundle.sh first"; exit 1; }

rm -f "$DMG" "$RW"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# Writable image first, so Finder can lay out the window; then compress it.
hdiutil create -volname "MacTalk" -srcfolder "$STAGE" -fs HFS+ -format UDRW -ov "$RW" >/dev/null
MOUNT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW" | awk -F'\t' '/\/Volumes\//{print $NF}')"
osascript <<OSA >/dev/null 2>&1 || echo "note: Finder layout skipped (grant Automation to Terminal for a styled window)"
tell application "Finder"
  tell disk "MacTalk"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {200, 120, 740, 508}
    set theViewOptions to icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 112
    set text size of theViewOptions to 13
    set position of item "MacTalk.app" of container window to {140, 250}
    set position of item "Applications" of container window to {400, 250}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
OSA
sync
hdiutil detach "$MOUNT" -quiet || hdiutil detach "$MOUNT" -force
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$RW"
rm -rf "$STAGE"

if [ -n "${MACTALK_NOTARY_PROFILE:-}" ]; then
    xcrun notarytool submit "$DMG" --keychain-profile "$MACTALK_NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
fi

hdiutil verify "$DMG" >/dev/null && echo "built $DMG"
