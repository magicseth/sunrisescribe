import SwiftUI

struct ContentView: View {
    let onSave: (_ yesterday: String, _ today: String) -> Void

    @State private var yesterdayText = ""
    @State private var todayText     = ""

    var body: some View {
        // 1️⃣  GeometryReader gives us the screen size
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 32) {
                    Text("Good morning!")
                        .font(.largeTitle.weight(.bold))

                    GroupBox("What happened **yesterday**?") {
                        TextEditor(text: $yesterdayText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                    }

                    GroupBox("Your hopes & dreams for **today**:") {
                        TextEditor(text: $todayText)
                            .scrollContentBackground(.hidden)
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
    }
}
