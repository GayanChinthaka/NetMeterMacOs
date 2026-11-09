import Foundation
import ServiceManagement

public final class PreferencesManager: ObservableObject {
    public static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin(launchAtLogin)
        }
    }
    
    @Published public var speedUnit: SpeedUnit {
        didSet { defaults.set(speedUnit.rawValue, forKey: "speedUnit") }
    }
    
    @Published public var displayLayout: DisplayLayout {
        didSet { defaults.set(displayLayout.rawValue, forKey: "displayLayout") }
    }
    
    @Published public var displayMode: DisplayMode {
        didSet { defaults.set(displayMode.rawValue, forKey: "displayMode") }
    }
    
    @Published public var uploadOnTop: Bool {
        didSet { defaults.set(uploadOnTop, forKey: "uploadOnTop") }
    }
    
    @Published public var updateInterval: Double {
        didSet { defaults.set(updateInterval, forKey: "updateInterval") }
    }
    
    @Published public var interfaceFilter: InterfaceFilter {
        didSet { defaults.set(interfaceFilter.rawValue, forKey: "interfaceFilter") }
    }
    
    @Published public var showColors: Bool {
        didSet { defaults.set(showColors, forKey: "showColors") }
    }
    
    @Published public var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: "fontSize") }
    }
    
    private init() {
        let launch = defaults.object(forKey: "launchAtLogin") as? Bool ?? false
        let unitStr = defaults.string(forKey: "speedUnit") ?? SpeedUnit.bytes.rawValue
        let layoutStr = defaults.string(forKey: "displayLayout") ?? DisplayLayout.stacked.rawValue
        let modeStr = defaults.string(forKey: "displayMode") ?? DisplayMode.both.rawValue
        let upTop = defaults.bool(forKey: "uploadOnTop")
        let interval = defaults.double(forKey: "updateInterval") == 0 ? 1.0 : defaults.double(forKey: "updateInterval")
        let ifaceStr = defaults.string(forKey: "interfaceFilter") ?? InterfaceFilter.auto.rawValue
        let colors = defaults.object(forKey: "showColors") as? Bool ?? true
        let fontSz = defaults.double(forKey: "fontSize")
        let validFontSz = (fontSz >= 9.0 && fontSz <= 13.0) ? fontSz : 10.5
        
        self.launchAtLogin = launch
        self.speedUnit = SpeedUnit(rawValue: unitStr) ?? .bytes
        self.displayLayout = DisplayLayout(rawValue: layoutStr) ?? .stacked
        self.displayMode = DisplayMode(rawValue: modeStr) ?? .both
        self.uploadOnTop = upTop
        self.updateInterval = interval
        self.interfaceFilter = InterfaceFilter(rawValue: ifaceStr) ?? .auto
        self.showColors = colors
        self.fontSize = validFontSz
        
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            if status == .enabled && !launch {
                self.launchAtLogin = true
            }
        }
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                NSLog("NetMeter: Failed to update SMAppService: %@", error.localizedDescription)
            }
        }
    }
}

