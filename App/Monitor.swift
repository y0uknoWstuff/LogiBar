import Foundation
import Observation
import WidgetKit

/// Polls OpenLogi, publishes the snapshot to the UI and the widget, and drives alerts.
@MainActor
@Observable
final class Monitor {
    private(set) var snapshot = SnapshotStore.load()
    private(set) var isRefreshing = false

    private let notifier = Notifier()
    /// DPI and SmartShift are live HID reads, so they are refreshed less often than the
    /// battery, which the agent already has in its inventory.
    private var settingsCache: [String: (dpi: Int?, smartShift: SmartShiftMode?)] = [:]
    private var settingsReadAt = Date.distantPast
    private var pollTask: Task<Void, Never>?

    private static let pollInterval: Duration = .seconds(30)
    private static let settingsInterval: TimeInterval = 5 * 60

    func start() {
        guard pollTask == nil else { return }
        notifier.requestAuthorization()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    /// `includeSettings` forces fresh DPI/SmartShift reads (e.g. when the menu opens).
    func refresh(includeSettings: Bool = false) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let next = await fetch(includeSettings: includeSettings)
        notifier.evaluate(next)
        guard next.devices != snapshot.devices || next.state != snapshot.state else {
            snapshot.updatedAt = next.updatedAt
            return
        }
        snapshot = next
        SnapshotStore.save(next)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func fetch(includeSettings: Bool) async -> Snapshot {
        let client: OpenLogiClient
        do {
            client = try OpenLogiClient()
        } catch {
            return Snapshot(state: .notInstalled, devices: [], updatedAt: .now)
        }
        guard let data = try? await client.devices() else {
            return Snapshot(state: .unavailable, devices: [], updatedAt: .now)
        }

        let readSettings = includeSettings
            || Date.now.timeIntervalSince(settingsReadAt) > Self.settingsInterval
        if readSettings { settingsReadAt = .now }

        var devices: [Device] = []
        for raw in data.devices {
            let id = raw.id ?? ""
            var device = Device(
                id: id,
                name: raw.name ?? String(localized: "Logitech device"),
                kind: raw.kind,
                online: raw.online,
                battery: raw.battery.map {
                    Battery(percentage: $0.percentage, level: $0.level, status: $0.status)
                })
            if readSettings, raw.online, raw.kind == "mouse", !id.isEmpty {
                let dpi = try? await client.dpi(device: id).current
                let mode = try? await client.smartShift(device: id).mode
                settingsCache[device.alertKey] = (dpi, mode.flatMap(SmartShiftMode.init(rawValue:)))
            }
            if let cached = settingsCache[device.alertKey] {
                device.dpi = cached.dpi
                device.smartShift = cached.smartShift
            }
            devices.append(device)
        }

        let state: Snapshot.AgentState = data.inventory == "ready" ? .ok : .scanning
        return Snapshot(state: state, devices: devices, updatedAt: .now)
    }
}
