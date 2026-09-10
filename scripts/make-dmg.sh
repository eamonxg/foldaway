#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."

APP="build/Foldaway.app"
[[ -d "$APP" ]] || { echo "missing $APP; run scripts/build.sh first" >&2; exit 1; }
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")}"
OUTPUT="build/Foldaway-${VERSION}.dmg"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/root/.background"
cp -R "$APP" "$STAGE/root/"
ln -s /Applications "$STAGE/root/Applications"
swift scripts/make-dmg-background.swift "$STAGE"
tiffutil -cathidpicheck "$STAGE/background.png" "$STAGE/background@2x.png" -out "$STAGE/root/.background/background.tiff"

hdiutil create -volname Foldaway -srcfolder "$STAGE/root" -fs HFS+ -format UDRW -ov "$STAGE/rw.dmg" >/dev/null
MOUNT_POINT="$(hdiutil attach -readwrite -noverify -noautoopen "$STAGE/rw.dmg" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1 | sed 's/[[:space:]]*$//')"
VOLUME_NAME="$(basename "$MOUNT_POINT")"

osascript - "$VOLUME_NAME" <<'EOS' || echo "warning: Finder layout not applied" >&2
on run argv
  set volumeName to item 1 of argv
  tell application "Finder"
    tell disk volumeName
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set bounds of container window to {200, 120, 860, 520}
      set viewOptions to icon view options of container window
      set arrangement of viewOptions to not arranged
      set icon size of viewOptions to 128
      set background picture of viewOptions to file ".background:background.tiff"
      set position of item "Foldaway.app" of container window to {165, 185}
      set position of item "Applications" of container window to {495, 185}
      close
      open
      update without registering applications
      delay 1
      close
    end tell
  end tell
end run
EOS

sync
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$OUTPUT"
hdiutil convert "$STAGE/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$OUTPUT" >/dev/null
echo "Built $OUTPUT"
