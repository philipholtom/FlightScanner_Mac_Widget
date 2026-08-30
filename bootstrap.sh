#!/usr/bin/env bash
# Generates PlaneRadar.xcodeproj from project.yml and opens it in Xcode.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "▶ Installing XcodeGen via Homebrew…"
    brew install xcodegen
  else
    echo "XcodeGen is required. Install Homebrew (https://brew.sh) then: brew install xcodegen" >&2
    exit 1
  fi
fi

echo "▶ Generating project…"
xcodegen generate

echo "▶ Opening PlaneRadar.xcodeproj"
open PlaneRadar.xcodeproj
