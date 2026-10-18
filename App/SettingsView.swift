import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage(Notifier.thresholdKey) private var threshold = Notifier.defaultThreshold
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Picker("Low battery alert", selection: $threshold) {
                ForEach([10, 15, 20, 25, 30], id: \.self) { Text("\($0)%").tag($0) }
            }
            Text("A second alert always fires at \(Notifier.criticalThreshold)%.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Toggle("Open at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .fixedSize()
    }
}
