import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    @Environment(PortService.self) private var portService
    @Environment(DatabaseService.self) private var db
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "network")
                    .font(.title2)
                    .foregroundColor(themeManager.current.accent)

                Text("ThePort")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.current.textPrimary)

                Spacer()

                // Theme toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        themeManager.isDarkMode.toggle()
                    }
                } label: {
                    Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.current.textMuted)
                }
                .buttonStyle(.plain)
                .help(themeManager.isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode")
            }
            .padding()

            Divider()
                .background(TPTheme.border)

            // Navigation items
            ScrollView {
                VStack(spacing: 4) {
                    // Main section
                    SidebarSection(title: "MONITOR") {
                        ForEach(SidebarItem.allCases) { item in
                            SidebarRow(
                                item: item,
                                isSelected: selectedItem == item,
                                badge: badgeFor(item)
                            ) {
                                selectedItem = item
                            }
                        }
                    }

                    Divider()
                        .background(TPTheme.border)
                        .padding(.vertical, 8)

                    // Quick stats
                    SidebarSection(title: "QUICK STATS") {
                        QuickStatRow(
                            title: "Total Ports",
                            value: "\(portService.uniquePortCount())",
                            icon: "number",
                            color: TPTheme.accent
                        )

                        QuickStatRow(
                            title: "Processes",
                            value: "\(portService.uniqueProcessCount())",
                            icon: "app.fill",
                            color: TPTheme.accentSecondary
                        )

                        QuickStatRow(
                            title: "Watchlist",
                            value: "\(db.watchlistCount())",
                            icon: "star.fill",
                            color: TPTheme.warning
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, TPTheme.spacing)
            }

            Spacer()

            Divider()
                .background(TPTheme.border)

            // Footer
            HStack {
                if let lastRefresh = portService.lastRefresh {
                    Text("Updated \(lastRefresh.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(TPTheme.textMuted)
                }

                Spacer()

                Button {
                    portService.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(TPTheme.textMuted)
                }
                .buttonStyle(.plain)
                .help("Refresh")
            }
            .padding(TPTheme.spacing)
        }
        .frame(width: TPTheme.sidebarWidth)
        .background(themeManager.current.surface)
    }

    private func badgeFor(_ item: SidebarItem) -> Int? {
        switch item {
        case .allPorts:
            return portService.uniquePortCount()
        case .listening:
            return portService.listeningCount()
        case .established:
            return portService.establishedCount()
        case .watchlist:
            let watchlistPorts = db.watchlistPorts()
            return portService.ports.filter { watchlistPorts.contains($0.port) }.count
        }
    }
}

struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(TPTheme.textMuted)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

            content()
        }
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : item.color)
                    .frame(width: 20)

                Text(item.rawValue)
                    .font(.system(.subheadline, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : TPTheme.textPrimary)

                Spacer()

                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : TPTheme.textMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.2) : TPTheme.card)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? TPTheme.accent : (isHovering ? TPTheme.card : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

struct QuickStatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(.caption)
                .foregroundColor(TPTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundColor(TPTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
