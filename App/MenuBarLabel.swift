import SwiftUI

/// The menu bar item: a mouse glyph and the primary device's battery.
struct MenuBarLabel: View {
    let snapshot: Snapshot

    var body: some View {
        let battery = snapshot.state == .ok ? snapshot.primary?.battery : nil
        HStack(spacing: 3) {
            Image(systemName: battery == nil ? "computermouse" : "computermouse.fill")
            if let battery {
                Text(BatteryStyle.label(for: battery))
                    .monospacedDigit()
            }
        }
    }
}
