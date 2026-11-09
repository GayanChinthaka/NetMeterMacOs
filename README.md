# NetMeter 🚀

A blazing-fast, ultra-lightweight macOS menu bar utility that displays real-time network download and upload speeds. Designed with 100% privacy and zero disk storage.

Inspired by Scaler and MenuMeters, built natively with Swift, AppKit, and SwiftUI.

---

## ✨ Features

- **⚡ Real-time Speed Monitoring**: High-accuracy download and upload speeds computed from Darwin kernel 64-bit network counters (`NET_RT_IFLIST2`).
- **🪶 Ultra Lightweight**:
  - Binary size: **~525 KB**
  - RAM usage: **~15 - 20 MB**
  - CPU usage: **< 0.1%**
- **🔒 100% Private & Stateless**:
  - No user accounts or login.
  - Zero disk logging or database writes.
  - Zero telemetry or external network calls.
  - Session counters exist solely in volatile RAM and vanish when the app quits.
- **🚀 Launch at Login**: Modern macOS `SMAppService` integration — toggle with one click in Settings.
- **🎨 Custom Display Layouts**:
  - **Stacked (2 lines)**: Compact vertical layout (Scaler style).
  - **Single Line**: Horizontal layout (`↓ 1.4 MB/s  ↑ 250 KB/s`).
  - **Upload on Top**: Option to place upload above download.
  - **Color Indicators**: Green for download, Cyan for upload, or monochrome.
- **📊 Units Supported**:
  - Bytes/s: `B/s`, `KB/s`, `MB/s`, `GB/s`
  - Bits/s: `bps`, `Kbps`, `Mbps`, `Gbps`
- **⏱️ Configurable Refresh Rate**: 0.5s (ultra-fast), 1.0s (recommended), or 2.0s (battery saver).
- **🌐 Smart Network Detection**: Automatically tracks the active primary interface (`en0`, Wi-Fi, Ethernet) using `NWPathMonitor` and shows local IP address.

---

## 🚀 Installation & Usage

### Option 1: Quick Install to Applications
Run the install script from the project folder:
```bash
./scripts/install.sh
```
This builds the release binary, copies `NetMeter.app` to `/Applications/NetMeter.app`, and launches it immediately.

### Option 2: Build from Source
```bash
# Build the release bundle
./scripts/build_app.sh

# Open the app directly
open build/NetMeter.app
```

---

## ⚙️ Settings / Preferences

Click the menu bar item and select **Settings...** (or press `⌘,`):

1. **General**:
   - **Launch at Login**: Enable or disable auto-start on Mac boot.
   - **Update Interval**: Select 0.5s, 1.0s, or 2.0s refresh intervals.
2. **Display**:
   - **Speed Unit**: Choose Bytes/s (file transfer style) or Bits/s (ISP speed style).
   - **Menu Bar Layout**: Stacked (2 lines) or Single Line (horizontal).
   - **Show**: Both (Download & Upload), Download Only, or Upload Only.
   - **Upload on Top**: Place upload on the first line when stacked.
   - **Colored Indicators**: Color arrows (Green / Cyan) or adapt to menu bar monochrome.
   - **Live Preview**: See how the menu bar will look in real time.
3. **Network**:
   - **Traffic Source**: Auto (Primary active interface) or All interfaces combined.
   - **Connection Details**: Shows active interface type (`Wi-Fi`, `Ethernet`) and local IP address.
4. **Privacy**:
   - View session totals and click **Reset Session Counters** anytime.

---

## 🛠️ Tech Stack & Architecture

- **Language**: Swift 6 (Modern Concurrency & Safety)
- **Frameworks**: AppKit (`NSStatusItem`, `NSStatusBarButton`), SwiftUI (`SettingsView`), Darwin (`sysctl`, `NET_RT_IFLIST2`), Network (`NWPathMonitor`), ServiceManagement (`SMAppService`)
- **Compatibility**: macOS 13.0 (Ventura) and later (tested on macOS Sequoia / macOS 26 Apple Silicon)

