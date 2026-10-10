#!/usr/bin/env bash
# Mac App Store build: signed .app -> signed .pkg -> upload to App Store Connect.
# Needs an Apple Developer Program membership and these certificates in your keychain:
#   MACTALK_APP_SIGN_ID        "Apple Distribution: Your Name (TEAMID)"   (or "3rd Party Mac Developer Application: ...")
#   MACTALK_INSTALLER_SIGN_ID  "Mac Installer Distribution: Your Name (TEAMID)" (or "3rd Party Mac Developer Installer: ...")
#   MACTALK_APPLE_ID, MACTALK_APP_PASSWORD  App Store Connect credentials (app-specific password) for upload
# Not yet run end-to-end: it requires the Apple Developer account and App Store Connect app record.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${MACTALK_APP_SIGN_ID:?set MACTALK_APP_SIGN_ID}"
: "${MACTALK_INSTALLER_SIGN_ID:?set MACTALK_INSTALLER_SIGN_ID}"

MACTALK_SIGN_ID="$MACTALK_APP_SIGN_ID" ./scripts/bundle.sh

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
PKG="build/MacTalk-$VERSION.pkg"
rm -f "$PKG"
productbuild --component build/MacTalk.app /Applications --sign "$MACTALK_INSTALLER_SIGN_ID" "$PKG"
pkgutil --check-signature "$PKG" | head -3

if [ -n "${MACTALK_APPLE_ID:-}" ]; then
    xcrun altool --upload-app -f "$PKG" -t macos -u "$MACTALK_APPLE_ID" -p "$MACTALK_APP_PASSWORD"
    echo "uploaded $PKG to App Store Connect"
else
    echo "built $PKG (set MACTALK_APPLE_ID and MACTALK_APP_PASSWORD to upload)"
fi
