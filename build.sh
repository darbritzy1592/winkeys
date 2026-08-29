#!/bin/zsh
# Builds WinKeys.app and signs it with the stable local identity.
#
# The identity matters: an ad-hoc signature changes on every build, macOS then
# treats each build as a different app, and the user has to grant Accessibility
# again every single time. A stable certificate makes the designated
# requirement "identifier + certificate root" instead of a cdhash, so the
# permission survives rebuilds.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="WinKeys"
BUNDLE_ID="com.winkeys.app"
IDENTITY="WinKeys Signing"        # created by Tools/setup-signing.sh
STAGE="build/stage/$APP_NAME.app"

echo "▸ Compiling…"
# Universal from day one: the same bundle runs on Intel and Apple Silicon.
# The arch flags must be repeated for --show-bin-path, or SwiftPM reports the
# single-architecture directory and the universal binary is silently ignored.
ARCH_FLAGS=(--arch x86_64 --arch arm64)
if ! swift build -c release "${ARCH_FLAGS[@]}" >/dev/null 2>&1; then
    echo "  cross-build unavailable, falling back to host architecture"
    ARCH_FLAGS=()
    swift build -c release >/dev/null
fi

BINARY="$(swift build -c release "${ARCH_FLAGS[@]}" --show-bin-path)/$APP_NAME"

echo "▸ Generating icon…"
swift Tools/MakeIcon.swift >/dev/null
iconutil -c icns build/WinKeys.iconset -o build/WinKeys.icns

echo "▸ Assembling bundle…"
rm -rf "$STAGE"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources"
cp "$BINARY" "$STAGE/Contents/MacOS/$APP_NAME"
cp build/WinKeys.icns "$STAGE/Contents/Resources/$APP_NAME.icns"

cat > "$STAGE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleIconFile</key><string>$APP_NAME</string>
    <key>LSMinimumSystemVersion</key><string>10.13</string>
    <key>LSUIElement</key><true/>
    <key>NSHumanReadableCopyright</key><string>GPL-3.0-or-later</string>
</dict>
</plist>
PLIST

echo "▸ Signing…"
if security find-identity -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
    codesign --force --strip-disallowed-xattrs --sign "$IDENTITY" "$STAGE"
    echo "  signed with '$IDENTITY' (permissions survive rebuilds)"
else
    codesign --force --strip-disallowed-xattrs --sign - "$STAGE"
    echo "  ⚠ ad-hoc: Accessibility will be asked again on every build."
    echo "    Run Tools/setup-signing.sh first."
fi
codesign --verify --strict "$STAGE"

echo "▸ Verifying architecture…"
lipo -archs "$STAGE/Contents/MacOS/$APP_NAME"

echo "✓ Ready: $STAGE"
