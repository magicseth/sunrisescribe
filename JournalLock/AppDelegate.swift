import Cocoa
import SwiftUI
import ServiceManagement

// 1️⃣  Runs all the unlock logic
final class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("hascompletedsetup8") private var hasCompletedSetup: Bool = false
    private lazy var journalWindow = JournalWindowController()

    func applicationDidFinishLaunching(_ note: Notification) {
        // At boot
    
        // Listen for explicit request from SetupWizard
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(showJournalNotification),
            name: .init("SunriseScribeShowJournal"),
            object: nil)
    
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
            if (hasCompletedSetup) {

                guard todaysEntryMissing() else { return }
                journalWindow.show()          // full-screen SwiftUI window
            }
    }

    private func todaysEntryMissing() -> Bool {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let file = JournalDirectory.get().appendingPathComponent("\(df.string(from: .now)).txt")
        return !FileManager.default.fileExists(atPath: file.path)
    }
    func applicationShouldTerminate(_ sender: NSApplication)
        -> NSApplication.TerminateReply
    {
         .terminateCancel     // block quit
        
    }

    // Invoked when the user opens the app again (e.g. via Spotlight) while it is already
    // running. This should always show the journal window so the current day's entry can
    // be reviewed or edited.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if (hasCompletedSetup) {
            journalWindow.show()
        }
            
        return true // we handled the reopen
    }

    /// Allows other parts of the app (e.g. SetupWizard) to show the journal window immediately.
    @objc func showJournal() {
        journalWindow.show()
    }

    @objc private func showJournalNotification(_ notification: Notification) {
        showJournal()
    }
}
