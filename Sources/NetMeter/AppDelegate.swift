import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        MenuBarController.shared.setup()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        // Clean shutdown
    }
}

