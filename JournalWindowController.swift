import SwiftUI
import AppKit


enum JournalSaver {
    static func save(yesterday: String, today: String) {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let dir = JournalDirectory.get()
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

        // Reveal in Finder
        NSWorkspace.shared.activateFileViewerSelecting([file])
    }
}

final class JournalWindowController: NSWindowController {
    private var hostingController: NSHostingController<AnyView>!
    // Add a counter to force ContentView recreation
    private var viewResetCounter = 0
    
    // Store the content when deferred
    private var savedYesterdayText = ""
    private var savedTodayText = ""
    private var savedDate: String? // Track the date associated with cached text

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private func currentDateString() -> String {
        dateFormatter.string(from: .now)
    }

    init() {
        // 1️⃣  Make the hosting controller generic over AnyView
        let host = NSHostingController(rootView: AnyView(EmptyView()))
        self.hostingController = host

        // 2️⃣  Build the window
        let win = JournalWindow(contentViewController: host)
        win.title = "Sunrise Scribe"
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
        // If the cached text is from a previous day, reset it
        if savedDate != currentDateString() {
            savedYesterdayText = ""
            savedTodayText = ""
            savedDate = currentDateString()
        }

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
                    guard let self = self else { return }
                    self.savedYesterdayText = yesterday
                    self.savedTodayText = today
                    self.savedDate = self.currentDateString()
                    self.hideAndRelax()
                    self.close()
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
        
        // Load any existing entry of the day so the user can keep editing
        populateFromTodaysEntry()
        
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

    // Loads today's entry from disk (if present) so that the next call to `show()`
    // will present the existing contents for editing.
    func populateFromTodaysEntry() {
        // First ensure cache isn't stale
        if savedDate != currentDateString() {
            savedYesterdayText = ""
            savedTodayText = ""
        }

        let fileURL = JournalDirectory.get().appendingPathComponent("\(currentDateString()).txt")
        // If the file doesn't exist (or cannot be read) we leave the cached
        // text as-is – this supports the "Skip for now" flow where the user may
        // relaunch later to continue writing the deferred entry.
        guard let raw = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return
        }

        // Split the file at the "## Today" marker
        // Expected format:
        // ## Yesterday\n<yesterday>\n\n## Today\n<today>
        let components = raw.components(separatedBy: "## Today")
        if components.count == 2 {
            // Remove the leading "## Yesterday" header and trim whitespace
            let yesterdaySection = components[0]
                .replacingOccurrences(of: "## Yesterday", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let todaySection = components[1]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            savedYesterdayText = yesterdaySection
            savedTodayText = todaySection
            savedDate = currentDateString()
        } else {
            // Fallback – treat whole file as a single blob in the today field
            savedYesterdayText = ""
            savedTodayText = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            savedDate = currentDateString()
        }
    }

    func showWindowed() {
        guard let win = window else { return }
        populateFromTodaysEntry()
        refreshContentView()
        // Ensure we are a regular app and focused
        if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
        NSApp.activate(ignoringOtherApps: true)
        // Remove any kiosk options
        NSApp.presentationOptions = []
        // Show the window (not full-screen)
        win.makeKeyAndOrderFront(nil)
        // Lower the window level so it behaves like a normal app window
        win.level = .normal
        // If the window is currently in full-screen, exit that mode
        if win.styleMask.contains(.fullScreen) {
            win.toggleFullScreen(nil)
        }

        // Give it a sensible size and centre it
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame.insetBy(dx: 100, dy: 100)
            win.setFrame(frame, display: true, animate: true)
            win.center()
        }
    }
}
import Carbon.HIToolbox   // for kVK_Tab
