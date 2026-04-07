<p align="center">
  <img src="ThePort/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="ThePort Icon">
</p>

<h1 align="center">ThePort</h1>

<p align="center">
  <strong>A native macOS port and process monitor for developers.</strong><br>
  View active ports, identify processes, kill operations, and track specific ports — all from a lightweight menubar-friendly app.
</p>

<p align="center">
  <a href="https://github.com/bujosa/ThePort/releases/latest"><img src="https://img.shields.io/github/v/release/bujosa/ThePort?style=flat-square&color=blue" alt="Release"></a>
  <a href="https://github.com/bujosa/ThePort/releases/latest"><img src="https://img.shields.io/github/downloads/bujosa/ThePort/total?style=flat-square&color=green" alt="Downloads"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.9-orange?style=flat-square" alt="Swift">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/bujosa/ThePort?style=flat-square" alt="License"></a>
</p>

---

## Download

Grab the latest `.dmg` from [**Releases**](https://github.com/bujosa/ThePort/releases/latest), mount it, and drag **ThePort** into your Applications folder. No brew, no signing headaches — just open and go.

## Why ThePort?

Ever run `lsof -i :3000` just to find out what's hogging a port? ThePort replaces that workflow with a real-time UI that shows every active TCP connection on your Mac, which process owns it, and lets you kill it in one click.

## Features

| Feature | Description |
|---|---|
| **Port Monitoring** | Real-time view of all active TCP ports on your system |
| **Process Identification** | See which processes (Node, Chrome, Postgres, etc.) own each port |
| **Kill Processes** | Terminate processes directly — graceful (SIGTERM) or force (SIGKILL) |
| **Search & Filter** | Filter by state (Listening, Established) or search by port, process name, or address |
| **Watchlist** | Track specific ports you care about with custom names and priority levels |
| **Auto-Refresh** | Automatic updates every 5 seconds (configurable) |
| **Light & Dark Theme** | Follows system appearance or toggle manually |
| **Low Resource Usage** | ~94 MB memory, 0% CPU when idle |

## How It Works

ThePort uses two macOS system commands under the hood:

1. **`netstat -an -p tcp`** — lists all active TCP connections and listening ports
2. **`lsof -i -P -n -F`** — enriches each port entry with process info (PID, name, user)

These run on a configurable timer and feed a clean, filterable SwiftUI interface.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Database | SQLite via [GRDB.swift](https://github.com/groue/GRDB.swift) 7.x |
| Port Scanning | `netstat` · `lsof` |
| Build System | [Tuist](https://tuist.io) |
| CI/CD | GitHub Actions |
| Distribution | DMG |

## Build from Source

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15+
- [Tuist](https://tuist.io) 4.x (`brew tap tuist/tuist && brew install tuist`)

### Quick Start

```bash
git clone https://github.com/bujosa/ThePort.git
cd ThePort

# Install dependencies & generate Xcode project
make install
make generate

# Build and run (debug)
make build
make run
```

### All Commands

| Command | Description |
|---------|------------|
| `make install` | Install Swift package dependencies |
| `make generate` | Generate Xcode workspace via Tuist |
| `make build` | Build debug configuration |
| `make run` | Build and launch the app |
| `make release` | Build release configuration |
| `make dmg` | Create distributable `.dmg` |
| `make clean` | Clean build artifacts and regenerate |
| `make edit` | Open Tuist project for editing |
| `make icons` | Regenerate app icons |

## Project Structure

```
ThePort/
├── Project.swift                    # Tuist project definition
├── Tuist/Package.swift              # Dependencies (GRDB.swift)
├── Makefile                         # Build automation
├── .github/workflows/release.yml    # CI/CD — builds DMG on tag push
├── scripts/
│   ├── create-dmg.sh               # DMG packaging script
│   └── generate-icons.swift         # App icon generator
└── ThePort/
    ├── Sources/
    │   ├── ThePortApp.swift         # App entry point
    │   ├── Models/                  # Data models (PortInfo, ProcessInfo, etc.)
    │   ├── Services/
    │   │   ├── PortService.swift    # Port scanning via netstat/lsof
    │   │   └── DatabaseService.swift # SQLite via GRDB (watchlist persistence)
    │   ├── Theme/                   # Light/Dark theme system
    │   └── Views/
    │       ├── ContentView/         # Root navigation
    │       ├── Sidebar/             # Navigation sidebar
    │       ├── PortList/            # Port listing with filters
    │       ├── Watchlist/           # Watchlist management
    │       ├── ProcessDetail/       # Process details modal
    │       └── Components/          # Reusable UI components
    └── Resources/
        └── Assets.xcassets/         # App icons & colors
```

## Data Storage

Watchlist data is stored locally in a SQLite database:

```
~/Library/Application Support/ThePort/db.sqlite
```

No cloud services, no accounts, no telemetry. Everything stays on your machine.

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/awesome-thing`)
3. Commit your changes
4. Push and open a Pull Request

## License

MIT License — see [LICENSE](LICENSE) for details.
