# SystemPulse

A lightweight, native macOS menu bar app that displays real-time system metrics with beautiful mini graphs.

<img width="397" height="715" alt="image" src="https://github.com/user-attachments/assets/6868a0ac-1d01-45aa-84d7-8d21dc0daa6b" />


![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **CPU monitoring** - Usage percentage, temperature, per-core tracking with history graph
- **Memory monitoring** - Used/free memory, active/wired/compressed breakdown
- **GPU monitoring** - Utilization percentage, temperature, history graph
- **Network monitoring** - Download/upload speeds, local & public IP, session totals
- **Disk monitoring** - Usage percentage, free space, volume name
- **Battery monitoring** - Charge level, charging status, time remaining
- **Fan monitoring** - RPM for each fan (when available)
- **System info** - Load average, process count, swap usage, kernel version, uptime

### Interactive features

- **Hover** over any card to reveal a clickable arrow
- **Click** to open the corresponding system app (Activity Monitor, Disk Utility, System Settings, etc.)
- **Right-click** the menu bar icon for a quick menu

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac

## Installation

### Option 1: Build from source

1. Clone the repository:
   ```bash
   git clone https://github.com/bluewave-labs/systempulse.git
   cd systempulse
   ```

2. Build the app:
   ```bash
   swiftc -O -o SystemPulse SystemPulse.swift -framework Cocoa -framework IOKit -framework Metal
   ```

3. Run:
   ```bash
   ./SystemPulse
   ```

### Option 2: Create an app bundle (optional)

If you want SystemPulse to appear as a proper macOS app:

1. Create the app structure:
   ```bash
   mkdir -p SystemPulse.app/Contents/MacOS
   cp SystemPulse SystemPulse.app/Contents/MacOS/
   ```

2. Create `SystemPulse.app/Contents/Info.plist`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>CFBundleExecutable</key>
       <string>SystemPulse</string>
       <key>CFBundleIdentifier</key>
       <string>com.bluewave.systempulse</string>
       <key>CFBundleName</key>
       <string>SystemPulse</string>
       <key>CFBundleVersion</key>
       <string>1.0</string>
       <key>LSMinimumSystemVersion</key>
       <string>14.0</string>
       <key>LSUIElement</key>
       <true/>
   </dict>
   </plist>
   ```

3. Move to Applications (optional):
   ```bash
   mv SystemPulse.app /Applications/
   ```

### Launch at login (optional)

1. Open **System Settings** > **General** > **Login Items**
2. Click **+** and add SystemPulse

## Usage

Once running, SystemPulse appears in your menu bar showing CPU and memory usage.

- **Left-click** the menu bar item to open the detailed panel
- **Right-click** for a quick menu with Quit option
- **Hover** over any metric card to see an arrow indicator
- **Click** a card to open the related system app

## Technical details

SystemPulse uses native macOS APIs for accurate metrics:

- **CPU**: `host_processor_info()` Mach API
- **Memory**: `host_statistics64()` Mach API
- **GPU**: IOKit `IOAccelerator` service
- **Network**: `getifaddrs()` for interface statistics
- **Battery**: `IOPSCopyPowerSourcesInfo()` from IOKit
- **Temperature/Fans**: SMC (System Management Controller) via IOKit

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

Built with Swift and AppKit for native macOS performance.
