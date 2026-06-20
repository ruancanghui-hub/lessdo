#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> flutter pub get"
flutter pub get >/dev/null

echo "==> flutter gen-l10n"
flutter gen-l10n

echo "==> dart format"
dart format --output=none --set-exit-if-changed lib test integration_test

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> flutter build ios --release --no-codesign"
flutter build ios --release --no-codesign

APP="build/ios/iphoneos/Runner.app"
if [[ ! -d "$APP" ]]; then
  echo "Missing $APP" >&2
  exit 1
fi

echo "==> bundle inspection"
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$APP/Info.plist"

if find "$APP" -name 'PrivacyInfo.xcprivacy' | grep -q .; then
  echo "privacy manifests: ok"
else
  echo "missing privacy manifests" >&2
  exit 1
fi

if find "$APP/Frameworks" -maxdepth 1 -iname '*purchase*' 2>/dev/null | grep -q .; then
  echo "forbidden in_app_purchase framework in release bundle" >&2
  exit 1
fi

if grep -a -E -q "Upgrade|Premium|Cloud sync|Calendar sync|example.com" "$APP" 2>/dev/null; then
  echo "forbidden marketing strings in release bundle" >&2
  exit 1
fi

echo "release verification passed"
