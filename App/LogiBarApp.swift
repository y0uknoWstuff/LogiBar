import SwiftUI

@main
struct LogiBarApp: App {
    @State private var monitor = Monitor()

    var body: some Scene {
        MenuBarExtra {
            MenuView(monitor: monitor)
        } label: {
            MenuBarLabel(snapshot: monitor.snapshot)
                .task { monitor.start() }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
