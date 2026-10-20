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
        case .untrusted:
            Notice(symbol: "xmark.shield",
                   title: "OpenLogi could not be verified",
                   detail: "The installed OpenLogi is not signed by its developer, so LogiBar does not run it. Reinstall it from the official site.") {
                NSWorkspace.shared.open(URL(string: "https://github.com/aprilnea/openlogi/releases")!)
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
