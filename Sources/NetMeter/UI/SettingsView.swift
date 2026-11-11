import SwiftUI

public struct SettingsView: View {
    // Note: this view deliberately does not observe NetworkMonitor. Only the small
    // subviews that show live numbers do, so the whole TabView is not rebuilt every tick.
    @ObservedObject var prefs = PreferencesManager.shared
    
    public init() {}
    
    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            displayTab
                .tabItem {
                    Label("Display", systemImage: "macwindow")
                }
            
            networkTab
                .tabItem {
                    Label("Network", systemImage: "network")
                }
            
            privacyTab
                .tabItem {
                    Label("Privacy", systemImage: "lock.shield")
                }
        }
        .padding(20)
        .frame(width: 480, height: 380)
    }
    
    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $prefs.launchAtLogin)
                    .help("Automatically start NetMeter when you log in to your Mac.")
                
                Picker("Update Interval", selection: $prefs.updateInterval) {
                    Text("0.5 seconds (Ultra Fast)").tag(0.5)
                    Text("1.0 second (Recommended)").tag(1.0)
                    Text("2.0 seconds (Battery Saver)").tag(2.0)
                }
                .help("How frequently network speeds are recalculated.")
            } header: {
                Text("Startup & Refresh Rate").fontWeight(.medium)
            }
            
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NetMeter")
                            .font(.headline)
                        Text("Ultra-lightweight real-time network speed monitor for macOS.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Version 1.0.0 • Personal Use • Native Swift")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
    }
    
    private var displayTab: some View {
        Form {
            Section {
                Picker("Speed Unit", selection: $prefs.speedUnit) {
                    ForEach(SpeedUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                
                Picker("Menu Bar Layout", selection: $prefs.displayLayout) {
                    ForEach(DisplayLayout.allCases) { layout in
                        Text(layout.displayName).tag(layout)
                    }
                }
                
                Picker("Show", selection: $prefs.displayMode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                
                if prefs.displayLayout == .stacked && prefs.displayMode == .both {
                    Toggle("Upload on top (Download on bottom)", isOn: $prefs.uploadOnTop)
                }
                
                Toggle("Use colored indicators (Green / Cyan)", isOn: $prefs.showColors)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Font Size:")
                        Spacer()
                        Text(String(format: "%.1f pt", prefs.fontSize))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $prefs.fontSize, in: 9.0...12.5, step: 0.5) {
                        Text("Font Size")
                    } minimumValueLabel: {
                        Text("9 pt").font(.caption).foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("12.5 pt").font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 2)
            } header: {
                Text("Menu Bar Appearance").fontWeight(.medium)
            }
            
            Section {
                HStack {
                    Text("Live Preview:")
                        .foregroundColor(.secondary)
                    Spacer()
                    SettingsPreviewBox()
                }
            } header: {
                Text("Preview").fontWeight(.medium)
            }
        }
        .formStyle(.grouped)
    }
    
    private var networkTab: some View {
        Form {
            Section {
                Picker("Traffic Source", selection: $prefs.interfaceFilter) {
                    ForEach(InterfaceFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
            } header: {
                Text("Interface Monitoring").fontWeight(.medium)
            }
            
            ConnectionDetailsSection()
        }
        .formStyle(.grouped)
    }
    
    private var privacyTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("100% Private & Stateless")
                            .font(.headline)
                    }
                    
                    Text("NetMeter does not record, log, or persist your network traffic or visited sites to any files, databases, or external servers.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("• Zero disk logging\n• Zero analytics or telemetry\n• No account or login required\n• All session counters are held strictly in temporary RAM and vanish when NetMeter quits.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            } header: {
                Text("Privacy Guarantee").fontWeight(.medium)
            }
            
            SessionUsageSection()
        }
        .formStyle(.grouped)
    }
}

