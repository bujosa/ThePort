import SwiftUI

struct WatchlistRowView: View {
    let item: WatchlistItem
    let isActive: Bool
    let currentPort: PortInfo?
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        HStack(spacing: TPTheme.spacing) {
            // Priority indicator
            Circle()
                .fill(TPTheme.priorityColor(item.priority))
                .frame(width: 8, height: 8)

            // Port number
            Text("\(item.port)")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundColor(TPTheme.textPrimary)
                .frame(width: 70, alignment: .leading)

            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(isActive ? TPTheme.success : TPTheme.textMuted)
                    .frame(width: 8, height: 8)
                Text(isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(isActive ? TPTheme.success : TPTheme.textMuted)
            }
            .frame(width: 80)

            // Name and description
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(.body, weight: .medium))
                    .foregroundColor(TPTheme.textPrimary)
                    .lineLimit(1)

                if !item.description_.isEmpty {
                    Text(item.description_)
                        .font(.caption)
                        .foregroundColor(TPTheme.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Current process info
            if let port = currentPort {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(port.processName)
                        .font(.caption)
                        .foregroundColor(TPTheme.textSecondary)

                    Text("PID: \(port.pid)")
                        .font(.caption2)
                        .foregroundColor(TPTheme.textMuted)
                }
                .frame(width: 120)
            } else {
                Text("-")
                    .font(.caption)
                    .foregroundColor(TPTheme.textMuted)
                    .frame(width: 120)
            }

            // Priority badge
            HStack(spacing: 4) {
                Image(systemName: item.priority.icon)
                    .font(.caption2)
                Text(item.priority.label)
                    .font(.caption)
            }
            .foregroundColor(TPTheme.priorityColor(item.priority))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(TPTheme.priorityColor(item.priority).opacity(0.15))
            .cornerRadius(6)

            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(TPTheme.textMuted)
                }
                .buttonStyle(.plain)
                .help("Edit")

                Button {
                    showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(TPTheme.error.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Remove from Watchlist")
            }
            .opacity(isHovering ? 1 : 0.5)
        }
        .padding(.horizontal, TPTheme.spacing)
        .padding(.vertical, TPTheme.spacingSmall)
        .background(isHovering ? TPTheme.cardHover : Color.clear)
        .cornerRadius(TPTheme.cornerRadius)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .alert("Remove from Watchlist", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to remove port \(item.port) (\(item.name)) from your watchlist?")
        }
    }
}

struct AddToWatchlistSheet: View {
    @Binding var isPresented: Bool
    let initialPort: Int?
    let onSave: (Int, String, String, WatchlistPriority) -> Void

    @State private var port: String = ""
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var priority: WatchlistPriority = .medium

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add to Watchlist")
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
                // Port
                VStack(alignment: .leading, spacing: 4) {
                    Text("Port Number")
                        .font(.subheadline)
                        .foregroundColor(TPTheme.textSecondary)

                    TextField("8080", text: $port)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(TPTheme.surface)
                        .cornerRadius(TPTheme.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                                .stroke(TPTheme.border, lineWidth: 1)
                        )
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
                    Text("Description (optional)")
                        .font(.subheadline)
                        .foregroundColor(TPTheme.textSecondary)

                    TextField("Development server", text: $description)
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
                    if let portNum = Int(port), !name.isEmpty {
                        onSave(portNum, name, description, priority)
                        isPresented = false
                    }
                } label: {
                    Text("Add to Watchlist")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(TPTheme.accent)
                .disabled(Int(port) == nil || name.isEmpty)
            }
            .padding()
            .background(TPTheme.surface)
        }
        .frame(width: 400)
        .background(TPTheme.background)
        .cornerRadius(TPTheme.cardCornerRadius)
        .onAppear {
            if let p = initialPort {
                port = String(p)
            }
        }
    }
}
