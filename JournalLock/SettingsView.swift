import SwiftUI
import Foundation
import ServiceManagement

struct SettingsView: View {
    @AppStorage("journalTimeoutSeconds") private var timeoutSeconds: Int = 30
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = true
    @State private var journalPath: String = "Loading..."
    
    private let timeoutOptions = [10, 15, 30, 45, 60, 120]
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    private let supportEmail = "sunrise@magicseth.com"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sunrise Scribe Settings")
                .font(.headline)
                .padding(.bottom, 5)
            
            GroupBox("Timer Settings") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Journal Skip Timeout:", selection: $timeoutSeconds) {
                        ForEach(timeoutOptions, id: \.self) { seconds in
                            Text("\(seconds) seconds").tag(seconds)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text("This setting controls how long to wait before enabling the 'Skip for now' button.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
            
            GroupBox("Launch Settings") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            if newValue {
                                enableLoginItem()
                            } else {
                                disableLoginItem() 
                            }
                        }
                    
                    Text("When enabled, Sunrise Scribe will start automatically when you log in to your Mac.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
            
            GroupBox("Journal Location") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Journal entries will be saved in your Documents folder. To change this location, use the 'Save As' dialog when first saving a journal entry.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
            
            GroupBox("About") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Version:")
                            .bold()
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                    }
                    
                    HStack {
                        Text("Support:")
                            .bold()
                        Spacer()
                        Link(supportEmail, destination: URL(string: "mailto:\(supportEmail)")!)
                    }
                }
                .padding(.vertical, 5)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 400)
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

#Preview {
    SettingsView()
} 