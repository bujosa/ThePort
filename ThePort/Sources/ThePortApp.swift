import SwiftUI

@main
struct ThePortApp: App {
    @State private var portService = PortService()
    @State private var databaseService = DatabaseService()

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(portService)
                .environment(databaseService)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    configureWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Ports") {
                Button("Refresh") {
                    portService.refresh()
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Show All Ports") {
                    // Navigation handled by sidebar
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Show Listening") {
                    // Navigation handled by sidebar
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Show Established") {
                    // Navigation handled by sidebar
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Show Watchlist") {
                    // Navigation handled by sidebar
                }
                .keyboardShortcut("4", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(portService)
                .environment(databaseService)
        }
    }

    private func configureWindow() {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(TPTheme.background)
            window.isMovableByWindowBackground = true
            window.titleVisibility = .hidden

            // Traffic light positioning
            if let contentView = window.contentView {
                let titlebarView = contentView.superview?.subviews.first { view in
                    view.className == "NSTitlebarContainerView"
                }
                if let titlebar = titlebarView {
                    titlebar.frame.origin.y = window.frame.height - titlebar.frame.height - 8
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(PortService.self) private var portService
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval: Double = 5.0
    @AppStorage("showNotifications") private var showNotifications: Bool = true

    var body: some View {
        TabView {
            GeneralSettingsView(
                autoRefreshInterval: $autoRefreshInterval,
                showNotifications: $showNotifications
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @Binding var autoRefreshInterval: Double
    @Binding var showNotifications: Bool

    var body: some View {
        Form {
            Section {
                Picker("Auto-refresh interval", selection: $autoRefreshInterval) {
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                    Text("10 seconds").tag(10.0)
                    Text("30 seconds").tag(30.0)
                }

                Toggle("Show notifications for watchlist changes", isOn: $showNotifications)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 48))
                .foregroundColor(TPTheme.accent)

            Text("ThePort")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("A powerful port and process monitor for macOS")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Text("Made with Swift & SwiftUI")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
