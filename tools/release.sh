#!/bin/sh
# Builds a notarized, stapled LogiBar-<version>.dmg in dist/ for distribution outside the
# App Store.
#
# Needs, once per Mac:
#   - a "Developer ID Application" certificate (Xcode > Settings > Accounts > Manage Certificates)
#   - notary credentials in the keychain, stored with
#       xcrun notarytool store-credentials logibar --apple-id <apple id> --team-id <team id>
#     (NOTARY_PROFILE overrides the profile name)
set -eu

cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
profile="${NOTARY_PROFILE:-logibar}"
team=$(sed -n 's/^DEVELOPMENT_TEAM *= *//p' Local.xcconfig)
work="${TMPDIR:-/tmp}/logibar-release"

identity=$(security find-identity -v -p codesigning \
    | sed -n "s/.*\"\(Developer ID Application: .* ($team)\)\"/\1/p" | head -n 1)
[ -n "$identity" ] || { echo "No Developer ID Application certificate for team $team." >&2; exit 1; }
xcrun notarytool history --keychain-profile "$profile" >/dev/null \
    || { echo "No notary credentials in the keychain profile '$profile'." >&2; exit 1; }

rm -rf "$work"
mkdir -p "$work" dist
xcodegen -q

echo "==> Archiving"
xcodebuild -project LogiBar.xcodeproj -scheme LogiBar -configuration Release \
    -archivePath "$work/LogiBar.xcarchive" -allowProvisioningUpdates -quiet archive

echo "==> Exporting with Developer ID"
cat > "$work/export.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>developer-id</string>
    <key>signingStyle</key><string>automatic</string>
    <key>teamID</key><string>$team</string>
</dict>
</plist>
EOF
xcodebuild -exportArchive -archivePath "$work/LogiBar.xcarchive" \
    -exportOptionsPlist "$work/export.plist" -exportPath "$work/export" \
    -allowProvisioningUpdates -quiet
app="$work/export/LogiBar.app"
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist")

echo "==> Notarizing the app"
ditto -c -k --keepParent "$app" "$work/LogiBar.zip"
xcrun notarytool submit "$work/LogiBar.zip" --keychain-profile "$profile" --wait
xcrun stapler staple "$app"

echo "==> Building the disk image"
mkdir "$work/dmg"
cp -R "$app" "$work/dmg/"
ln -s /Applications "$work/dmg/Applications"
dmg="dist/LogiBar-$version.dmg"
rm -f "$dmg"
hdiutil create -volname "LogiBar $version" -srcfolder "$work/dmg" -fs HFS+ -format UDZO \
    -ov "$dmg" >/dev/null
codesign --sign "$identity" --timestamp "$dmg"

echo "==> Notarizing the disk image"
xcrun notarytool submit "$dmg" --keychain-profile "$profile" --wait
xcrun stapler staple "$dmg"

echo "==> Verifying"
spctl --assess --type open --context context:primary-signature --verbose "$dmg"
spctl --assess --type execute --verbose "$app"
shasum -a 256 "$dmg"
echo "Ready: $dmg"
