import SwiftUI

struct ContentView: View {
    @Environment(PortService.self) private var portService
    @Environment(DatabaseService.self) private var db
    @State private var themeManager = ThemeManager.shared

    @State private var selectedItem: SidebarItem = .allPorts
    @State private var selectedProcess: ProcessInfo?
    @State private var showingSplash = true

    var body: some View {
        ZStack {
            if showingSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                mainView
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onAppear {
            Task {
                await db.initialize()
                portService.startAutoRefresh(interval: 5.0)

                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.easeInOut(duration: 0.5)) {
                    showingSplash = false
                }
            }
        }
    }

    private var mainView: some View {
        HSplitView {
            SidebarView(selectedItem: $selectedItem)
                .frame(minWidth: TPTheme.sidebarWidth, maxWidth: TPTheme.sidebarWidth)

            mainContent
                .frame(minWidth: 600)
        }
        .background(themeManager.current.background)
        .sheet(item: $selectedProcess) { process in
            ProcessDetailView(process: process)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedItem {
        case .allPorts:
            PortListView(filter: .all)
        case .listening:
            PortListView(filter: .listening)
        case .established:
            PortListView(filter: .established)
        case .watchlist:
            WatchlistView()
        }
    }
}

struct SplashView: View {
    @State private var themeManager = ThemeManager.shared
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            themeManager.current.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [themeManager.current.accent, themeManager.current.accentSecondary, themeManager.current.accent]),
                                center: .center
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(rotation))

                    // Icon
                    Image(systemName: "network")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(themeManager.current.accent)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 8) {
                    Text("ThePort")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.current.textPrimary)

                    Text("Port & Process Monitor")
                        .font(.subheadline)
                        .foregroundColor(themeManager.current.textMuted)
                }
                .opacity(opacity)

                ProgressView()
                    .scaleEffect(0.8)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(PortService())
        .environment(DatabaseService())
}
