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

    init() {
        // 1️⃣  Make the hosting controller generic over AnyView
        let host = NSHostingController(rootView: AnyView(EmptyView()))

        // 2️⃣  Build the window
        let win = NSWindow(contentViewController: host)
        win.styleMask = [.fullSizeContentView, .titled]
        win.titleVisibility = .hidden
        win.collectionBehavior = [.fullScreenPrimary, .canJoinAllSpaces]
        win.level = .mainMenu + 1
        win.isReleasedWhenClosed = false
        win.styleMask.insert([.resizable, .titled, .fullSizeContentView])


        super.init(window: win)            // ✅ self is now fully initialised

        // 3️⃣  Now we can capture `self`
        host.rootView = AnyView(ContentView { [weak self] y, t in
            JournalSaver.save(yesterday: y, today: t)
            self?.hideAndRelax()

            self?.close()
        })
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }

    func show() {
        guard let win = window else { return }

        // 1️⃣ Become a ‘real’ app so kiosk flags are honoured
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

    /// Called by ContentView’s “Save” button
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
