# Cordkeeper 🔥

A native iOS app to track your firewood consumption throughout the heating season.

## Features (v1)

- **Quick Log Entry** — Three large tap targets for Small, Medium, and Large pieces. Single tap adds one, long-press for multiple. Designed for cold/dirty hands.
- **Fire Sessions** — Start and end fires to group log entries together. See running totals during active fires.
- **Cord Calibration** — Set how many medium-equivalent units make up one cord of your specific wood.
- **Size Ratios** — Configurable ratios for S/M/L pieces (default: 0.25/1.0/2.0).
- **Season Dashboard** — Total logs burned by size, fire count, estimated cords, progress toward seasonal goal.
- **History View** — Browse past fires grouped by month with duration and log breakdown.
- **Data Persistence** — All data stored locally using SwiftData.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Download and unzip the project
2. Open `Cordkeeper.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on your device or simulator

## Project Structure

```
Cordkeeper/
├── Cordkeeper.xcodeproj/
└── Cordkeeper/
    ├── CordkeeperApp.swift      # App entry point
    ├── ContentView.swift         # Main navigation & tab bar
    ├── Models.swift              # Data models (Fire, LogEntry, AppSettings)
    ├── OnboardingView.swift      # First-launch setup flow
    ├── DashboardView.swift       # Home screen with stats
    ├── ActiveFireView.swift      # Log entry during active fire
    ├── HistoryView.swift         # Past fires list
    ├── SettingsView.swift        # Configuration options
    └── Assets.xcassets/          # App icons and colors
```

## Data Model

**Fire**
- Start/end times
- Collection of log entries
- Optional notes

**LogEntry**
- Size (small/medium/large)
- Quantity
- Timestamp

**AppSettings**
- Units per cord (default: 400)
- Size ratios (S: 0.25, M: 1.0, L: 2.0)
- Season goal
- Season start date

## Usage

1. **First Launch**: Complete the onboarding to set your cord calibration and optional season goal.

2. **Start a Fire**: Tap "Start a Fire" on the dashboard.

3. **Add Logs**: Tap S/M/L buttons to add pieces. Hold for quantity picker.

4. **End Fire**: When done, tap "End Fire" to save to history.

5. **Track Progress**: Dashboard shows cords burned and progress toward your goal.

## Future Roadmap

- Home screen widget
- Apple Watch companion app
- Weather integration
- Cost tracking
- Inventory management
- iCloud sync
- Export to CSV/PDF

## License

MIT License — feel free to modify and use as you wish.

---

Built with SwiftUI and SwiftData for iOS 17+.
