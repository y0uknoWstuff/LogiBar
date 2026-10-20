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
            WidgetEntryView(snapshot: entry.snapshot)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Mouse battery")
        .description("Battery and status of your Logitech mouse, from OpenLogi.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Reads the size WidgetKit gives this instance.
struct WidgetEntryView: View {
    let snapshot: Snapshot
    @Environment(\.widgetFamily) private var family

    var body: some View {
        WidgetView(snapshot: snapshot, family: family)
    }
}

#Preview(as: .systemMedium) {
    LogiBarWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .preview)
}
