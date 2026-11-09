import Foundation

public enum SpeedUnit: String, CaseIterable, Identifiable {
    case bytes = "bytes"
    case bits = "bits"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .bytes: return "Bytes/s (KB/s, MB/s)"
        case .bits:  return "Bits/s (Kbps, Mbps)"
        }
    }
}

public struct SpeedFormatter {
    public static func formatSpeed(_ bytesPerSec: Double, unit: SpeedUnit) -> String {
        let value = (unit == .bits) ? (bytesPerSec * 8.0) : bytesPerSec
        let k: Double = 1024.0
        let m: Double = k * 1024.0
        let g: Double = m * 1024.0
        
        let labels: (b: String, k: String, m: String, g: String) = {
            switch unit {
            case .bytes: return ("B/s", "KB/s", "MB/s", "GB/s")
            case .bits:  return ("bps", "Kbps", "Mbps", "Gbps")
            }
        }()
        
        if value < 1.0 {
            return (unit == .bytes) ? "0 KB/s" : "0 Kbps"
        } else if value < k {
            return String(format: "%.0f %@", value, labels.b)
        } else if value < m {
            let v = value / k
            return v < 10.0 ? String(format: "%.1f %@", v, labels.k) : String(format: "%.0f %@", v, labels.k)
        } else if value < g {
            let v = value / m
            return v < 10.0 ? String(format: "%.2f %@", v, labels.m) : String(format: "%.1f %@", v, labels.m)
        } else {
            let v = value / g
            return String(format: "%.2f %@", v, labels.g)
        }
    }
    
    public static func formatTotalBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        let k = 1024.0
        let m = k * 1024.0
        let g = m * 1024.0
        let t = g * 1024.0
        
        if b < k {
            return "\(bytes) B"
        } else if b < m {
            return String(format: "%.1f KB", b / k)
        } else if b < g {
            return String(format: "%.2f MB", b / m)
        } else if b < t {
            return String(format: "%.2f GB", b / g)
        } else {
            return String(format: "%.2f TB", b / t)
        }
    }
}

