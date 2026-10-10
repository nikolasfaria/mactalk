#!/usr/bin/env bash
# Builds build/MacTalk.app.
#   MACTALK_SIGN_ID   signing identity (default "-" = ad-hoc, for local use only)
#   MACTALK_ENTITLEMENTS  defaults to Resources/MacTalk.entitlements
set -euo pipefail
cd "$(dirname "$0")/.."

SIGN_ID="${MACTALK_SIGN_ID:--}"
ENTITLEMENTS="${MACTALK_ENTITLEMENTS:-Resources/MacTalk.entitlements}"
APP="build/MacTalk.app"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/MacTalk"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/MacTalk"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/PrivacyInfo.xcprivacy "$APP/Contents/Resources/"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
cp Resources/MenuBarIcon*.png "$APP/Contents/Resources/"
cp Vendor/sherpa-onnx/lib/*.dylib "$APP/Contents/Frameworks/"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/" || echo "note: no Resources/AppIcon.icns yet"

# Dev builds carry rpaths to the repo's Vendor/ folder; the bundle must only use Contents/Frameworks.
otool -l "$APP/Contents/MacOS/MacTalk" | awk '/LC_RPATH/{f=1} f && /path /{print $2; f=0}' \
    | grep '/Vendor/sherpa-onnx/lib$' \
    | while read -r rpath; do install_name_tool -delete_rpath "$rpath" "$APP/Contents/MacOS/MacTalk"; done

# Sign inside-out. Hardened runtime is required for notarization and the App Store.
OPTS=()
[ "$SIGN_ID" != "-" ] && OPTS=(--options runtime --timestamp)
for lib in "$APP"/Contents/Frameworks/*.dylib; do
    codesign --force ${OPTS[@]+"${OPTS[@]}"} --sign "$SIGN_ID" "$lib"
done
codesign --force ${OPTS[@]+"${OPTS[@]}"} --sign "$SIGN_ID" --entitlements "$ENTITLEMENTS" "$APP"
codesign --verify --deep --strict "$APP" && echo "signature ok ($SIGN_ID)"

echo "built $APP"