private struct SettingsPreviewBox: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @ObservedObject var monitor = NetworkMonitor.shared
    
    var body: some View {
        let downStr = SpeedFormatter.formatSpeed(monitor.downloadSpeed > 0 ? monitor.downloadSpeed : 1_540_000, unit: prefs.speedUnit)
        let upStr = SpeedFormatter.formatSpeed(monitor.uploadSpeed > 0 ? monitor.uploadSpeed : 256_000, unit: prefs.speedUnit)
        
        let downColor: Color = prefs.showColors ? .green : .primary
        let upColor: Color = prefs.showColors ? .cyan : .primary
        let currentSize = CGFloat(prefs.fontSize)
        
        return Group {
            if prefs.displayLayout == .stacked {
                VStack(alignment: .leading, spacing: 1) {
                    if prefs.displayMode == .both {
                        if prefs.uploadOnTop {
                            HStack(spacing: 3) {
                                Text("↑").foregroundColor(upColor).bold().frame(width: currentSize, alignment: .leading)
                                Text(upStr).font(.system(size: currentSize, weight: .semibold, design: .monospaced))
                            }
                            HStack(spacing: 3) {
                                Text("↓").foregroundColor(downColor).bold().frame(width: currentSize, alignment: .leading)
                                Text(downStr).font(.system(size: currentSize, weight: .semibold, design: .monospaced))
                            }
                        } else {
                            HStack(spacing: 3) {
                                Text("↓").foregroundColor(downColor).bold().frame(width: currentSize, alignment: .leading)
                                Text(downStr).font(.system(size: currentSize, weight: .semibold, design: .monospaced))
                            }
                            HStack(spacing: 3) {
                                Text("↑").foregroundColor(upColor).bold().frame(width: currentSize, alignment: .leading)
                                Text(upStr).font(.system(size: currentSize, weight: .semibold, design: .monospaced))
                            }
                        }
                    } else if prefs.displayMode == .downloadOnly {
                        HStack(spacing: 3) {
                            Text("↓").foregroundColor(downColor).bold().frame(width: currentSize, alignment: .leading)
                            Text(downStr).font(.system(size: currentSize, weight: .semibold, design: .monospaced))
                        }
                    } else {
                        HStack(spacing: 3) {
                            Text("↑").foregroundColor(upColor).bold().frame(width: currentSize, alignment: .leading)
                            Text(upStr).font(.system(size: currentSize, weight: .semibold, design: .monospaced))
                        }
                    }
                }
            } else {
                let singleSize = currentSize + 1.5
                HStack(spacing: 8) {
                    if prefs.displayMode == .both || prefs.displayMode == .downloadOnly {
                        HStack(spacing: 3) {
                            Text("↓").foregroundColor(downColor).bold()
                            Text(downStr).font(.system(size: singleSize, weight: .semibold, design: .monospaced))
                        }
                    }
                    if prefs.displayMode == .both || prefs.displayMode == .uploadOnly {
                        HStack(spacing: 3) {
                            Text("↑").foregroundColor(upColor).bold()
                            Text(upStr).font(.system(size: singleSize, weight: .semibold, design: .monospaced))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
}

private struct ConnectionDetailsSection: View {
    @ObservedObject var monitor = NetworkMonitor.shared
    
    var body: some View {
        Section {
            LabeledContent("Active Interface", value: "\(monitor.activeInterfaceType) (\(monitor.activeInterfaceName))")
            LabeledContent("Local IP Address", value: monitor.localIPAddress)
            LabeledContent("Connection Status", value: monitor.isConnected ? "Connected" : "Disconnected")
        } header: {
            Text("Connection Details").fontWeight(.medium)
        }
    }
}

private struct SessionUsageSection: View {
    @ObservedObject var monitor = NetworkMonitor.shared
    
    var body: some View {
        Section {
            LabeledContent("Session Downloaded", value: SpeedFormatter.formatTotalBytes(monitor.sessionDownloadedBytes))
            LabeledContent("Session Uploaded", value: SpeedFormatter.formatTotalBytes(monitor.sessionUploadedBytes))
            
            Button(role: .destructive, action: {
                monitor.resetSession()
            }) {
                Label("Reset Session Counters", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("Current RAM Session").fontWeight(.medium)
        }
    }
}
