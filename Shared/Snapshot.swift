import Foundation

/// What the menu bar app last learned from OpenLogi. The app writes it to the App Group
/// container; the widget only ever reads it.
struct Snapshot: Codable, Equatable, Sendable {
    enum AgentState: String, Codable, Sendable {
        case ok
        /// OpenLogi.app is not installed.
        case notInstalled
        /// An app claims to be OpenLogi but is not signed by its developer.
        case untrusted
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
    var name: String
    var kind: String
    var online: Bool
    var battery: Battery?
    var dpi: Int?
    var smartShift: SmartShiftMode?

    /// Stable enough to remember alert state between polls. OpenLogi's route id is
    /// deliberately not kept: it embeds the receiver's serial and this file is persisted.
    var alertKey: String { "\(kind):\(name)" }
    var id: String { alertKey }
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
