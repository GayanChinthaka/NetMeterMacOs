# NetMeter 🚀

A lightweight macOS menu bar app that shows your real-time download and upload speeds. No accounts, no logs, no telemetry. Nothing is written to disk.

Inspired by Scaler and MenuMeters, built natively with Swift, AppKit and SwiftUI.

---

## ✨ Features

- **⚡ Real-time speeds** read straight from the macOS kernel's 64-bit network counters (`NET_RT_IFLIST2`).
- **🪶 Lightweight**
  - App size: about **0.6 MB** (Apple Silicon build), **1.2 MB** universal
  - Memory: about **11 MB**
  - CPU: about **0.3–0.5%** at the default 1-second refresh
  - Pauses itself while the display is asleep, the Mac sleeps or you switch users
- **🔒 Private and stateless**
  - No account or login
  - No disk logging, no database, no analytics, no outgoing network calls
  - Session totals live only in memory and vanish when the app quits
- **🚀 Launch at Login** via macOS `SMAppService`, toggled from Settings
- **🎨 Display layouts**
  - **Stacked (2 lines)**: compact vertical layout
  - **Single line**: `↓ 1.4 MB/s  ↑ 250 KB/s`
  - **Upload on top**, **download / upload only**, adjustable **font size**
  - **Colored arrows** (green / cyan) or monochrome
- **📊 Units**: Bytes/s (`KB/s`, `MB/s`, …) or Bits/s (`Kbps`, `Mbps`, …)
- **⏱️ Refresh rate**: 0.5 s, 1 s (recommended) or 2 s (battery saver)
- **🌐 Smart interface detection**: follows the active Wi-Fi or Ethernet connection with `NWPathMonitor` and shows your local IP address

---

## 📥 Download

Get the latest **NetMeter-vX.Y.Z-macOS.dmg** from the [Releases page](https://github.com/GayanChinthaka/NetMeterMacOs/releases/latest), open it and drag **NetMeter** into **Applications**.

> [!NOTE]
> NetMeter is not notarized by Apple, so macOS blocks it the first time you open it.
> Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
> Or run this once in Terminal:
> ```bash
> xattr -dr com.apple.quarantine /Applications/NetMeter.app
> ```

Requires macOS 13 Ventura or later. Release builds run natively on both Apple Silicon and Intel Macs.

---

## 🛠️ Building from Source

### Prerequisites
- macOS 13 or later
- Xcode or the Xcode Command Line Tools (Swift 5.9 or later)

### Build commands
```bash
# Build, install to /Applications and launch
./scripts/install.sh

# Build build/NetMeter.app only
./scripts/build_app.sh
open build/NetMeter.app

# Release-style build: universal binary + DMG, ZIP and checksums in dist/
UNIVERSAL=1 APP_VERSION=1.2.0 ./scripts/build_app.sh
./scripts/package_release.sh
```

`build_app.sh` accepts these optional environment variables:

| Variable | Effect |
|---|---|
| `UNIVERSAL=1` | Builds for Apple Silicon and Intel and joins them into one binary |
| `APP_VERSION=1.2.0` | Sets the version shown in the app (`CFBundleShortVersionString`) |
| `BUILD_NUMBER=42` | Sets the build number (`CFBundleVersion`) |

---

## 🚀 Release Workflow (GitHub Actions)

Releases are built and published by the **Build & Publish Release** workflow ([`.github/workflows/release.yml`](.github/workflows/release.yml)).

It runs **only** when:
- a tag starting with `v` is pushed, or
- it is started by hand from the **Actions** tab.

Ordinary pushes to `main` or any other branch do not run it.

### How to publish a new release

1. **Update the version** in `Resources/Info.plist`:
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.2.0</string>
   ```

2. **Commit and push**:
   ```bash
   git add Resources/Info.plist
   git commit -m "Bump version to 1.2.0"
   git push origin main
   ```

3. **Create and push the tag**:
   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

### What happens automatically

Once the tag is pushed, the workflow:
- Reads the version from the tag (and warns if it does not match `Info.plist`).
- Builds a universal `NetMeter.app` on a macOS runner, with the version and build number stamped in.
- Packages `NetMeter-v1.2.0-macOS.dmg`, `NetMeter-v1.2.0-macOS.zip` and `checksums-sha256.txt`.
- Publishes a GitHub Release with install instructions, auto-generated release notes and the files above attached.

> [!TIP]
> To run it by hand, open **Actions → Build & Publish Release → Run workflow**. A manual run uses the version in `Info.plist` and creates the `v<version>` tag on the selected branch if it does not exist yet. You can mark it as a **pre-release** or **draft**.

---

## ⚙️ Settings

Click the menu bar item and choose **Settings...** (`⌘,`):

1. **General**: Launch at Login, update interval
2. **Display**: speed unit, layout, what to show, upload on top, colored arrows, font size, live preview
3. **Network**: traffic source (primary interface or all combined), active interface and local IP address
4. **Privacy**: session totals and **Reset Session Counters**

---

## 🧱 Tech Stack

- **Language**: Swift (Swift 5.9 package, builds with the Swift 6 toolchain)
- **Frameworks**: AppKit (`NSStatusItem`), SwiftUI (Settings window), Darwin (`sysctl`, `NET_RT_IFLIST2`), Network (`NWPathMonitor`), ServiceManagement (`SMAppService`)
- **Compatibility**: macOS 13 Ventura and later, Apple Silicon and Intel
