# ThePort

A native macOS port and process monitor for developers. View active ports, identify processes, kill operations, and track specific ports with a watchlist.

## Features

- **Port Monitoring**: View all active TCP ports on your system in real-time
- **Process Identification**: See which processes (Node, Chrome, etc.) are using each port
- **Kill Processes**: Terminate processes directly from the app (graceful or force kill)
- **Search & Filter**: Filter ports by state (Listening, Established) or search by port number, process name, or address
- **Watchlist**: Track specific ports you care about with custom names and priority levels
- **Auto-Refresh**: Automatic updates every 5 seconds (configurable)
- **Light/Dark Theme**: Toggle between light and dark modes
- **Low Resource Usage**: ~94MB memory, 0% CPU when idle

## Screenshots

<!-- Add screenshots here -->

## Requirements

- macOS 14.0+
- [Tuist](https://tuist.io) 4.x
- Xcode 15+

## Getting Started

```bash
# Clone the repository
git clone https://github.com/yourusername/ThePort.git
cd ThePort

# Install dependencies and generate Xcode project
make install
make generate

# Build and run
make build
make run
```

## Project Structure

```
ThePort/
├── Project.swift                    # Tuist project definition
├── Tuist/Package.swift              # Dependencies (GRDB.swift)
├── Makefile                         # Build automation
├── .github/workflows/release.yml    # CI/CD pipeline
├── scripts/
│   ├── create-dmg.sh               # DMG packaging
│   └── generate-icons.swift         # App icon generator
└── ThePort/
    ├── Sources/
    │   ├── ThePortApp.swift
    │   ├── Models/
    │   │   └── Models.swift              # Data models (PortInfo, ProcessInfo, etc.)
    │   ├── Services/
    │   │   ├── PortService.swift         # Port scanning via netstat/lsof
    │   │   └── DatabaseService.swift     # SQLite via GRDB (watchlist)
    │   ├── Theme/
    │   │   └── Theme.swift               # Light/Dark theme system
    │   └── Views/
    │       ├── ContentView/              # Root navigation
    │       ├── Sidebar/                  # Navigation sidebar
    │       ├── PortList/                 # Port listing with filters
    │       ├── Watchlist/                # Watchlist management
    │       ├── ProcessDetail/            # Process details modal
    │       └── Components/               # Reusable UI components
    └── Resources/
        └── Assets.xcassets/
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Database | SQLite ([GRDB.swift](https://github.com/groue/GRDB.swift) 7.x) |
| Port Scanning | netstat, lsof |
| Build | [Tuist](https://tuist.io) |
| CI/CD | GitHub Actions |
| Distribution | DMG |

## Build Commands

| Command | Description |
|---------|------------|
| `make install` | Install Swift package dependencies |
| `make generate` | Generate Xcode workspace via Tuist |
| `make build` | Build debug configuration |
| `make run` | Build and launch the app |
| `make release` | Build release configuration |
| `make dmg` | Create distributable DMG |
| `make clean` | Clean build artifacts and regenerate |
| `make edit` | Open Tuist project for editing |
| `make icons` | Regenerate app icons |

## How It Works

ThePort uses macOS system commands to gather port information:

1. **netstat -an -p tcp**: Lists all active TCP connections and listening ports
2. **lsof -i -P -n -F**: Enriches port data with process information (PID, name, user)

The app runs these commands periodically and displays the results in a clean, filterable interface.

## Data Storage

Watchlist data is stored locally:
- **Database**: `~/Library/Application Support/ThePort/db.sqlite`

No cloud services or external accounts required.

## License

MIT License - see [LICENSE](LICENSE) for details.
