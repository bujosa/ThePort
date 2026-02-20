import Foundation
import SwiftUI
import GRDB

// MARK: - Port Information

struct PortInfo: Identifiable, Hashable, Sendable {
    let id: String
    let port: Int
    let pid: Int
    let processName: String
    let user: String
    let protocol_: String
    let localAddress: String
    let foreignAddress: String
    let state: PortState

    init(port: Int, pid: Int, processName: String, user: String, protocol_: String, localAddress: String, foreignAddress: String, state: PortState) {
        self.id = "\(port)-\(pid)-\(protocol_)"
        self.port = port
        self.pid = pid
        self.processName = processName
        self.user = user
        self.protocol_ = protocol_
        self.localAddress = localAddress
        self.foreignAddress = foreignAddress
        self.state = state
    }
}

enum PortState: String, CaseIterable, Sendable {
    case listen = "LISTEN"
    case established = "ESTABLISHED"
    case timeWait = "TIME_WAIT"
    case closeWait = "CLOSE_WAIT"
    case synSent = "SYN_SENT"
    case synReceived = "SYN_RECEIVED"
    case finWait1 = "FIN_WAIT_1"
    case finWait2 = "FIN_WAIT_2"
    case closing = "CLOSING"
    case lastAck = "LAST_ACK"
    case closed = "CLOSED"
    case unknown = "UNKNOWN"

    var label: String {
        switch self {
        case .listen: return "Listening"
        case .established: return "Established"
        case .timeWait: return "Time Wait"
        case .closeWait: return "Close Wait"
        case .synSent: return "SYN Sent"
        case .synReceived: return "SYN Received"
        case .finWait1: return "FIN Wait 1"
        case .finWait2: return "FIN Wait 2"
        case .closing: return "Closing"
        case .lastAck: return "Last ACK"
        case .closed: return "Closed"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .listen: return .green
        case .established: return .blue
        case .timeWait, .finWait1, .finWait2: return .orange
        case .closeWait, .closing, .lastAck: return .yellow
        case .closed: return .gray
        case .synSent, .synReceived: return .purple
        case .unknown: return .secondary
        }
    }

    var icon: String {
        switch self {
        case .listen: return "antenna.radiowaves.left.and.right"
        case .established: return "link"
        case .timeWait, .finWait1, .finWait2: return "clock"
        case .closeWait, .closing, .lastAck: return "xmark.circle"
        case .closed: return "circle.slash"
        case .synSent, .synReceived: return "arrow.triangle.2.circlepath"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Process Information

struct ProcessInfo: Identifiable, Hashable, Sendable {
    let id: Int // PID
    let pid: Int
    let name: String
    let user: String
    let cpuPercent: Double
    let memoryPercent: Double
    let memoryMB: Double
    let threads: Int
    let startTime: String
    let command: String
    let ports: [PortInfo]

    init(pid: Int, name: String, user: String, cpuPercent: Double = 0, memoryPercent: Double = 0, memoryMB: Double = 0, threads: Int = 0, startTime: String = "", command: String = "", ports: [PortInfo] = []) {
        self.id = pid
        self.pid = pid
        self.name = name
        self.user = user
        self.cpuPercent = cpuPercent
        self.memoryPercent = memoryPercent
        self.memoryMB = memoryMB
        self.threads = threads
        self.startTime = startTime
        self.command = command
        self.ports = ports
    }

    var formattedCPU: String {
        String(format: "%.1f%%", cpuPercent)
    }

    var formattedMemory: String {
        if memoryMB >= 1024 {
            return String(format: "%.1f GB", memoryMB / 1024)
        }
        return String(format: "%.1f MB", memoryMB)
    }

    var statusColor: Color {
        if cpuPercent > 80 { return .red }
        if cpuPercent > 50 { return .orange }
        if cpuPercent > 20 { return .yellow }
        return .green
    }
}

// MARK: - Watchlist Item (persisted)

struct WatchlistItem: Identifiable, Hashable, Sendable, Codable, FetchableRecord, PersistableRecord {
    var id: UUID
    var port: Int
    var name: String
    var description_: String
    var notifyOnChange: Bool
    var createdAt: Date
    var lastSeenActive: Date?
    var priority: WatchlistPriority

    static let databaseTableName = "watchlist_items"

    static func new(port: Int, name: String, description_: String = "", priority: WatchlistPriority = .medium) -> WatchlistItem {
        WatchlistItem(
            id: UUID(),
            port: port,
            name: name,
            description_: description_,
            notifyOnChange: true,
            createdAt: Date(),
            lastSeenActive: nil,
            priority: priority
        )
    }
}

enum WatchlistPriority: String, CaseIterable, Sendable, Codable, DatabaseValueConvertible {
    case low
    case medium
    case high
    case critical

    var label: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "equal.circle"
        case .high: return "arrow.up.circle"
        case .critical: return "exclamationmark.triangle"
        }
    }

    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Filter and Sort Options

enum PortFilter: String, CaseIterable {
    case all = "All Ports"
    case listening = "Listening"
    case established = "Established"
    case watchlist = "Watchlist"

    var icon: String {
        switch self {
        case .all: return "network"
        case .listening: return "antenna.radiowaves.left.and.right"
        case .established: return "link"
        case .watchlist: return "star.fill"
        }
    }
}

enum SortOption: String, CaseIterable {
    case port = "Port"
    case process = "Process"
    case cpu = "CPU"
    case memory = "Memory"
    case state = "State"

    var icon: String {
        switch self {
        case .port: return "number"
        case .process: return "app"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .state: return "circle.grid.2x2"
        }
    }
}

// MARK: - Navigation

enum NavigationDestination: Hashable {
    case portList
    case watchlist
    case processDetail(ProcessInfo)
    case settings
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case allPorts = "All Ports"
    case listening = "Listening"
    case established = "Established"
    case watchlist = "Watchlist"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .allPorts: return "network"
        case .listening: return "antenna.radiowaves.left.and.right"
        case .established: return "link"
        case .watchlist: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .allPorts: return .blue
        case .listening: return .green
        case .established: return .orange
        case .watchlist: return .yellow
        }
    }
}
