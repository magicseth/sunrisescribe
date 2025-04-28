import Cocoa
import SwiftUI
import ServiceManagement
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
