import SwiftUI

struct PortListView: View {
    let filter: PortFilter
    @Environment(PortService.self) private var portService
    @Environment(DatabaseService.self) private var db

    @State private var searchText = ""
    @State private var sortOption: SortOption = .port
    @State private var sortAscending = true
    @State private var showingAddToWatchlist = false
    @State private var selectedPortForWatchlist: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()
                .background(TPTheme.border)

            // Stats bar
            statsBar

            Divider()
                .background(TPTheme.border)

            // Toolbar
            toolbarView

            // Error message
            if let error = portService.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(TPTheme.error)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(TPTheme.error)
                    Spacer()
                }
                .padding()
                .background(TPTheme.error.opacity(0.1))
            }

            // Port list
            if portService.isLoading && portService.ports.isEmpty {
                loadingView
            } else if filteredPorts.isEmpty {
                emptyView
            } else {
                portListContent
            }
        }
        .background(TPTheme.background)
        .sheet(isPresented: $showingAddToWatchlist) {
            AddToWatchlistSheet(
                isPresented: $showingAddToWatchlist,
                initialPort: selectedPortForWatchlist
            ) { port, name, description, priority in
                Task {
                    await db.addToWatchlist(port: port, name: name, description: description, priority: priority)
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(filter == .all ? "All Ports" : filter.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(TPTheme.textPrimary)

                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundColor(TPTheme.textMuted)

                Text("Raw: \(portService.ports.count) ports loaded")
                    .font(.caption2)
                    .foregroundColor(TPTheme.textMuted)
            }

            Spacer()

            // Refresh indicator
            if portService.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 8)
            }

            Button {
                portService.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundColor(TPTheme.textSecondary)
            .help("Refresh")
        }
        .padding()
    }

    private var headerSubtitle: String {
        let count = filteredPorts.count
        switch filter {
        case .all:
            return "\(count) active port\(count == 1 ? "" : "s")"
        case .listening:
            return "\(count) port\(count == 1 ? "" : "s") listening for connections"
        case .established:
            return "\(count) established connection\(count == 1 ? "" : "s")"
        case .watchlist:
            return "\(count) watched port\(count == 1 ? "" : "s") currently active"
        }
    }

    private var statsBar: some View {
        HStack(spacing: TPTheme.spacing) {
            StatBadge(
                title: "Total Ports",
                value: "\(portService.uniquePortCount())",
                icon: "number",
                color: TPTheme.accent
            )

            StatBadge(
                title: "Listening",
                value: "\(portService.listeningCount())",
                icon: "antenna.radiowaves.left.and.right",
                color: TPTheme.success
            )

            StatBadge(
                title: "Established",
                value: "\(portService.establishedCount())",
                icon: "link",
                color: TPTheme.info
            )

            StatBadge(
                title: "Processes",
                value: "\(portService.uniqueProcessCount())",
                icon: "app.fill",
                color: TPTheme.accentSecondary
            )
        }
        .padding()
    }

    private var toolbarView: some View {
        HStack(spacing: TPTheme.spacing) {
            SearchBar(text: $searchText)
                .frame(maxWidth: 300)

            Spacer()

            // Sort options
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        if sortOption == option {
                            sortAscending.toggle()
                        } else {
                            sortOption = option
                            sortAscending = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: option.icon)
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Sort")
                }
                .font(.subheadline)
                .foregroundColor(TPTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(TPTheme.surface)
                .cornerRadius(8)
            }

            // Add to watchlist button
            if filter != .watchlist {
                Button {
                    selectedPortForWatchlist = nil
                    showingAddToWatchlist = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add to Watchlist")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(TPTheme.accent)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: TPTheme.spacing) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Scanning ports...")
                .font(.subheadline)
                .foregroundColor(TPTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: TPTheme.spacing) {
            Image(systemName: "network.slash")
                .font(.system(size: 48))
                .foregroundColor(TPTheme.textMuted)

            Text(emptyMessage)
                .font(.headline)
                .foregroundColor(TPTheme.textSecondary)

            Text(emptySubtitle)
                .font(.subheadline)
                .foregroundColor(TPTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessage: String {
        if !searchText.isEmpty {
            return "No results found"
        }
        switch filter {
        case .all:
            return "No active ports"
        case .listening:
            return "No listening ports"
        case .established:
            return "No established connections"
        case .watchlist:
            return "No watched ports active"
        }
    }

    private var emptySubtitle: String {
        if !searchText.isEmpty {
            return "Try adjusting your search"
        }
        return "Ports will appear here when active"
    }

    private var portListContent: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(sortedPorts) { port in
                    PortRowView(
                        port: port,
                        isInWatchlist: db.isInWatchlist(port: port.port),
                        onKill: {
                            Task {
                                _ = await portService.killProcess(pid: port.pid)
                            }
                        },
                        onToggleWatchlist: {
                            if db.isInWatchlist(port: port.port) {
                                Task {
                                    await db.removeFromWatchlist(port: port.port)
                                }
                            } else {
                                selectedPortForWatchlist = port.port
                                showingAddToWatchlist = true
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    private var filteredPorts: [PortInfo] {
        portService.filteredPorts(
            filter: filter,
            searchText: searchText,
            watchlistPorts: db.watchlistPorts()
        )
    }

    private var sortedPorts: [PortInfo] {
        let ports = filteredPorts

        return ports.sorted { a, b in
            let result: Bool
            switch sortOption {
            case .port:
                result = a.port < b.port
            case .process:
                result = a.processName.lowercased() < b.processName.lowercased()
            case .cpu, .memory:
                // Sort by port number as fallback (CPU/memory requires additional process lookup)
                result = a.port < b.port
            case .state:
                result = a.state.rawValue < b.state.rawValue
            }
            return sortAscending ? result : !result
        }
    }
}
