import AppKit
import SwiftUI
import Combine

public final class MenuBarController: NSObject, NSMenuDelegate {
    public static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem!
    private var statusView: StatusItemView?
    private var menu: NSMenu!
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?
    
    // Menu items that get dynamically updated
    private var speedHeaderItem: NSMenuItem!
    private var sessionDownItem: NSMenuItem!
    private var sessionUpItem: NSMenuItem!
    private var interfaceItem: NSMenuItem!
    private var ipItem: NSMenuItem!
    
    private override init() {
        super.init()
    }
    
    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = ""
            button.image = nil
            let view = StatusItemView(frame: button.bounds)
            button.addSubview(view)
            self.statusView = view
        }
        
        buildMenu()
        statusItem.menu = menu
        
        setupSubscriptions()
        updateTitle()
    }
    
    private func setupSubscriptions() {
        // 1. Live speed updates from NetworkMonitor (emits immediately and on every second tick)
        Publishers.CombineLatest(
            NetworkMonitor.shared.$downloadSpeed,
            NetworkMonitor.shared.$uploadSpeed
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _ in
            self?.updateTitle()
        }
        .store(in: &cancellables)
        
        // 2. Preferences updates (when user changes any setting)
        PreferencesManager.shared.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateTitle()
                }
            }
            .store(in: &cancellables)
    }
    
    public func updateTitle() {
        guard let button = statusItem?.button, let view = statusView else { return }
        let prefs = PreferencesManager.shared
        let monitor = NetworkMonitor.shared
        
        let downStr = SpeedFormatter.formatSpeed(monitor.downloadSpeed, unit: prefs.speedUnit)
        let upStr = SpeedFormatter.formatSpeed(monitor.uploadSpeed, unit: prefs.speedUnit)
        
        view.topArrow = "↓"
        view.topText = downStr
        view.bottomArrow = "↑"
        view.bottomText = upStr
        view.isStacked = (prefs.displayLayout == .stacked)
        view.displayMode = prefs.displayMode
        view.uploadOnTop = prefs.uploadOnTop
        view.showColors = prefs.showColors
        
        let neededWidth = view.calculateNeededWidth()
        statusItem.length = neededWidth
        let h = button.bounds.height > 0 ? button.bounds.height : 24.0
        view.frame = NSRect(x: 0, y: 0, width: neededWidth, height: h)
        view.needsDisplay = true
    }
    
    private func buildMenu() {
        menu = NSMenu()
        menu.delegate = self
        
        // Speed Header
        speedHeaderItem = NSMenuItem(title: "NetMeter", action: nil, keyEquivalent: "")
        speedHeaderItem.isEnabled = false
        menu.addItem(speedHeaderItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Session Usage (In-Memory Only)
        let sessionHeader = NSMenuItem(title: "Session Usage (In-Memory):", action: nil, keyEquivalent: "")
        sessionHeader.isEnabled = false
        menu.addItem(sessionHeader)
        
        sessionDownItem = NSMenuItem(title: "  ↓ Download: 0 B", action: nil, keyEquivalent: "")
        sessionDownItem.isEnabled = false
        menu.addItem(sessionDownItem)
        
        sessionUpItem = NSMenuItem(title: "  ↑ Upload: 0 B", action: nil, keyEquivalent: "")
        sessionUpItem.isEnabled = false
        menu.addItem(sessionUpItem)
        
        let resetItem = NSMenuItem(title: "  Reset Session Counter", action: #selector(resetSessionClicked), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Network Info
        let netHeader = NSMenuItem(title: "Network Connection:", action: nil, keyEquivalent: "")
        netHeader.isEnabled = false
        menu.addItem(netHeader)
        
        interfaceItem = NSMenuItem(title: "  Interface: Detecting...", action: nil, keyEquivalent: "")
        interfaceItem.isEnabled = false
        menu.addItem(interfaceItem)
        
        ipItem = NSMenuItem(title: "  IP Address: Detecting...", action: nil, keyEquivalent: "")
        ipItem.isEnabled = false
        menu.addItem(ipItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings / Preferences
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit NetMeter", action: #selector(quitAppClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        let monitor = NetworkMonitor.shared
        let prefs = PreferencesManager.shared
        
        let downStr = SpeedFormatter.formatSpeed(monitor.downloadSpeed, unit: prefs.speedUnit)
        let upStr = SpeedFormatter.formatSpeed(monitor.uploadSpeed, unit: prefs.speedUnit)
        
        speedHeaderItem.title = "Current:  ↓ \(downStr)   ↑ \(upStr)"
        sessionDownItem.title = "  ↓ Download: \(SpeedFormatter.formatTotalBytes(monitor.sessionDownloadedBytes))"
        sessionUpItem.title = "  ↑ Upload: \(SpeedFormatter.formatTotalBytes(monitor.sessionUploadedBytes))"
        
        interfaceItem.title = "  Interface: \(monitor.activeInterfaceType) (\(monitor.activeInterfaceName))"
        ipItem.title = "  IP Address: \(monitor.localIPAddress)"
    }
    
    @objc private func resetSessionClicked() {
        NetworkMonitor.shared.resetSession()
    }
    
    @objc public func openSettingsClicked() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "NetMeter Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        self.settingsWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitAppClicked() {
        NSApp.terminate(nil)
    }
}

