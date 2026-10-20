import SwiftUI

/// One device in the menu: name, battery bar and its settings.
struct DeviceRow: View {
    let device: Device

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: device.kind == "keyboard" ? "keyboard" : "computermouse")
                    .foregroundStyle(.secondary)
                Text(device.name).font(.headline).lineLimit(1)
                Spacer()
                if device.online {
                    Text(BatteryStyle.label(for: device.battery))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(BatteryStyle.color(for: device.battery))
                } else {
                    Text("Offline").foregroundStyle(.secondary)
                }
            }
            if device.online, let percent = device.battery?.estimatedPercentage {
                ProgressView(value: Double(percent), total: 100)
                    .tint(BatteryStyle.color(for: device.battery))
            }
            if device.online {
                HStack(spacing: 14) {
                    if let status = BatteryStyle.statusText(for: device.battery) {
                        Label(status, systemImage: BatteryStyle.symbol(for: device.battery))
                    }
                    if let dpi = device.dpi {
                        Label("\(dpi) DPI", systemImage: "scope")
                    }
                    if let mode = device.smartShift {
                        Label(mode == .free ? "Free spin" : "Ratchet",
                              systemImage: mode == .free ? "arrow.trianglehead.2.clockwise" : "gearshape.2")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            }
        }
    }
}
