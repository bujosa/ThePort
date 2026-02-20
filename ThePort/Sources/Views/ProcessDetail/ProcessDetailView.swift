import SwiftUI

struct ProcessDetailView: View {
    let process: ProcessInfo
    @Environment(PortService.self) private var portService
    @Environment(\.dismiss) private var dismiss

    @State private var showingKillConfirm = false
    @State private var isKilling = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()
                .background(TPTheme.border)

            ScrollView {
                VStack(spacing: TPTheme.spacingLarge) {
                    // Resource usage
                    resourceUsageSection

                    // Process info
                    processInfoSection

                    // Ports section
                    if !process.ports.isEmpty {
                        portsSection
                    }

                    // Command
                    commandSection
                }
                .padding()
            }

            Divider()
                .background(TPTheme.border)

            // Actions
            actionsView
        }
        .frame(width: 500, height: 600)
        .background(TPTheme.background)
        .alert("Kill Process", isPresented: $showingKillConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Force Kill", role: .destructive) {
                killProcess(force: true)
            }
            Button("Graceful Kill") {
                killProcess(force: false)
            }
        } message: {
            Text("How would you like to terminate \(process.name)?")
        }
    }

    private var headerView: some View {
        HStack(spacing: TPTheme.spacing) {
            ZStack {
                Circle()
                    .fill(process.statusColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "app.fill")
                    .font(.title2)
                    .foregroundColor(process.statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(process.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(TPTheme.textPrimary)
                    .lineLimit(1)

                Text("PID: \(process.pid) • \(process.user)")
                    .font(.subheadline)
                    .foregroundColor(TPTheme.textMuted)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(TPTheme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var resourceUsageSection: some View {
        VStack(alignment: .leading, spacing: TPTheme.spacing) {
            Text("Resource Usage")
                .font(.headline)
                .foregroundColor(TPTheme.textPrimary)

            HStack(spacing: TPTheme.spacing) {
                ResourceGauge(
                    title: "CPU",
                    value: process.cpuPercent,
                    formattedValue: process.formattedCPU,
                    color: TPTheme.cpuColor(process.cpuPercent)
                )

                ResourceGauge(
                    title: "Memory",
                    value: process.memoryPercent,
                    formattedValue: process.formattedMemory,
                    color: TPTheme.memoryColor(process.memoryPercent)
                )
            }
        }
    }

    private var processInfoSection: some View {
        VStack(alignment: .leading, spacing: TPTheme.spacing) {
            Text("Process Information")
                .font(.headline)
                .foregroundColor(TPTheme.textPrimary)

            VStack(spacing: 0) {
                InfoRow(label: "Process ID", value: "\(process.pid)")
                Divider().background(TPTheme.border)
                InfoRow(label: "User", value: process.user)
                Divider().background(TPTheme.border)
                InfoRow(label: "Threads", value: "\(process.threads > 0 ? "\(process.threads)" : "N/A")")
                Divider().background(TPTheme.border)
                InfoRow(label: "Open Ports", value: "\(process.ports.count)")
            }
            .cardStyle()
        }
    }

    private var portsSection: some View {
        VStack(alignment: .leading, spacing: TPTheme.spacing) {
            HStack {
                Text("Open Ports")
                    .font(.headline)
                    .foregroundColor(TPTheme.textPrimary)

                Spacer()

                Text("\(process.ports.count)")
                    .font(.subheadline)
                    .foregroundColor(TPTheme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(TPTheme.surface)
                    .cornerRadius(10)
            }

            VStack(spacing: 8) {
                ForEach(process.ports) { port in
                    HStack(spacing: TPTheme.spacing) {
                        Text("\(port.port)")
                            .font(.system(.body, design: .monospaced, weight: .medium))
                            .foregroundColor(TPTheme.textPrimary)
                            .frame(width: 60, alignment: .leading)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(TPTheme.stateColor(port.state))
                                .frame(width: 6, height: 6)
                            Text(port.state.label)
                                .font(.caption)
                                .foregroundColor(TPTheme.stateColor(port.state))
                        }
                        .frame(width: 100, alignment: .leading)

                        Text(port.protocol_)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(TPTheme.textSecondary)

                        Spacer()

                        Text(port.localAddress)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(TPTheme.textMuted)
                    }
                    .padding(TPTheme.spacingSmall)
                    .background(TPTheme.surface)
                    .cornerRadius(TPTheme.cornerRadius)
                }
            }
        }
    }

    private var commandSection: some View {
        VStack(alignment: .leading, spacing: TPTheme.spacing) {
            HStack {
                Text("Command")
                    .font(.headline)
                    .foregroundColor(TPTheme.textPrimary)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(process.command, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(TPTheme.textMuted)
                }
                .buttonStyle(.plain)
                .help("Copy command")
            }

            Text(process.command)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(TPTheme.textSecondary)
                .padding(TPTheme.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TPTheme.surface)
                .cornerRadius(TPTheme.cornerRadius)
                .textSelection(.enabled)
        }
    }

    private var actionsView: some View {
        HStack {
            Button {
                showingKillConfirm = true
            } label: {
                HStack(spacing: 6) {
                    if isKilling {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                    }
                    Text("Kill Process")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(TPTheme.error)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isKilling)

            Spacer()

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundColor(TPTheme.textSecondary)
        }
        .padding()
    }

    private func killProcess(force: Bool) {
        isKilling = true
        Task {
            let success: Bool
            if force {
                success = await portService.killProcess(pid: process.pid)
            } else {
                success = await portService.killProcessGracefully(pid: process.pid)
            }

            isKilling = false
            if success {
                dismiss()
            }
        }
    }
}

struct ResourceGauge: View {
    let title: String
    let value: Double
    let formattedValue: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(TPTheme.surface, lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: min(value / 100, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(formattedValue)
                        .font(.system(.body, design: .monospaced, weight: .bold))
                        .foregroundColor(TPTheme.textPrimary)
                }
            }

            Text(title)
                .font(.subheadline)
                .foregroundColor(TPTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(TPTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(TPTheme.textPrimary)
        }
        .padding(TPTheme.spacing)
    }
}
