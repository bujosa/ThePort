import Foundation
import GRDB

@MainActor
@Observable
class DatabaseService {
    var watchlistItems: [WatchlistItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private var dbQueue: DatabaseQueue?

    init() {}

    // MARK: - Database Setup

    func initialize() async {
        do {
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDirectory = appSupportURL.appendingPathComponent("ThePort", isDirectory: true)

            if !fileManager.fileExists(atPath: appDirectory.path) {
                try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
            }

            let dbURL = appDirectory.appendingPathComponent("theport.sqlite")

            var config = Configuration()
            config.foreignKeysEnabled = true

            dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)

            try runMigrations()
            await fetchWatchlist()
        } catch {
            errorMessage = "Database initialization failed: \(error.localizedDescription)"
        }
    }

    private func runMigrations() throws {
        guard let dbQueue = dbQueue else { return }

        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            try db.create(table: "watchlist_items", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("port", .integer).notNull()
                t.column("name", .text).notNull()
                t.column("description_", .text).notNull().defaults(to: "")
                t.column("notifyOnChange", .boolean).notNull().defaults(to: true)
                t.column("createdAt", .datetime).notNull()
                t.column("lastSeenActive", .datetime)
                t.column("priority", .text).notNull().defaults(to: "medium")
            }

            try db.create(index: "idx_watchlist_port", on: "watchlist_items", columns: ["port"])
        }

        try migrator.migrate(dbQueue)
    }

    // MARK: - Watchlist CRUD

    func fetchWatchlist() async {
        guard let dbQueue = dbQueue else { return }
        isLoading = true

        do {
            watchlistItems = try await dbQueue.read { db in
                try WatchlistItem.order(Column("priority").asc, Column("port").asc).fetchAll(db)
            }
        } catch {
            errorMessage = "Failed to fetch watchlist: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func addToWatchlist(port: Int, name: String, description: String = "", priority: WatchlistPriority = .medium) async {
        guard let dbQueue = dbQueue else { return }

        let item = WatchlistItem.new(port: port, name: name, description_: description, priority: priority)

        do {
            try await dbQueue.write { db in
                try item.insert(db)
            }
            await fetchWatchlist()
        } catch {
            errorMessage = "Failed to add to watchlist: \(error.localizedDescription)"
        }
    }

    func updateWatchlistItem(_ item: WatchlistItem) async {
        guard let dbQueue = dbQueue else { return }

        do {
            try await dbQueue.write { db in
                try item.update(db)
            }
            await fetchWatchlist()
        } catch {
            errorMessage = "Failed to update watchlist item: \(error.localizedDescription)"
        }
    }

    func removeFromWatchlist(_ item: WatchlistItem) async {
        guard let dbQueue = dbQueue else { return }

        do {
            _ = try await dbQueue.write { db in
                try item.delete(db)
            }
            await fetchWatchlist()
        } catch {
            errorMessage = "Failed to remove from watchlist: \(error.localizedDescription)"
        }
    }

    func removeFromWatchlist(port: Int) async {
        guard let dbQueue = dbQueue else { return }

        do {
            try await dbQueue.write { db in
                try db.execute(sql: "DELETE FROM watchlist_items WHERE port = ?", arguments: [port])
            }
            await fetchWatchlist()
        } catch {
            errorMessage = "Failed to remove from watchlist: \(error.localizedDescription)"
        }
    }

    func isInWatchlist(port: Int) -> Bool {
        watchlistItems.contains { $0.port == port }
    }

    func watchlistPorts() -> [Int] {
        watchlistItems.map { $0.port }
    }

    func updateLastSeen(port: Int) async {
        guard let dbQueue = dbQueue else { return }

        do {
            try await dbQueue.write { db in
                try db.execute(
                    sql: "UPDATE watchlist_items SET lastSeenActive = ? WHERE port = ?",
                    arguments: [Date(), port]
                )
            }
        } catch {
            // Silent failure for last seen updates
        }
    }

    // MARK: - Statistics

    func watchlistCount() -> Int {
        watchlistItems.count
    }

    func criticalCount() -> Int {
        watchlistItems.filter { $0.priority == .critical }.count
    }

    func highPriorityCount() -> Int {
        watchlistItems.filter { $0.priority == .high }.count
    }
}
