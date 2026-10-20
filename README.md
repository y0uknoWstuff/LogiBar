# LogiBar

Battery level and status of Logitech mice on macOS — in the menu bar, as a desktop /
Notification Center widget, and with a low-battery alert. Data comes from
[OpenLogi](https://github.com/aprilnea/openlogi), which must be installed and running.

First target: the original **MX Master** (HID++ 2.0, battery feature `0x1000`, Unifying receiver).

## Install

1. Install and open [OpenLogi](https://github.com/aprilnea/openlogi/releases).
2. Download `LogiBar-<version>.dmg` from [Releases](https://github.com/y0uknoWstuff/LogiBar/releases),
   open it and drag LogiBar to Applications. The app is signed with Developer ID and notarized by Apple.
3. Open LogiBar: the mouse appears in the menu bar. To add the widget, right-click the desktop >
   Edit Widgets > LogiBar.

Requires macOS 14 or later.

## How it works

```
OpenLogi Agent ──(HID++)── mouse
      │
      │  openlogi api devices   (stable JSON, schema_version 1)
      ▼
LogiBar.app  (menu bar, not sandboxed)
  · polls the API, shows % in the menu bar
  · low-battery notifications (15% and 5%, reset on charge)
  · writes a snapshot to the App Group container ──► WidgetCenter.reloadAllTimelines()
      ▼
LogiBarWidget.appex  (WidgetKit, sandboxed)
  · reads the snapshot, never talks to OpenLogi or the hardware
```

- LogiBar never opens the HID device: OpenLogi stays the only owner of the hardware,
  so no conflicting HID++ requests.
- Only the documented `openlogi api` JSON contract is used (not the internal tarpc IPC,
  which is Rust-only and changes every release). Consumers must check `schema_version`
  and `ok` and ignore unknown fields.
- OpenLogi binary: `/Applications/OpenLogi.app/Contents/MacOS/openlogi`.
- Shown data: battery (`percentage`, `level`, `status`), online state, DPI
  (`api dpi`), SmartShift mode (`api smartshift`).

## Build

Requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
cp Local.xcconfig.example Local.xcconfig   # then put your team ID in it
tools/install.sh   # builds, installs in /Applications, restarts the app and its widget
```

Your team ID is in Xcode > Settings > Accounts.

To build a notarized `dist/LogiBar-<version>.dmg`: a Developer ID Application certificate, notary
credentials stored with `xcrun notarytool store-credentials logibar --apple-id <id> --team-id <team>`,
then `tools/release.sh`.

## License

[MIT](LICENSE)
