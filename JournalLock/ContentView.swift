import SwiftUI
import AppKit
// Provide visibility of JournalDirectory for Swift Playground
// (module-level linking should already expose, but this ensures same compilation unit.)

struct ContentView: View {
    let onSave: (_ yesterday: String, _ today: String) -> Void
    let onDefer: (_ yesterday: String, _ today: String) -> Void
    @FocusState private var focus: TabbableTextEditor.FocusID?

    @State private var yesterdayText: String
    @State private var todayText: String
    @State private var secondsRemaining = 30
    @State private var timer: Timer?
    @State private var chosenDirectory: URL = JournalDirectory.get()
    
    // Initialize with optional initial values
    init(
        initialYesterday: String = "", 
        initialToday: String = "", 
        onSave: @escaping (_ yesterday: String, _ today: String) -> Void,
        onDefer: @escaping (_ yesterday: String, _ today: String) -> Void
    ) {
        self.onSave = onSave
        self.onDefer = onDefer
        // Use _yesterdayText and _todayText to initialize @State properties
        self._yesterdayText = State(initialValue: initialYesterday)
        self._todayText = State(initialValue: initialToday)
    }

    var body: some View {
        // 1️⃣  GeometryReader gives us the screen size
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 32) {
                    Text("Good morning!")
                        .font(.largeTitle.weight(.bold))

                    GroupBox("What happened **yesterday**?") {
                        TabbableTextEditor(
                               text: $yesterdayText,
                               focusID: .yesterday,
                               focusBinding: $focus
                           )
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)

                    GroupBox("Your hopes & dreams for **today**:") {
                        TabbableTextEditor(
                            text: $todayText,
                            focusID: .today,
                            focusBinding: $focus
                        )
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)

                    Button("Save and start the day") {
                        onSave(
                            yesterdayText.trimmingCharacters(in: .whitespacesAndNewlines),
                            todayText.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(yesterdayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              todayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(secondsRemaining > 0 ? "Skip for now (\(secondsRemaining)s)" : "Skip for now") {
                        onDefer(yesterdayText, todayText)
                    }
                    .disabled(secondsRemaining > 0)

                    Button("Change Folder…") {
                        chooseFolder()
                    }
                    .buttonStyle(.link)
                    .padding(.top, 4)

                    // Display the currently-selected folder in a subtle caption
                    Text(chosenDirectory.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                // 2️⃣  centre the content but cap its width for readability
                .frame(maxWidth: min(geo.size.width * 0.9, 700))
                .padding(.top, 60)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        // 3️⃣  colour the *entire* full-screen space
        .background(Color(NSColor.windowBackgroundColor))
        .ignoresSafeArea()           // ← crucial: extend into system areas
        .onAppear { 
            focus = .yesterday
            startTimer()
        }   // start in first field
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private func chooseFolder() {
        guard let window = NSApp.keyWindow else { return }

        // 1️⃣  Temporarily clear kiosk presentation so the sheet is visible
        let previousOpts = NSApp.presentationOptions
        NSApp.presentationOptions = []

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = chosenDirectory
        panel.prompt = "Choose"

        panel.beginSheetModal(for: window) { response in
            if response == .OK, let url = panel.url {
                chosenDirectory = url
                JournalDirectory.set(url)
            }

            // 2️⃣  Restore kiosk flags
            NSApp.presentationOptions = previousOpts
        }
    }
}
