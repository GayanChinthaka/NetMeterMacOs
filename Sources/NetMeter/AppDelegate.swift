import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        MenuBarController.shared.setup()
        observeSleepAndWake()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        // Clean shutdown
    }

    /// Nobody can see the menu bar while the displays sleep or the user session is
    /// switched out, so stop sampling until it is visible again.
    private func observeSleepAndWake() {
        let center = NSWorkspace.shared.notificationCenter
        let pauseNames: [Notification.Name] = [
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.willSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification
        ]
        let resumeNames: [Notification.Name] = [
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.didWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification
        ]
        for name in pauseNames {
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                NetworkMonitor.shared.pause()
            }
        }
        for name in resumeNames {
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                NetworkMonitor.shared.resume()
            }
        }
    }
}
