import SwiftUI

/// Shared look for battery readings, so the menu and the widget agree.
enum BatteryStyle {
    static func color(for battery: Battery?) -> Color {
        guard let battery, let percent = battery.estimatedPercentage else { return .secondary }
        if battery.isCharging { return .green }
        switch percent {
        case ..<10: return .red
        case ..<20: return .orange
        default: return .primary
        }
    }

    /// SF Symbol matching the fill level, with the bolt while charging.
    static func symbol(for battery: Battery?) -> String {
        guard let battery, let percent = battery.estimatedPercentage else {
            return "battery.0percent"
        }
        if battery.isCharging { return "battery.100percent.bolt" }
        switch percent {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    static func label(for battery: Battery?) -> String {
        guard let battery else { return "—" }
        if let percent = battery.percentage { return "\(percent)%" }
        return battery.level.map { String(localized: String.LocalizationValue($0.capitalized)) } ?? "—"
    }

    static func statusText(for battery: Battery?) -> String? {
        switch battery?.status {
        case "charging": return String(localized: "Charging")
        case "full": return String(localized: "Fully charged")
        case "discharging": return String(localized: "On battery")
        default: return nil
        }
    }
}
