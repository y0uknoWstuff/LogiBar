# LogiBar

Battery level and status of Logitech mice on macOS — in the menu bar, as a desktop /
Notification Center widget, and with a low-battery alert. Data comes from
[OpenLogi](https://github.com/aprilnea/openlogi), which must be installed and running.

First target: the original **MX Master** (HID++ 2.0, battery feature `0x1000`, Unifying receiver).

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
xcodegen
open LogiBar.xcodeproj
```

Signing: Personal Team (free Apple ID) for local use. A paid account later enables
notarized `.dmg` distribution.
