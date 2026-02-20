import SwiftUI

struct ProcessRowView: View {
    let process: ProcessInfo
    let onKill: () -> Void
    let onSelect: () -> Void

    @State private var isHovering = false
    @State private var showingKillConfirm = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: TPTheme.spacing) {
                // Process icon
                ZStack {
                    Circle()
                        .fill(process.statusColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: "app.fill")
                        .foregroundColor(process.statusColor)
                }

                // Process info
                VStack(alignment: .leading, spacing: 4) {
                    Text(process.name)
                        .font(.system(.body, weight: .medium))
                        .foregroundColor(TPTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text("PID: \(process.pid)")
                            .font(.caption)
                            .foregroundColor(TPTheme.textMuted)

                        Text("•")
                            .foregroundColor(TPTheme.textMuted)

                        Text(process.user)
                            .font(.caption)
                            .foregroundColor(TPTheme.textMuted)

                        if !process.ports.isEmpty {
                            Text("•")
                                .foregroundColor(TPTheme.textMuted)

                            HStack(spacing: 2) {
                                Image(systemName: "network")
                                    .font(.caption2)
                                Text("\(process.ports.count) ports")
                                    .font(.caption)
                            }
                            .foregroundColor(TPTheme.accent)
                        }
                    }
                }

                Spacer()

                // CPU usage
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.formattedCPU)
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .foregroundColor(TPTheme.cpuColor(process.cpuPercent))

                    Text("CPU")
                        .font(.caption2)
                        .foregroundColor(TPTheme.textMuted)
                }
                .frame(width: 60)

                // Memory usage
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.formattedMemory)
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .foregroundColor(TPTheme.memoryColor(process.memoryPercent))

                    Text("Memory")
                        .font(.caption2)
                        .foregroundColor(TPTheme.textMuted)
                }
                .frame(width: 80)

                // Kill button
                Button {
                    showingKillConfirm = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(TPTheme.error.opacity(isHovering ? 1 : 0.5))
                }
                .buttonStyle(.plain)
                .help("Kill Process")
                .opacity(isHovering ? 1 : 0)
            }
            .padding(TPTheme.spacing)
            .background(isHovering ? TPTheme.cardHover : TPTheme.card)
            .cornerRadius(TPTheme.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: TPTheme.cardCornerRadius)
                    .stroke(TPTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
            Text("Are you sure you want to kill \(process.name) (PID: \(process.pid))? This action cannot be undone.")
        }
    }
}

struct MiniProcessCard: View {
    let process: ProcessInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(process.name)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(TPTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("PID: \(process.pid)")
                    .font(.caption)
                    .foregroundColor(TPTheme.textMuted)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(TPTheme.cpuColor(process.cpuPercent))
                        .frame(width: 6, height: 6)
                    Text(process.formattedCPU)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(TPTheme.textSecondary)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(TPTheme.memoryColor(process.memoryPercent))
                        .frame(width: 6, height: 6)
                    Text(process.formattedMemory)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(TPTheme.textSecondary)
                }
            }
        }
        .padding(TPTheme.spacingSmall)
        .background(TPTheme.surface)
        .cornerRadius(TPTheme.cornerRadius)
    }
}
