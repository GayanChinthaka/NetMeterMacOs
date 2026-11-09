import Foundation

public enum DisplayLayout: String, CaseIterable, Identifiable {
    case stacked = "stacked"
    case singleLine = "singleLine"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .stacked: return "Stacked (2 lines)"
        case .singleLine: return "Single Line (Horizontal)"
        }
    }
}

public enum DisplayMode: String, CaseIterable, Identifiable {
    case both = "both"
    case downloadOnly = "downloadOnly"
    case uploadOnly = "uploadOnly"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .both: return "Both (Download & Upload)"
        case .downloadOnly: return "Download Only"
        case .uploadOnly: return "Upload Only"
        }
    }
}

public enum InterfaceFilter: String, CaseIterable, Identifiable {
    case auto = "auto"
    case all = "all"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .auto: return "Auto (Primary Active Interface)"
        case .all: return "All Interfaces (Combined)"
        }
    }
}

