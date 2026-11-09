import Foundation
import Darwin
import Network
import Combine

public struct NetworkCounters {
    public var inBytes: UInt64 = 0
    public var outBytes: UInt64 = 0
}

public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    @Published public var downloadSpeed: Double = 0.0 // Bytes per second
    @Published public var uploadSpeed: Double = 0.0   // Bytes per second
    
    // In-Memory ONLY - No disk logs or storage
    @Published public var sessionDownloadedBytes: UInt64 = 0
    @Published public var sessionUploadedBytes: UInt64 = 0
    
    @Published public var activeInterfaceName: String = "en0"
    @Published public var activeInterfaceType: String = "Wi-Fi"
    @Published public var localIPAddress: String = ""
    @Published public var isConnected: Bool = true
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.netmeter.pathMonitor", qos: .utility)
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.netmeter.timer", qos: .utility)
    
    private var lastCounters: NetworkCounters?
    private var lastTimestamp: CFAbsoluteTime = 0
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let initialIface = Self.detectInitialPrimaryInterface()
        self.activeInterfaceName = initialIface
        self.localIPAddress = fetchIPAddress(for: initialIface) ?? ""
        
        startPathMonitor()
        startTimer(interval: PreferencesManager.shared.updateInterval)
        
        // Listen to preference changes for updateInterval and interfaceFilter
        PreferencesManager.shared.$updateInterval
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newInterval in
                self?.startTimer(interval: newInterval)
            }
            .store(in: &cancellables)
    }
    
    private static func detectInitialPrimaryInterface() -> String {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: Int = 0
        guard sysctl(&mib, 6, nil, &len, nil, 0) == 0, len > 0 else { return "en0" }

        let buffer = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: MemoryLayout<Int>.alignment)
        defer { buffer.deallocate() }

        guard sysctl(&mib, 6, buffer, &len, nil, 0) == 0 else { return "en0" }

        var cursor = buffer
        let limit = buffer.advanced(by: len)
        var candidate = "en0"
        var maxBytes: UInt64 = 0

        while cursor < limit {
            let msgHdr = cursor.assumingMemoryBound(to: if_msghdr.self).pointee
            let nextCursor = cursor.advanced(by: Int(msgHdr.ifm_msglen))

            if msgHdr.ifm_type == RTM_IFINFO2 {
                let msgHdr2 = cursor.assumingMemoryBound(to: if_msghdr2.self).pointee
                let flags = Int32(msgHdr2.ifm_flags)
                let isUp = (flags & IFF_UP) != 0 && (flags & IFF_RUNNING) != 0
                let isLoopback = (flags & IFF_LOOPBACK) != 0

                if isUp && !isLoopback {
                    let sdlPtr = cursor.advanced(by: MemoryLayout<if_msghdr2>.stride).assumingMemoryBound(to: sockaddr_dl.self)
                    let sdl = sdlPtr.pointee
                    var name = ""
                    if sdl.sdl_nlen > 0 {
                        withUnsafePointer(to: sdl.sdl_data) { ptr in
                            let bytePtr = UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
                            name = String(decoding: UnsafeBufferPointer(start: bytePtr, count: Int(sdl.sdl_nlen)), as: UTF8.self)
                        }
                    }
                    let bytes = msgHdr2.ifm_data.ifi_ibytes + msgHdr2.ifm_data.ifi_obytes
                    if bytes > maxBytes {
                        maxBytes = bytes
                        candidate = name
                    }
                }
            }
            cursor = nextCursor
        }
        return candidate
    }
    
    deinit {
        timer?.cancel()
        pathMonitor.cancel()
    }
    
    public func resetSession() {
        DispatchQueue.main.async {
            self.sessionDownloadedBytes = 0
            self.sessionUploadedBytes = 0
        }
    }
    
    private func startPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let connected = (path.status == .satisfied)
            
            var primaryName = "en0"
            var typeString = "Wi-Fi"
            
            if let primary = path.availableInterfaces.first(where: { path.usesInterfaceType($0.type) }) {
                primaryName = primary.name
                switch primary.type {
                case .wifi: typeString = "Wi-Fi"
                case .wiredEthernet: typeString = "Ethernet"
                case .cellular: typeString = "Cellular"
                case .loopback: typeString = "Loopback"
                case .other: typeString = "Other"
                @unknown default: typeString = "Network"
                }
            } else if let fallback = path.availableInterfaces.first {
                primaryName = fallback.name
            }
            
            let ip = self.fetchIPAddress(for: primaryName) ?? "No IP"
            
            DispatchQueue.main.async {
                self.isConnected = connected
                self.activeInterfaceName = primaryName
                self.activeInterfaceType = typeString
                self.localIPAddress = ip
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }
    
    private func startTimer(interval: Double) {
        timer?.cancel()
        
        let validInterval = max(0.2, interval)
        let newTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        newTimer.schedule(deadline: .now(), repeating: validInterval, leeway: .milliseconds(50))
        
        newTimer.setEventHandler { [weak self] in
            self?.tick()
        }
        newTimer.resume()
        self.timer = newTimer
    }
    
    private func tick() {
        let now = CFAbsoluteTimeGetCurrent()
        let filter = PreferencesManager.shared.interfaceFilter
        let targetIface = activeInterfaceName
        
        let counters = fetchCounters(filter: filter, targetInterface: targetIface)
        
        guard let prev = lastCounters, lastTimestamp > 0 else {
            lastCounters = counters
            lastTimestamp = now
            return
        }
        
        let deltaSec = now - lastTimestamp
        guard deltaSec > 0.05 else { return }
        
        var downSpeed: Double = 0.0
        var upSpeed: Double = 0.0
        var addedIn: UInt64 = 0
        var addedOut: UInt64 = 0
        
        if counters.inBytes >= prev.inBytes {
            addedIn = counters.inBytes - prev.inBytes
            downSpeed = Double(addedIn) / deltaSec
        }
        
        if counters.outBytes >= prev.outBytes {
            addedOut = counters.outBytes - prev.outBytes
            upSpeed = Double(addedOut) / deltaSec
        }
        
        lastCounters = counters
        lastTimestamp = now
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.downloadSpeed = downSpeed
            self.uploadSpeed = upSpeed
            self.sessionDownloadedBytes += addedIn
            self.sessionUploadedBytes += addedOut
        }
    }
    
    private func fetchCounters(filter: InterfaceFilter, targetInterface: String) -> NetworkCounters {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: Int = 0
        guard sysctl(&mib, 6, nil, &len, nil, 0) == 0, len > 0 else { return NetworkCounters() }
        
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: len, alignment: MemoryLayout<Int>.alignment)
        defer { buffer.deallocate() }
        
        guard sysctl(&mib, 6, buffer, &len, nil, 0) == 0 else { return NetworkCounters() }
        
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var targetFoundIn: UInt64 = 0
        var targetFoundOut: UInt64 = 0
        var matchedTarget = false
        
        var cursor = buffer
        let limit = buffer.advanced(by: len)
        
        while cursor < limit {
            let msgHdr = cursor.assumingMemoryBound(to: if_msghdr.self).pointee
            let nextCursor = cursor.advanced(by: Int(msgHdr.ifm_msglen))
            
            if msgHdr.ifm_type == RTM_IFINFO2 {
                let msgHdr2 = cursor.assumingMemoryBound(to: if_msghdr2.self).pointee
                let flags = Int32(msgHdr2.ifm_flags)
                let isUp = (flags & IFF_UP) != 0 && (flags & IFF_RUNNING) != 0
                let isLoopback = (flags & IFF_LOOPBACK) != 0
                
                if isUp && !isLoopback {
                    let sdlPtr = cursor.advanced(by: MemoryLayout<if_msghdr2>.stride).assumingMemoryBound(to: sockaddr_dl.self)
                    let sdl = sdlPtr.pointee
                    var ifName = ""
                    if sdl.sdl_nlen > 0 {
                        withUnsafePointer(to: sdl.sdl_data) { ptr in
                            let bytePtr = UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
                            ifName = String(decoding: UnsafeBufferPointer(start: bytePtr, count: Int(sdl.sdl_nlen)), as: UTF8.self)
                        }
                    }
                    
                    let ib = msgHdr2.ifm_data.ifi_ibytes
                    let ob = msgHdr2.ifm_data.ifi_obytes
                    
                    totalIn += ib
                    totalOut += ob
                    
                    if filter == .auto && ifName == targetInterface {
                        targetFoundIn = ib
                        targetFoundOut = ob
                        matchedTarget = true
                    }
                }
            }
            cursor = nextCursor
        }
        
        if filter == .auto && matchedTarget {
            return NetworkCounters(inBytes: targetFoundIn, outBytes: targetFoundOut)
        }
        
        return NetworkCounters(inBytes: totalIn, outBytes: totalOut)
    }
    
    private func fetchIPAddress(for ifaceName: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let name = String(cString: ptr.pointee.ifa_name)
            if name == ifaceName {
                let addr = ptr.pointee.ifa_addr.pointee
                if addr.sa_family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        return String(cString: hostname)
                    }
                }
            }
        }
        return nil
    }
}

