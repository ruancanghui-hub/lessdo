#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONTACT="${ROOT}/docs/publisher_contact.yaml"
PASS=0
FAIL=0

ok() {
  echo "  ✓ $1"
  PASS=$((PASS + 1))
}

bad() {
  echo "  ✗ $1" >&2
  FAIL=$((FAIL + 1))
}

yaml_value() {
  local key="$1"
  awk -F': ' -v k="$key" '$1 == k { print $2; exit }' "$CONTACT" | sed 's/^"//;s/"$//'
}

echo "==> LessDo App Store upload readiness"
echo

echo "==> Version"
VERSION_LINE="$(awk '/^version:/ { print $2 }' pubspec.yaml)"
MARKETING="${VERSION_LINE%%+*}"
BUILD="${VERSION_LINE#*+}"
echo "  Marketing version: ${MARKETING}"
echo "  Build number: ${BUILD}"
if [[ "${MARKETING}" == "1.0.0" ]]; then
  ok "marketing version is 1.0.0"
else
  bad "unexpected marketing version ${MARKETING}"
fi

BUNDLE_ID="$(yaml_value ios_bundle_id)"
if rg -q "PRODUCT_BUNDLE_IDENTIFIER = ${BUNDLE_ID};" ios/Runner.xcodeproj/project.pbxproj; then
  ok "iOS bundle ID matches publisher config (${BUNDLE_ID})"
else
  bad "iOS bundle ID mismatch (expected ${BUNDLE_ID})"
fi

echo
echo "==> Publisher URLs"
PRIVACY_URL="$(yaml_value privacy_policy_url)"
SUPPORT_URL="$(yaml_value support_url)"
SUPPORT_EMAIL="$(yaml_value support_email)"
POLICY_LIVE="$(yaml_value policy_published)"

for url in "$PRIVACY_URL" "$SUPPORT_URL"; do
  code="$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 15 "$url" || echo "000")"
  if [[ "$code" == "200" ]]; then
    ok "${url} (${code})"
  else
    bad "${url} (HTTP ${code})"
  fi
done

if [[ "${POLICY_LIVE}" == "true" ]]; then
  ok "policy_published is true"
else
  bad "policy_published is not true"
fi

if [[ -n "${SUPPORT_EMAIL}" && "${SUPPORT_EMAIL}" != *example.com* ]]; then
  ok "support_email configured (${SUPPORT_EMAIL})"
else
  bad "support_email missing or placeholder"
fi

echo
echo "==> Upload copy files"
for file in \
  docs/app_store_connect/en-US.txt \
  docs/app_store_connect/zh-Hans.txt \
  docs/app_store_connect/review-notes.txt \
  docs/APP_STORE_CONNECT_UPLOAD.md \
  docs/APP_STORE_METADATA.md; do
  if [[ -f "$file" ]]; then
    ok "$file"
  else
    bad "missing $file"
  fi
done

echo
echo "==> Screenshot folders"
mkdir -p docs/app_store_connect/screenshots/{iphone-6.9,ipad-13}/{en,zh}
SCREEN_COUNT="$(find docs/app_store_connect/screenshots -name '*.png' -o -name '*.jpg' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${SCREEN_COUNT}" -gt 0 ]]; then
  ok "${SCREEN_COUNT} screenshot(s) in docs/app_store_connect/screenshots/"
else
  echo "  ! No screenshots yet — capture before submission (see APP_STORE_CONNECT_UPLOAD.md §7)"
fi

echo
echo "==> Quick software gate (analyze + theme test)"
flutter pub get >/dev/null
flutter analyze >/dev/null && ok "flutter analyze" || bad "flutter analyze failed"
flutter test test/theme/lessdo_theme_test.dart >/dev/null && ok "theme regression tests" || bad "theme tests failed"

echo
if [[ "${FAIL}" -eq 0 ]]; then
  echo "Ready for metadata entry and Archive upload (${PASS} checks passed)."
  echo "Next: open docs/APP_STORE_CONNECT_UPLOAD.md and ios/Runner.xcworkspace"
  exit 0
fi

echo "${FAIL} check(s) failed, ${PASS} passed. Fix blockers before uploading." >&2
exit 1
