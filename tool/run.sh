#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-iphone}"
DEVICE_ID="${LESSDO_DEVICE_ID:-}"

usage() {
  cat <<'EOF'
Usage: ./tool/run.sh [iphone|ipad|macos|chrome|device-id]

Examples:
  ./tool/run.sh
  ./tool/run.sh ipad
  ./tool/run.sh macos
  LESSDO_DEVICE_ID=932D8363-BB30-4E74-8F45-CC5B5BA4CBDF ./tool/run.sh device-id

Defaults to the booted iPhone simulator when available.
EOF
}

if [[ "${TARGET}" == "-h" || "${TARGET}" == "--help" ]]; then
  usage
  exit 0
fi

pick_device() {
  if [[ -n "${DEVICE_ID}" ]]; then
    echo "${DEVICE_ID}"
    return
  fi

  local platform=""
  case "${TARGET}" in
    iphone) platform="ios" ;;
    ipad) platform="ios" ;;
    macos) platform="darwin" ;;
    chrome) platform="web-javascript" ;;
    device-id) echo ""; return ;;
    *)
      echo "Unknown target: ${TARGET}" >&2
      usage >&2
      exit 1
      ;;
  esac

  ruby -rjson -e '
    require "json"
    target = ARGV[0]
    platform = ARGV[1]
    devices = JSON.parse(STDIN.read)
    matches = devices.select do |device|
      next false unless device["targetPlatform"] == platform
      case target
      when "iphone" then device["name"].include?("iPhone")
      when "ipad" then device["name"].include?("iPad")
      when "macos" then device["name"].include?("macOS")
      when "chrome" then device["name"].include?("Chrome")
      else false
      end
    end
  puts matches.first&.fetch("id", "")
  ' "${TARGET}" "${platform}" < <(flutter devices --machine 2>/dev/null || echo "[]")
}

echo "==> Preparing LessDo"
flutter pub get
flutter gen-l10n

DEVICE="$(pick_device)"
RUN_ARGS=()

if [[ -n "${DEVICE}" ]]; then
  echo "==> Running on device ${DEVICE}"
  RUN_ARGS=(-d "${DEVICE}")
else
  echo "==> Running on Flutter default device"
fi

echo "==> Launching app"
if [[ ${#RUN_ARGS[@]} -gt 0 ]]; then
  exec flutter run "${RUN_ARGS[@]}"
else
  exec flutter run
fi
