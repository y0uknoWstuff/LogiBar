import SwiftUI
import WidgetKit

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot
}

/// Reads what the menu bar app saved; the app reloads timelines whenever it changes.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = SnapshotStore.load()
        let shown = context.isPreview && snapshot.devices.isEmpty ? .preview : snapshot
        completion(SnapshotEntry(date: .now, snapshot: shown))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: .now, snapshot: SnapshotStore.load())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
    }
}

@main
struct LogiBarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LogiBarWidget", provider: SnapshotProvider()) { entry in
            WidgetView(snapshot: entry.snapshot)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Mouse battery")
        .description("Battery and status of your Logitech mouse, from OpenLogi.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetView: View {
    let snapshot: Snapshot
    @Environment(\.widgetFamily) private var family

    /// The app polls every 30 s; much older data means it is not running.
    private var isStale: Bool { Date.now.timeIntervalSince(snapshot.updatedAt) > 10 * 60 }

    var body: some View {
        if snapshot.state != .ok || isStale {
            unavailable
        } else if let device = snapshot.primary {
            switch family {
            case .systemMedium: medium(device)
            default: small(device)
            }
        } else {
            unavailable
        }
    }

    private var unavailableText: LocalizedStringKey {
        switch snapshot.state {
        case .notInstalled: "OpenLogi is not installed"
        case .untrusted: "OpenLogi could not be verified"
        default: "Open LogiBar"
        }
    }

    private var unavailable: some View {
        VStack(spacing: 6) {
            Image(systemName: "computermouse").font(.title2).foregroundStyle(.secondary)
            Text(unavailableText)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private func small(_ device: Device) -> some View {
        VStack(spacing: 8) {
            BatteryRing(device: device)
            Text(device.name)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func medium(_ device: Device) -> some View {
        HStack(spacing: 16) {
            BatteryRing(device: device)
            VStack(alignment: .leading, spacing: 6) {
                Text(device.name).font(.headline).lineLimit(2)
                if !device.online {
                    Text("Offline").foregroundStyle(.secondary)
                }
                if device.online, let status = BatteryStyle.statusText(for: device.battery) {
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
            Spacer(minLength: 0)
        }
    }
}

/// Circular battery ring with the percentage inside.
private struct BatteryRing: View {
    let device: Device

    var body: some View {
        let battery = device.online ? device.battery : nil
        let fraction = Double(battery?.estimatedPercentage ?? 0) / 100
        let color = BatteryStyle.color(for: battery)
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 8)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color == .primary ? .green : color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Image(systemName: battery?.isCharging == true ? "bolt.fill" : "computermouse.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(BatteryStyle.label(for: battery))
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(width: 84, height: 84)
    }
}

extension Snapshot {
    static let preview = Snapshot(
        state: .ok,
        devices: [Device(name: "MX Master", kind: "mouse", online: true,
                         battery: Battery(percentage: 72, level: "good", status: "discharging"),
                         dpi: 1000, smartShift: .ratchet)],
        updatedAt: .now)
}

#Preview(as: .systemMedium) {
    LogiBarWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .preview)
}
