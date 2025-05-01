import SwiftUI
import ServiceManagement
import Cocoa

@main
struct JournalLockApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("hascompletedsetup10") private var hasCompletedSetup: Bool = false

    // Directory that will hold YYYY-MM-DD.txt files
    private let journalDir: URL = {
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docPath.appendingPathComponent("SunriseScribeEntries", isDirectory: true)
    }()
    
    // Reference to the AppDelegate
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        // Print the actual directory path for debugging
        print("Journal entries will be saved to: \(journalDir.path)")
        
        // Only register autolaunch if setup is completed
        if hasCompletedSetup {
            registerAsLoginItem()             // auto-launch at login
            
            if todaysEntryExists() {          // already wrote today?
                // Quit immediately – nothing to do
//                DispatchQueue.main.async { NSApp.terminate(nil) }
            }
            
            // Only enable kiosk mode if setup is completed
            enableKioskMode()
        }
        createFolderIfNeeded()
    }

    // watch hasCompletedSetup, and call init if it changes
    


    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasCompletedSetup {
                    SetupWizardWrapper()
                } else {
                    WindowCloser()
                }
            }
            .animation(.easeInOut, value: hasCompletedSetup)
            .onChange(of: hasCompletedSetup) { completed in
                 guard completed else { return }
                if let win = NSApp.keyWindow { win.close() }

                 // Perform tasks deferred until setup finishes
                 registerAsLoginItem()
                 enableKioskMode()
                 // Show the journal just in case wizard didn't
//                 if let delegate = NSApp.delegate as? AppDelegate {
//                     delegate.showJournal()
//                 }
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        
        Settings {
            SettingsView()
        }
    }
}

// Wrapper view to handle setup completion
struct SetupWizardWrapper: View {
    @AppStorage("hascompletedsetup10") private var hasCompletedSetup: Bool = false
    @State private var showSetupWizard = true
    
    var body: some View {
        Group {
            if showSetupWizard {
                SetupWizard()
                    .onDisappear {
                        // If setup was completed, we need to hide the wizard and close its window
                        if hasCompletedSetup {
                            showSetupWizard = false
                            if let win = NSApp.keyWindow { win.close() }
                        }
                    }
            } else {
                EmptyView()
            }
        }
    }
    
    private func todaysEntryExists() -> Bool {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: .now)
        let fm = FileManager.default
        let docPath = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let journalFolder = docPath.appendingPathComponent("SunriseScribeEntries", isDirectory: true)
        let file = journalFolder.appendingPathComponent("\(today).txt")
        return fm.fileExists(atPath: file.path)
    }
}

// App state to be shared across the app
class AppState: ObservableObject {
    @Published var showJournalWindow: Bool = false
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

struct WindowCloser: View {
    var body: some View {
        Color.clear.frame(width: 1, height: 1).onAppear {
            if let win = NSApp.keyWindow { win.close() }
        }
    }
}
