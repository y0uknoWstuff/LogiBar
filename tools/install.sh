#!/bin/sh
# Builds LogiBar (Release), installs it in /Applications and restarts it.
#
# The running widget extension is stopped too: chronod keeps an old process alive across a
# reinstall, and old code reading a newer snapshot shows nothing. Derived data stays outside
# the repo so LaunchServices never registers a second copy of the app.
set -eu

cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
derived="${TMPDIR:-/tmp}/logibar-build"
lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

xcodegen -q
xcodebuild -project LogiBar.xcodeproj -scheme LogiBar -configuration Release \
    -derivedDataPath "$derived" -allowProvisioningUpdates -quiet build
built="$derived/Build/Products/Release/LogiBar.app"

pkill -x LogiBar || true
pkill -x LogiBarWidget || true
rm -rf /Applications/LogiBar.app
cp -R "$built" /Applications/
"$lsregister" -u "$built" || true
rm -rf "$derived/Build/Products"

open /Applications/LogiBar.app
echo "LogiBar installed and running."
