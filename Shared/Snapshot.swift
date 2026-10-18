import Foundation

/// What the menu bar app last learned from OpenLogi. The app writes it to the App Group
/// container; the widget only ever reads it.
struct Snapshot: Codable, Equatable, Sendable {
    enum AgentState: String, Codable, Sendable {
        case ok
        /// OpenLogi.app is not installed.
        case notInstalled
        /// Installed, but the agent is not running or not compatible.
        case unavailable
        /// The agent is still enumerating devices.
        case scanning
    }

    var state: AgentState
    var devices: [Device]
    var updatedAt: Date

    static let empty = Snapshot(state: .unavailable, devices: [], updatedAt: .distantPast)

    /// The device the widget and menu bar title show: the first online mouse, else the first mouse.
    var primary: Device? {
        devices.first { $0.kind == "mouse" && $0.online }
            ?? devices.first { $0.kind == "mouse" }
            ?? devices.first
    }
}

struct Device: Codable, Equatable, Identifiable, Sendable {
    /// OpenLogi's opaque route id. Not a stable key across reconnects.
    var id: String
    var name: String
    var kind: String
    var online: Bool
    var battery: Battery?
    var dpi: Int?
    var smartShift: SmartShiftMode?

    /// Stable enough to remember alert state between polls.
    var alertKey: String { "\(kind):\(name)" }
}

struct Battery: Codable, Equatable, Sendable {
    /// Nil when the device reports only a coarse level.
    var percentage: Int?
    var level: String?
    var status: String?

    var isCharging: Bool { status == "charging" || status == "full" }

    /// A percentage good enough for gauges and alerts, estimated from `level` when needed.
    var estimatedPercentage: Int? {
        if let percentage { return percentage }
        switch level {
        case "critical": return 5
        case "low": return 15
        case "good": return 50
        case "full": return 100
        default: return nil
        }
    }
}

enum SmartShiftMode: String, Codable, Sendable {
    case free, ratchet
}
