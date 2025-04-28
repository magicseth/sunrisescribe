import SwiftUI
import AppKit


enum JournalSaver {
    static func save(yesterday: String, today: String) {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let dir = FileManager.default.homeDirectoryForCurrentUser
                   .appendingPathComponent("JournalEntries")
        try? FileManager.default.createDirectory(at: dir,
                      withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(df.string(from: .now)).txt")

        let content = """
        ## Yesterday
        \(yesterday)

        ## Today
        \(today)
        """

        try? content.write(to: file, atomically: true, encoding: .utf8)

    }
}

final class JournalWindowController: NSWindowController {
    private var hostingController: NSHostingController<AnyView>!
    // Add a counter to force ContentView recreation
    private var viewResetCounter = 0
    
    // Store the content when deferred
    private var savedYesterdayText = ""
    private var savedTodayText = ""

    init() {
        // 1️⃣  Make the hosting controller generic over AnyView
        let host = NSHostingController(rootView: AnyView(EmptyView()))
        self.hostingController = host

        // 2️⃣  Build the window
        let win = JournalWindow(contentViewController: host)
        win.styleMask = [.fullSizeContentView, .titled]
        win.titleVisibility = .hidden
        win.collectionBehavior = [.fullScreenPrimary, .canJoinAllSpaces]
        win.level = .mainMenu + 1
        win.isReleasedWhenClosed = false
        win.styleMask.insert([.resizable, .titled, .fullSizeContentView])


        super.init(window: win)            // ✅ self is now fully initialised

        // 3️⃣  Now we can capture `self`
        refreshContentView()
    }
    
    private func refreshContentView() {
        // Increment counter to force SwiftUI to create a completely new ContentView
        viewResetCounter += 1
        
        // Use the ID parameter to force a new instance with fresh state
        hostingController.rootView = AnyView(
            ContentView(
                initialYesterday: savedYesterdayText,
                initialToday: savedTodayText,
                onSave: { [weak self] (yesterday: String, today: String) in
                    JournalSaver.save(yesterday: yesterday, today: today)
                    self?.hideAndRelax()
                    self?.close()
                },
                onDefer: { [weak self] (yesterday: String, today: String) in
                    // Save the current text when deferring
                    self?.savedYesterdayText = yesterday
                    self?.savedTodayText = today
                    self?.hideAndRelax()
                    self?.close()
                }
            )
            .id(viewResetCounter) // This forces SwiftUI to create a completely new view instance
        )
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
    private var escMonitor: Any?          // ← new

    func show() {
        guard let win = window else { return }
        
        // Reset the ContentView to ensure the timer is reset, but preserve text fields
        refreshContentView()
        
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { ev in
            // ⌘-Q is already blocked; here we stop plain Esc and ⌘-.
            if ev.keyCode == kVK_Escape { return nil }
            if ev.keyCode == kVK_ANSI_Period && ev.modifierFlags.contains(.command) {
                return nil
            }
            return ev        // pass everything else through
        }


        // 1️⃣ Become a 'real' app so kiosk flags are honoured
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)

        // 2️⃣ Apply kiosk presentation flags
        NSApp.presentationOptions = [
            .disableProcessSwitching,     // ⌘-Tab / Mission Control
            .disableForceQuit,            // ⌥⌘⎋
            .disableHideApplication,
            .autoHideDock,
            .autoHideMenuBar
        ]

        // 3️⃣ Display the window full-screen
        win.makeKeyAndOrderFront(nil)
        if !win.isZoomed { win.toggleFullScreen(nil) }
    }

    /// Called by ContentView's "Save" button
    func hideAndRelax() {
        guard let win = window else { return }

        // 1️⃣ Drop kiosk restrictions
        NSApp.presentationOptions = []

        // 2️⃣ Hide window
        win.orderOut(nil)

        // 3️⃣ Return to accessory (no Dock / Cmd-Tab icon)
        NSApp.setActivationPolicy(.accessory)
    }
}
import Carbon.HIToolbox   // for kVK_Tab
