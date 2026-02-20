import Foundation
import SwiftUI

@MainActor
@Observable
final class PortService {
    var ports: [PortInfo] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var lastRefresh: Date?

    private var refreshTimer: Timer?
    private var processCache: [Int: (pid: Int, name: String, user: String)] = [:]

    init() {}

    // MARK: - Public Methods

    func startAutoRefresh(interval: TimeInterval = 5.0) {
        stopAutoRefresh()
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() {
        Task {
            await fetchAllData()
        }
    }

    func killProcess(pid: Int) async -> Bool {
        do {
            let output = try await runCommand("/bin/kill", arguments: ["-9", String(pid)])
            if output.isEmpty || !output.contains("No such process") {
                refresh()
                return true
            }
            return false
        } catch {
            errorMessage = "Failed to kill process: \(error.localizedDescription)"
            return false
        }
    }

    func killProcessGracefully(pid: Int) async -> Bool {
        do {
            let output = try await runCommand("/bin/kill", arguments: ["-15", String(pid)])
            if output.isEmpty || !output.contains("No such process") {
                try? await Task.sleep(nanoseconds: 500_000_000)
                refresh()
                return true
            }
            return false
        } catch {
            errorMessage = "Failed to kill process: \(error.localizedDescription)"
            return false
        }
    }

    func getProcessDetails(pid: Int) async -> ProcessInfo? {
        do {
            let psOutput = try await runCommand("/bin/ps", arguments: ["-p", String(pid), "-o", "pid=,user=,%cpu=,%mem=,rss=,nlwp=,lstart=,command="])

            let lines = psOutput.split(separator: "\n")
            guard let line = lines.first else { return nil }

            let components = line.split(separator: " ", maxSplits: 7, omittingEmptySubsequences: true)
            guard components.count >= 7 else { return nil }

            let processPorts = ports.filter { $0.pid == pid }

            return ProcessInfo(
                pid: pid,
                name: String(components.last ?? ""),
                user: String(components[1]),
                cpuPercent: Double(components[2]) ?? 0,
                memoryPercent: Double(components[3]) ?? 0,
                memoryMB: (Double(components[4]) ?? 0) / 1024,
                threads: Int(components[5]) ?? 0,
                startTime: "",
                command: String(components.last ?? ""),
                ports: processPorts
            )
        } catch {
            return nil
        }
    }

    // MARK: - Private Methods

    private func fetchAllData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get ports from netstat
            var fetchedPorts = try await fetchPorts()

            // Enrich with process info from lsof
            let processMap = try await fetchProcessMap()
            fetchedPorts = fetchedPorts.map { port in
                if let processInfo = processMap[port.port] {
                    return PortInfo(
                        port: port.port,
                        pid: processInfo.pid,
                        processName: processInfo.name,
                        user: processInfo.user,
                        protocol_: port.protocol_,
                        localAddress: port.localAddress,
                        foreignAddress: port.foreignAddress,
                        state: port.state
                    )
                }
                return port
            }

            self.ports = fetchedPorts
            self.lastRefresh = Date()
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func fetchProcessMap() async throws -> [Int: (pid: Int, name: String, user: String)] {
        let output = try await runCommand("/usr/sbin/lsof", arguments: ["-i", "-P", "-n", "-F", "pcuLn"])

        var processMap: [Int: (pid: Int, name: String, user: String)] = [:]
        var currentPid = 0
        var currentName = ""
        var currentUser = ""

        for line in output.split(separator: "\n") {
            let lineStr = String(line)
            if lineStr.hasPrefix("p") {
                currentPid = Int(lineStr.dropFirst()) ?? 0
            } else if lineStr.hasPrefix("c") {
                currentName = String(lineStr.dropFirst())
            } else if lineStr.hasPrefix("u") {
                currentUser = String(lineStr.dropFirst())
            } else if lineStr.hasPrefix("n") {
                // n = name field contains address:port
                let addr = String(lineStr.dropFirst())
                if let port = extractPortFromLsof(addr) {
                    processMap[port] = (pid: currentPid, name: currentName, user: currentUser)
                }
            }
        }

        return processMap
    }

    private func extractPortFromLsof(_ address: String) -> Int? {
        // Format: "IP:PORT" or "[IPv6]:PORT" or "*:PORT"
        if address.contains("]:") {
            // IPv6 format [::1]:8080
            if let idx = address.lastIndex(of: ":") {
                return Int(address[address.index(after: idx)...])
            }
        } else if let idx = address.lastIndex(of: ":") {
            return Int(address[address.index(after: idx)...])
        }
        return nil
    }

    private func fetchPorts() async throws -> [PortInfo] {
        // Use netstat which is faster and more reliable
        let tcpOutput = try await runCommand("/usr/sbin/netstat", arguments: ["-an", "-p", "tcp"])

        var portInfos: [PortInfo] = []
        portInfos.append(contentsOf: parseNetstatOutput(tcpOutput, proto: "TCP"))

        return portInfos.sorted { $0.port < $1.port }
    }

    private func parseNetstatOutput(_ output: String, proto: String) -> [PortInfo] {
        var portInfos: [PortInfo] = []
        let lines = output.split(separator: "\n").dropFirst(2)

        for line in lines {
            let columns = String(line).split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard columns.count >= 6 else { continue }

            // Format: Proto Recv-Q Send-Q Local Foreign State
            let localAddress = columns[3]   // e.g., "10.0.0.215.61794"
            let foreignAddress = columns[4]
            let stateStr = columns[5]

            // Extract port from "IP.PORT" format (last component after last dot)
            let port = extractPortFromNetstat(localAddress)
            let state = parseState(stateStr)

            if port > 0 {
                let info = PortInfo(
                    port: port,
                    pid: 0,
                    processName: "-",
                    user: NSUserName(),
                    protocol_: proto,
                    localAddress: localAddress,
                    foreignAddress: foreignAddress,
                    state: state
                )
                portInfos.append(info)
            }
        }

        return portInfos
    }

    private func extractPortFromNetstat(_ address: String) -> Int {
        // Format: "10.0.0.215.61794" or "*.443" or IPv6
        if address.hasPrefix("*") {
            // *.PORT format
            let parts = address.split(separator: ".")
            if let last = parts.last {
                return Int(last) ?? 0
            }
        } else if address.contains("[") {
            // IPv6 format
            if let lastDot = address.lastIndex(of: ".") {
                let portStr = address[address.index(after: lastDot)...]
                return Int(portStr) ?? 0
            }
        } else {
            // IPv4 format: last dot-separated component is port
            if let lastDot = address.lastIndex(of: ".") {
                let portStr = address[address.index(after: lastDot)...]
                return Int(portStr) ?? 0
            }
        }
        return 0
    }

    private func fetchProcesses() async throws -> [ProcessInfo] {
        let output = try await runCommand("/bin/ps", arguments: ["aux"])

        var processInfos: [ProcessInfo] = []
        let lines = output.split(separator: "\n").dropFirst()

        for line in lines {
            let columns = line.split(separator: " ", maxSplits: 10, omittingEmptySubsequences: true)
            guard columns.count >= 11 else { continue }

            let user = String(columns[0])
            let pid = Int(columns[1]) ?? 0
            let cpu = Double(columns[2]) ?? 0
            let mem = Double(columns[3]) ?? 0
            let rss = (Double(columns[5]) ?? 0) / 1024

            let commandParts = columns[10...]
            let command = commandParts.joined(separator: " ")
            let name = command.split(separator: "/").last.map(String.init) ?? command

            let info = ProcessInfo(
                pid: pid,
                name: name,
                user: user,
                cpuPercent: cpu,
                memoryPercent: mem,
                memoryMB: rss,
                command: command
            )
            processInfos.append(info)
        }

        return processInfos
    }

    private func enrichProcessesWithPorts(_ processes: [ProcessInfo], ports: [PortInfo]) -> [ProcessInfo] {
        return processes.map { process in
            let processPorts = ports.filter { $0.pid == process.pid }
            return ProcessInfo(
                pid: process.pid,
                name: process.name,
                user: process.user,
                cpuPercent: process.cpuPercent,
                memoryPercent: process.memoryPercent,
                memoryMB: process.memoryMB,
                threads: process.threads,
                startTime: process.startTime,
                command: process.command,
                ports: processPorts
            )
        }
    }

    private func extractPort(from address: String) -> Int {
        // Handle IPv6 format: [ipv6]:port
        if address.contains("[") {
            if let closeBracket = address.lastIndex(of: "]"),
               let colonAfterBracket = address[closeBracket...].firstIndex(of: ":") {
                let portStart = address.index(after: colonAfterBracket)
                return Int(address[portStart...]) ?? 0
            }
            return 0
        }

        // Handle IPv4 or *:port format
        if let lastColon = address.lastIndex(of: ":") {
            let portStart = address.index(after: lastColon)
            return Int(address[portStart...]) ?? 0
        }

        return 0
    }

    private func parseState(_ state: String) -> PortState {
        let cleaned = state.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        switch cleaned.uppercased() {
        case "LISTEN": return .listen
        case "ESTABLISHED": return .established
        case "TIME_WAIT": return .timeWait
        case "CLOSE_WAIT": return .closeWait
        case "SYN_SENT": return .synSent
        case "SYN_RECEIVED", "SYN_RECV": return .synReceived
        case "FIN_WAIT_1", "FIN_WAIT1": return .finWait1
        case "FIN_WAIT_2", "FIN_WAIT2": return .finWait2
        case "CLOSING": return .closing
        case "LAST_ACK": return .lastAck
        case "CLOSED": return .closed
        default: return .unknown
        }
    }

    private func runCommand(_ path: String, arguments: [String]) async throws -> String {
        try await Task.detached {
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        }.value
    }

    // MARK: - Filtering

    func filteredPorts(filter: PortFilter, searchText: String, watchlistPorts: [Int]) -> [PortInfo] {
        var result = ports

        switch filter {
        case .all:
            break
        case .listening:
            result = result.filter { $0.state == .listen }
        case .established:
            result = result.filter { $0.state == .established }
        case .watchlist:
            result = result.filter { watchlistPorts.contains($0.port) }
        }

        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter {
                $0.processName.lowercased().contains(search) ||
                String($0.port).contains(search) ||
                $0.user.lowercased().contains(search) ||
                $0.localAddress.lowercased().contains(search)
            }
        }

        return result
    }

    func uniqueProcessCount() -> Int {
        Set(ports.compactMap { $0.pid > 0 ? $0.pid : nil }).count
    }

    func uniquePortCount() -> Int {
        Set(ports.map { $0.port }).count
    }

    func listeningCount() -> Int {
        ports.filter { $0.state == .listen }.count
    }

    func establishedCount() -> Int {
        ports.filter { $0.state == .established }.count
    }
}
