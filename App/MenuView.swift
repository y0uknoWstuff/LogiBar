import AppKit
import SwiftUI

struct MenuView: View {
    let monitor: Monitor
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 290)
        .task { await monitor.refresh(includeSettings: true) }
    }

    @ViewBuilder private var content: some View {
        let snapshot = monitor.snapshot
        switch snapshot.state {
        case .notInstalled:
            Notice(symbol: "exclamationmark.triangle",
                   title: "OpenLogi is not installed",
                   detail: "LogiBar reads your devices through OpenLogi.") {
                NSWorkspace.shared.open(URL(string: "https://github.com/aprilnea/openlogi")!)
            } actionTitle: { Text("Get OpenLogi") }
        case .unavailable:
            Notice(symbol: "powerplug",
                   title: "OpenLogi is not running",
                   detail: "Open OpenLogi to see your devices.") {
                openOpenLogi()
            } actionTitle: { Text("Open OpenLogi") }
        case .scanning:
            HStack {
                ProgressView().controlSize(.small)
                Text("Looking for devices…").foregroundStyle(.secondary)
            }
        case .ok where snapshot.devices.isEmpty:
            Text("No Logitech devices found.").foregroundStyle(.secondary)
        case .ok:
            ForEach(snapshot.devices) { device in
                DeviceRow(device: device)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Updated \(monitor.snapshot.updatedAt, style: .relative) ago")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Menu {
                Button("Open OpenLogi") { openOpenLogi() }
                Button("Settings…") {
                    NSApp.activate()
                    openSettings()
                }
                Divider()
                Button("Quit LogiBar") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private func openOpenLogi() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "org.openlogi.openlogi") {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }
}

private struct DeviceRow: View {
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

private struct Notice<ActionTitle: View>: View {
    let symbol: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let action: () -> Void
    @ViewBuilder let actionTitle: () -> ActionTitle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol).font(.headline)
            Text(detail).font(.callout).foregroundStyle(.secondary)
            Button(action: action, label: actionTitle)
        }
    }
}
