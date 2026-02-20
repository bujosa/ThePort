import SwiftUI

struct PortRowView: View {
    let port: PortInfo
    let isInWatchlist: Bool
    let onKill: () -> Void
    let onToggleWatchlist: () -> Void

    @State private var isHovering = false
    @State private var showingKillConfirm = false

    var body: some View {
        HStack(spacing: TPTheme.spacing) {
            // Port number
            Text("\(port.port)")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundColor(TPTheme.textPrimary)
                .frame(width: 70, alignment: .leading)

            // State badge
            HStack(spacing: 4) {
                Image(systemName: port.state.icon)
                    .font(.caption)
                Text(port.state.label)
                    .font(.caption)
            }
            .foregroundColor(TPTheme.stateColor(port.state))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(TPTheme.stateColor(port.state).opacity(0.15))
            .cornerRadius(6)
            .frame(width: 100)

            // Process name
            VStack(alignment: .leading, spacing: 2) {
                Text(port.processName)
                    .font(.system(.body, weight: .medium))
                    .foregroundColor(TPTheme.textPrimary)
                    .lineLimit(1)

                Text("PID: \(port.pid) • \(port.user)")
                    .font(.caption)
                    .foregroundColor(TPTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Protocol
            Text(port.protocol_)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(TPTheme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(TPTheme.surface)
                .cornerRadius(4)

            // Address info
            VStack(alignment: .trailing, spacing: 2) {
                Text(port.localAddress)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(TPTheme.textSecondary)

                if port.foreignAddress != "*:*" {
                    Text("→ \(port.foreignAddress)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(TPTheme.textMuted)
                }
            }
            .frame(width: 150, alignment: .trailing)

            // Actions
            HStack(spacing: 8) {
                Button {
                    onToggleWatchlist()
                } label: {
                    Image(systemName: isInWatchlist ? "star.fill" : "star")
                        .foregroundColor(isInWatchlist ? TPTheme.warning : TPTheme.textMuted)
                }
                .buttonStyle(.plain)
                .help(isInWatchlist ? "Remove from Watchlist" : "Add to Watchlist")

                Button {
                    showingKillConfirm = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(TPTheme.error.opacity(isHovering ? 1 : 0.7))
                }
                .buttonStyle(.plain)
                .help("Kill Process")
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
        .alert("Kill Process", isPresented: $showingKillConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Kill", role: .destructive) {
                onKill()
            }
        } message: {
            Text("Are you sure you want to kill \(port.processName) (PID: \(port.pid))? This action cannot be undone.")
        }
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(TPTheme.textPrimary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(TPTheme.textMuted)
            }
        }
        .padding(TPTheme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search ports, processes..."

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(TPTheme.textMuted)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(TPTheme.textPrimary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(TPTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(TPTheme.surface)
        .cornerRadius(TPTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                .stroke(TPTheme.border, lineWidth: 1)
        )
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? TPTheme.accent : TPTheme.surface)
            .foregroundColor(isSelected ? .white : TPTheme.textSecondary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? TPTheme.accent : TPTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
