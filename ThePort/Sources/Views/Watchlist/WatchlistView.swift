import SwiftUI

struct WatchlistView: View {
    @Environment(PortService.self) private var portService
    @Environment(DatabaseService.self) private var db

    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var editingItem: WatchlistItem?
    @State private var filterPriority: WatchlistPriority?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()
                .background(TPTheme.border)

            // Stats
            statsView

            Divider()
                .background(TPTheme.border)

            // Toolbar
            toolbarView

            // Content
            if db.watchlistItems.isEmpty {
                emptyView
            } else if filteredItems.isEmpty {
                noResultsView
            } else {
                watchlistContent
            }
        }
        .background(TPTheme.background)
        .sheet(isPresented: $showingAddSheet) {
            AddToWatchlistSheet(
                isPresented: $showingAddSheet,
                initialPort: nil
            ) { port, name, description, priority in
                Task {
                    await db.addToWatchlist(port: port, name: name, description: description, priority: priority)
                }
            }
        }
        .sheet(item: $editingItem) { item in
            EditWatchlistSheet(
                item: item,
                isPresented: Binding(
                    get: { editingItem != nil },
                    set: { if !$0 { editingItem = nil } }
                )
            ) { updatedItem in
                Task {
                    await db.updateWatchlistItem(updatedItem)
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Watchlist")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(TPTheme.textPrimary)

                Text("\(db.watchlistItems.count) port\(db.watchlistItems.count == 1 ? "" : "s") being monitored")
                    .font(.subheadline)
                    .foregroundColor(TPTheme.textMuted)
            }

            Spacer()

            Button {
                showingAddSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add Port")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(TPTheme.accent)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var statsView: some View {
        HStack(spacing: TPTheme.spacing) {
            WatchlistStatCard(
                title: "Active",
                value: "\(activeCount)",
                subtitle: "Currently in use",
                icon: "checkmark.circle.fill",
                color: TPTheme.success
            )

            WatchlistStatCard(
                title: "Inactive",
                value: "\(inactiveCount)",
                subtitle: "Not in use",
                icon: "moon.fill",
                color: TPTheme.textMuted
            )

            WatchlistStatCard(
                title: "Critical",
                value: "\(db.criticalCount())",
                subtitle: "High priority",
                icon: "exclamationmark.triangle.fill",
                color: TPTheme.error
            )

            WatchlistStatCard(
                title: "Total",
                value: "\(db.watchlistItems.count)",
                subtitle: "Monitored ports",
                icon: "star.fill",
                color: TPTheme.warning
            )
        }
        .padding()
    }

    private var toolbarView: some View {
        HStack(spacing: TPTheme.spacing) {
            SearchBar(text: $searchText, placeholder: "Search watchlist...")
                .frame(maxWidth: 300)

            Spacer()

            // Priority filter
            HStack(spacing: 4) {
                FilterChip(
                    title: "All",
                    icon: "line.3.horizontal.decrease.circle",
                    isSelected: filterPriority == nil
                ) {
                    filterPriority = nil
                }

                ForEach(WatchlistPriority.allCases, id: \.self) { priority in
                    FilterChip(
                        title: priority.label,
                        icon: priority.icon,
                        isSelected: filterPriority == priority
                    ) {
                        filterPriority = priority
                    }
                }
            }
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: TPTheme.spacingLarge) {
            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundColor(TPTheme.textMuted)

            VStack(spacing: 8) {
                Text("No Watched Ports")
                    .font(.headline)
                    .foregroundColor(TPTheme.textSecondary)

                Text("Add ports to your watchlist to monitor them")
                    .font(.subheadline)
                    .foregroundColor(TPTheme.textMuted)
            }

            Button {
                showingAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Port")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(TPTheme.accent)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: TPTheme.spacing) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(TPTheme.textMuted)

            Text("No matching ports")
                .font(.headline)
                .foregroundColor(TPTheme.textSecondary)

            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(TPTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var watchlistContent: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredItems) { item in
                    let portInfo = portService.ports.first { $0.port == item.port }
                    let isActive = portInfo != nil

                    WatchlistRowView(
                        item: item,
                        isActive: isActive,
                        currentPort: portInfo,
                        onEdit: {
                            editingItem = item
                        },
                        onDelete: {
                            Task {
                                await db.removeFromWatchlist(item)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    private var filteredItems: [WatchlistItem] {
        var items = db.watchlistItems

        if let priority = filterPriority {
            items = items.filter { $0.priority == priority }
        }

        if !searchText.isEmpty {
            let search = searchText.lowercased()
            items = items.filter {
                $0.name.lowercased().contains(search) ||
                $0.description_.lowercased().contains(search) ||
                String($0.port).contains(search)
            }
        }

        return items.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    private var activeCount: Int {
        let watchlistPorts = Set(db.watchlistItems.map { $0.port })
        return portService.ports.filter { watchlistPorts.contains($0.port) }.count
    }

    private var inactiveCount: Int {
        db.watchlistItems.count - activeCount
    }
}

struct WatchlistStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()

                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(TPTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(TPTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(TPTheme.textMuted)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct EditWatchlistSheet: View {
    let item: WatchlistItem
    @Binding var isPresented: Bool
    let onSave: (WatchlistItem) -> Void

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var priority: WatchlistPriority = .medium
    @State private var notifyOnChange: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Watchlist Item")
                    .font(.headline)
                    .foregroundColor(TPTheme.textPrimary)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(TPTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(TPTheme.surface)

            Divider()
                .background(TPTheme.border)

            // Form
            VStack(spacing: TPTheme.spacing) {
                // Port (read-only)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Port Number")
                        .font(.subheadline)
                        .foregroundColor(TPTheme.textSecondary)

                    Text("\(item.port)")
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .foregroundColor(TPTheme.textPrimary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TPTheme.surface.opacity(0.5))
                        .cornerRadius(TPTheme.cornerRadius)
                }

                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(TPTheme.textSecondary)

                    TextField("My Service", text: $name)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(TPTheme.surface)
                        .cornerRadius(TPTheme.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                                .stroke(TPTheme.border, lineWidth: 1)
                        )
                }

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(TPTheme.textSecondary)

                    TextField("Description", text: $description)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(TPTheme.surface)
                        .cornerRadius(TPTheme.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                                .stroke(TPTheme.border, lineWidth: 1)
                        )
                }

                // Priority
                VStack(alignment: .leading, spacing: 4) {
                    Text("Priority")
                        .font(.subheadline)
                        .foregroundColor(TPTheme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(WatchlistPriority.allCases, id: \.self) { p in
                            Button {
                                priority = p
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: p.icon)
                                        .font(.caption)
                                    Text(p.label)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(priority == p ? TPTheme.priorityColor(p) : TPTheme.surface)
                                .foregroundColor(priority == p ? .white : TPTheme.textSecondary)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Notifications toggle
                Toggle(isOn: $notifyOnChange) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notify on Change")
                            .font(.subheadline)
                            .foregroundColor(TPTheme.textPrimary)

                        Text("Get notified when this port becomes active/inactive")
                            .font(.caption)
                            .foregroundColor(TPTheme.textMuted)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding()

            Divider()
                .background(TPTheme.border)

            // Actions
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(TPTheme.textSecondary)

                Spacer()

                Button {
                    var updated = item
                    updated.name = name
                    updated.description_ = description
                    updated.priority = priority
                    updated.notifyOnChange = notifyOnChange
                    onSave(updated)
                    isPresented = false
                } label: {
                    Text("Save Changes")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(TPTheme.accent)
                .disabled(name.isEmpty)
            }
            .padding()
            .background(TPTheme.surface)
        }
        .frame(width: 400)
        .background(TPTheme.background)
        .cornerRadius(TPTheme.cardCornerRadius)
        .onAppear {
            name = item.name
            description = item.description_
            priority = item.priority
            notifyOnChange = item.notifyOnChange
        }
    }
}
