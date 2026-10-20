// Renders the README images from the app's real views, in light and dark.
// Run with tools/screenshots/render.sh.
import AppKit
import SwiftUI
import WidgetKit

@main
struct ScreenshotRenderer {
    @MainActor
    static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        for (name, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            try render(Desktop(), size: CGSize(width: 940, height: 290), appearance: appearance,
                       to: output.appendingPathComponent("overview-\(name).png"))
            try render(States(), size: CGSize(width: 940, height: 250), appearance: appearance,
                       to: output.appendingPathComponent("states-\(name).png"))
        }
    }

    @MainActor
    static func render(_ view: some View, size: CGSize, appearance: NSAppearance.Name, to url: URL) throws {
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        host.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: appearance)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: .now.addingTimeInterval(0.3))

        let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
        rep.size = size
        host.cacheDisplay(in: host.bounds, to: rep)
        try rep.representation(using: .png, properties: [:])!.write(to: url)
        print("wrote \(url.lastPathComponent)")
    }
}

// MARK: - Sample data

private func snapshot(_ percent: Int, _ status: String, dpi: Int = 1000,
                      wheel: SmartShiftMode = .ratchet) -> Snapshot {
    let level = percent <= 5 ? "critical" : percent <= 15 ? "low" : "good"
    return Snapshot(
        state: .ok,
        devices: [Device(name: "MX Master", kind: "mouse", online: true,
                         battery: Battery(percentage: percent, level: level, status: status),
                         dpi: dpi, smartShift: wheel)],
        updatedAt: .now)
}

// MARK: - Scenes

/// A desktop corner: the menu bar item open over its panel, and both widget sizes.
private struct Desktop: View {
    private let current = snapshot(72, "discharging")

    var body: some View {
        ZStack(alignment: .topLeading) {
            Wallpaper()
            VStack(spacing: 0) {
                MenuBar(snapshot: current)
                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 20) {
                        WidgetCard(snapshot: current, family: .systemSmall)
                        Caption("Small widget")
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        WidgetCard(snapshot: current, family: .systemMedium)
                        Caption("Medium widget")
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 20) {
                        Panel(snapshot: current)
                        Caption("Menu bar panel")
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)
            }
        }
    }
}

/// The same widget through a charge cycle.
private struct States: View {
    var body: some View {
        ZStack {
            Wallpaper()
            HStack(spacing: 26) {
                state(snapshot(72, "discharging"), "On battery")
                state(snapshot(14, "discharging", wheel: .free), "Low: first alert")
                state(snapshot(5, "discharging"), "Critical: second alert")
                state(snapshot(45, "charging"), "Charging")
            }
        }
    }

    private func state(_ snapshot: Snapshot, _ title: String) -> some View {
        VStack(spacing: 16) {
            WidgetCard(snapshot: snapshot, family: .systemSmall)
            Caption(title)
        }
    }
}

// MARK: - Pieces

private struct Wallpaper: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.06, green: 0.10, blue: 0.20), Color(red: 0.10, green: 0.20, blue: 0.32)]
                : [Color(red: 0.70, green: 0.82, blue: 0.95), Color(red: 0.86, green: 0.91, blue: 0.97)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct MenuBar: View {
    let snapshot: Snapshot

    var body: some View {
        HStack(spacing: 18) {
            Spacer()
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            MenuBarLabel(snapshot: snapshot)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
            Text("Tue 10:41")
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 16)
        .frame(height: 30)
        .background(.bar)
    }
}

private struct WidgetCard: View {
    let snapshot: Snapshot
    let family: WidgetFamily

    var body: some View {
        WidgetView(snapshot: snapshot, family: family)
            .padding(16)
            .frame(width: family == .systemMedium ? 344 : 160, height: 160)
            .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
    }
}

private struct Panel: View {
    let snapshot: Snapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(snapshot.devices) { DeviceRow(device: $0) }
            Divider()
            HStack {
                Text("Updated 12 seconds ago").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "gearshape").foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 290)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
    }
}

private struct Caption: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).font(.callout.weight(.medium)).foregroundStyle(.primary.opacity(0.75))
    }
}
