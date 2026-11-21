#!/usr/bin/env bash
# Takes the App Store screenshots (6.9", Turkish and English) in the simulator.
# Run from the project folder:  Tools/screenshots.sh
set -euo pipefail

DEVICE_NAME="${DEVICE_NAME:-iPhone 18 Pro Max}"
OUT="Docs/AppStore/Screenshots"
DERIVED="${TMPDIR:-/tmp}/redcard-screenshots"
BUNDLE="com.batuhan.redcard"

DEVICE=$(xcrun simctl list devices available | grep -m1 "    $DEVICE_NAME (" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$DEVICE" ] || { echo "Simulator '$DEVICE_NAME' not found"; exit 1; }

xcodebuild -project RedCard.xcodeproj -scheme RedCard -configuration Debug \
  -destination "id=$DEVICE" -derivedDataPath "$DERIVED" build -quiet

xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null
xcrun simctl ui "$DEVICE" appearance light
xcrun simctl status_bar "$DEVICE" override --time "9:41" --batteryState discharging \
  --batteryLevel 100 --wifiBars 3 --cellularMode active --cellularBars 4 --operatorName ""

# A clean install, so the home screen shows the first-run "Turn on the filter" state.
xcrun simctl uninstall "$DEVICE" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$DEVICE" "$DERIVED/Build/Products/Debug-iphonesimulator/RedCard.app"

shoot() { # language locale screen file
  xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$DEVICE" "$BUNDLE" -AppleLanguages "($1)" -AppleLocale "$2" -RedCardScreenshot "$3" >/dev/null
  sleep "${WAIT:-8}"
  mkdir -p "$OUT/$1"
  xcrun simctl io "$DEVICE" screenshot "$OUT/$1/$4.png" >/dev/null
  echo "  $OUT/$1/$4.png"
}

# The first launch after installing is slow; warm the app up once.
xcrun simctl launch "$DEVICE" "$BUNDLE" -RedCardScreenshot home >/dev/null
sleep 10

for lang in tr en; do
  locale=$([ "$lang" = tr ] && echo tr_TR || echo en_US)
  shoot "$lang" "$locale" home 1-home
  shoot "$lang" "$locale" tester 2-try-a-message
  shoot "$lang" "$locale" setup 3-setup
done

xcrun simctl status_bar "$DEVICE" clear

# App Store Connect asks for 6.1"/6.3" screenshots (1206x2622); JPEG has no alpha.
for lang in tr en; do
  mkdir -p "Docs/AppStore/Screenshots-6.3in/$lang"
  for f in "$OUT/$lang"/*.png; do
    name=$(basename "$f" .png)
    sips -z 2622 1206 -s format jpeg -s formatOptions 95 "$f" \
      --out "Docs/AppStore/Screenshots-6.3in/$lang/$lang-$name-1206x2622.jpg" >/dev/null
  done
done
echo "Done."
