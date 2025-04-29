import SwiftUI
import ServiceManagement                  // 🟢 auto-launch API


@main
struct JournalLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Directory that will hold YYYY-MM-DD.txt files
    private let journalDir = JournalDirectory.get()

    init() {
        // Print the actual directory path for debugging
        print("Journal entries will be saved to: \(journalDir.path)")
        
        registerAsLoginItem()             // auto-launch at login
        if todaysEntryExists() {          // already wrote today?
            // Quit immediately – nothing to do
//            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
        createFolderIfNeeded()
        enableKioskMode()
    }

//    var body: some Scene {
//        WindowGroup { ContentView(onSave: save  ) }
//            // prevent close/zoom buttons
//            .windowResizability(.contentSize)
//            .commands { CommandGroup(replacing: .appTermination) { } }
//    }
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }

}



// MARK: – Launch at login
extension JournalLockApp {
    private func registerAsLoginItem() {
        do { try SMAppService.mainApp.register() }  // Ventura+
        catch { print("Could not register login item: \(error)") }
    }
}

// MARK: – Kiosk presentation
extension JournalLockApp {
    private func enableKioskMode() {
        let opts: NSApplication.PresentationOptions = [
            .disableForceQuit,
            .disableProcessSwitching,
            .disableSessionTermination,
            .disableHideApplication,
            .autoHideDock,
            .autoHideMenuBar
        ]

        DispatchQueue.main.async {
            NSApp?.presentationOptions = opts
        }
    }
}

// MARK: – Journal helpers
extension JournalLockApp {
    private func todaysFilename() -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return journalDir.appendingPathComponent("\(df.string(from: .now)).txt")
    }
    private func todaysEntryExists() -> Bool { FileManager.default.fileExists(atPath: todaysFilename().path) }
    private func createFolderIfNeeded() {
        try? FileManager.default.createDirectory(at: journalDir,
                                                 withIntermediateDirectories: true)
    }
    fileprivate func save(yesterday: String, today: String) {
        let content = """
        ## Reflections on \(Calendar.current.date(byAdding: .day, value: -1, to: .now)!.formatted(date: .long, time: .omitted))
        \(yesterday)

        ## Hopes & dreams for \(Date.now.formatted(date: .long, time: .omitted))
        \(today)
        """
        try? content.write(to: todaysFilename(), atomically: true, encoding: .utf8)
        
        // Log where the file was saved
        print("Journal entry saved to: \(todaysFilename().path)")

//        NSApp.terminate(nil)
    }
}
