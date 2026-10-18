import Foundation
import UserNotifications

/// Low-battery alerts: one at the user's threshold, one at the critical level, re-armed
/// once the device charges.
@MainActor
final class Notifier {
    static let thresholdKey = "alertThreshold"
    static let defaultThreshold = 15
    static let criticalThreshold = 5

    private let defaults = UserDefaults.standard
    private let lastAlertKey = "lastAlertedThreshold"

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func evaluate(_ snapshot: Snapshot) {
        guard snapshot.state == .ok else { return }
        let configured = defaults.object(forKey: Self.thresholdKey) as? Int ?? Self.defaultThreshold
        let thresholds = Set([configured, Self.criticalThreshold]).sorted(by: >)
        var alerted = defaults.dictionary(forKey: lastAlertKey) as? [String: Int] ?? [:]

        for device in snapshot.devices where device.online {
            guard let battery = device.battery, let percent = battery.estimatedPercentage else {
                continue
            }
            let key = device.alertKey
            if battery.isCharging || percent > configured {
                alerted[key] = nil
                continue
            }
            // The lowest threshold already crossed; alert only when it is new.
            guard let crossed = thresholds.last(where: { percent <= $0 }),
                  crossed < alerted[key] ?? Int.max
            else { continue }
            alerted[key] = crossed
            post(device: device, label: BatteryStyle.label(for: battery),
                 critical: crossed <= Self.criticalThreshold)
        }
        defaults.set(alerted, forKey: lastAlertKey)
    }

    private func post(device: Device, label: String, critical: Bool) {
        let content = UNMutableNotificationContent()
        content.title = critical
            ? String(localized: "\(device.name): battery almost empty")
            : String(localized: "\(device.name): low battery")
        content.body = String(localized: "\(label) left. Charge it soon.")
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "battery-\(device.alertKey)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
