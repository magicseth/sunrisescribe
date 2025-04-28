import SwiftUI

struct ContentView: View {
    let onSave: (_ yesterday: String, _ today: String) -> Void
    let onDefer: () -> Void
    @FocusState private var focus: TabbableTextEditor.FocusID?

    @State private var yesterdayText = ""
    @State private var todayText     = ""
    @State private var secondsRemaining = 30
    @State private var timer: Timer?

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
                           .frame(minHeight: 160)                    }

                    GroupBox("Your hopes & dreams for **today**:") {
                        TabbableTextEditor(
                            text: $todayText,
                            focusID: .today,
                            focusBinding: $focus
                        )
                        .frame(minHeight: 160)
                    }

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
                        onDefer()
                    }
                    .disabled(secondsRemaining > 0)
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
}
