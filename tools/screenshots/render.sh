#!/bin/sh
# Regenerates docs/images from the app's real SwiftUI views.
set -eu

cd "$(dirname "$0")/../.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
bin="${TMPDIR:-/tmp}/logibar-screenshots"

xcrun swiftc -parse-as-library -swift-version 5 -target arm64-apple-macos14.0 -o "$bin" \
    tools/screenshots/main.swift Shared/Snapshot.swift Shared/BatteryStyle.swift \
    Widget/WidgetView.swift App/DeviceRow.swift App/MenuBarLabel.swift
"$bin" docs/images
