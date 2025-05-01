import SwiftUI
import ServiceManagement
import Cocoa // For NSApp
import Foundation

struct SetupWizard: View {
    @AppStorage("hascompletedsetup8") private var hasCompletedSetup: Bool = false
    @AppStorage("journalTimeoutSeconds") private var timeoutSeconds: Int = 30
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = true
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage = 0
    private let timeoutOptions = [10, 15, 30, 45, 60, 120]
    @State private var wizardWindow: NSWindow?
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)]), 
                           startPoint: .topLeading, 
                           endPoint: .bottomTrailing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            // Content
            VStack {
                // Header
                Text("Welcome to Sunrise Scribe")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Text("Let's set up your preferences")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 40)
                
                // Pages
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    welcomePage
                        .tag(0)
                    
                    // Page 2: Timeout setting
                    timeoutPage
                        .tag(1)
                    
                    // Page 3: Launch at login
                    launchAtLoginPage
                        .tag(2)
                    
                    // Page 4: All set
                    completionPage
                        .tag(3)
                }
                .tabViewStyle(.automatic)
                .frame(height: 300)
                
                // Page indicators
                HStack {
                    ForEach(0..<4) { page in
                        Circle()
                            .fill(currentPage == page ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 10)
                
                // Navigation buttons
                HStack {
                    Button(action: {
                        withAnimation {
                            currentPage = max(0, currentPage - 1)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(8)
                    }
                    .opacity(currentPage > 0 ? 1 : 0)
                    .disabled(currentPage == 0)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            if currentPage < 3 {
                                currentPage += 1
                            } else {
                                completeSetup()
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage < 3 ? "Next" : "Get Started")
                            Image(systemName: currentPage < 3 ? "arrow.right" : "checkmark")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                // Capture reference to the window showing the wizard
                if let win = NSApp.keyWindow {
                    wizardWindow = win
                }
                ensureRegularApp()
            }
        }
    }
    
    /// Make sure the application shows up in Cmd-Tab / Dock while the setup wizard is onscreen.
    private func ensureRegularApp() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private var welcomePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .padding()
            
            Text("Start each day with reflection")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Sunrise Scribe helps you build a daily journaling habit by prompting you at the start of each day.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 60)
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(16)
        .padding()
    }
    
    private var timeoutPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .padding()
            
            Text("Set your skip timeout")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("How long should the 'Skip for now' button be disabled when the journal appears?")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 40)
            
            Picker("Timeout duration", selection: $timeoutSeconds) {
                ForEach(timeoutOptions, id: \.self) { seconds in
                    Text("\(seconds) seconds").tag(seconds)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
            
            Text("This encourages you to pause and reflect before skipping.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(16)
        .padding()
    }
    
    private var launchAtLoginPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard.macwindow")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .padding()
            
            Text("Launch at login")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Would you like Sunrise Scribe to automatically launch when you log in to your Mac?")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 40)
            
            Toggle("Launch at login", isOn: $launchAtLogin)
                .padding(.horizontal, 100)
                .toggleStyle(.switch)
                .foregroundColor(.white)
            
            Text("You can change this later in the app settings.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(16)
        .padding()
    }
    
    private var completionPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding()
            
            Text("You're all set!")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Your preferences have been saved. Sunrise Scribe will help you build a consistent journaling habit.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "timer")
                    Text("Skip timeout: \(timeoutSeconds) seconds")
                }
                
                HStack {
                    Image(systemName: "keyboard.macwindow")
                    Text("Launch at login: \(launchAtLogin ? "Enabled" : "Disabled")")
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(16)
        .padding()
    }
    
    private func completeSetup() {
        // Set login item based on user preference
        if launchAtLogin {
            enableLoginItem()
        } else {
            disableLoginItem()
        }
        
        // Mark setup as completed
         hasCompletedSetup = true
        
        // Close the window and enable kiosk mode for journal
        DispatchQueue.main.async {
            dismiss()
            // Close the wizard window to avoid blank window lingering
            wizardWindow?.close()
            
            // Enable kiosk mode for the journal window
            let opts: NSApplication.PresentationOptions = [
                .disableForceQuit,
                .disableProcessSwitching,
                .disableSessionTermination,
                .disableHideApplication,
                .autoHideDock,
                .autoHideMenuBar
            ]
            NSApp.presentationOptions = opts
            
            // Show journal window or terminate
            DistributedNotificationCenter.default().post(name: .init("SunriseScribeShowJournal"), object: nil)
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
    
    private func enableLoginItem() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to register login item: \(error)")
        }
    }
    
    private func disableLoginItem() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("Failed to unregister login item: \(error)")
        }
    }
}

struct SetupWizard_Previews: PreviewProvider {
    static var previews: some View {
        SetupWizard()
    }
} 
