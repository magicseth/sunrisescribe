import Cocoa
import SwiftUI
import ServiceManagement

// 1️⃣  Runs all the unlock logic
final class AppDelegate: NSObject, NSApplicationDelegate {

    private lazy var journalWindow = JournalWindowController()

    func applicationDidFinishLaunching(_ note: Notification) {
        // At boot
        showIfNeeded()

        // Every unlock thereafter
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleUnlock),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil)

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleUnlock),
            name: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil)
    }

    @objc private func handleUnlock(_ n: Notification) { showIfNeeded() }

    private func showIfNeeded() {
        guard todaysEntryMissing() else { return }
        journalWindow.show()          // full-screen SwiftUI window
    }

    private func todaysEntryMissing() -> Bool {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let path = FileManager.default.homeDirectoryForCurrentUser
                  .appendingPathComponent("JournalEntries/\(df.string(from: .now)).txt").path
        return !FileManager.default.fileExists(atPath: path)
    }
}
