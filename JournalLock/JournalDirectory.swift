import Foundation

/// Utility to manage the folder where journal entries are stored.
/// The location is persisted in UserDefaults so it can be changed at runtime
/// from the UI and remembered across launches.
enum JournalDirectory {
    private static let bookmarkKey = "journalDirectoryBookmark2"
    private static var cachedURL: URL?

    /// Returns the currently configured directory for journal entries. If a
    /// security-scoped bookmark is stored we resolve it and start accessing the
    /// resource (only once per launch). Otherwise we fall back to the legacy
    /// path `~/JournalEntries` inside the user's home folder.
    static func get() -> URL {
        if let cachedURL { return cachedURL }

        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: bookmarkKey) {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: data,
                                  options: [.withSecurityScope],
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &stale) {
                if url.startAccessingSecurityScopedResource() {
                    cachedURL = url
                    // Refresh the bookmark if it became stale
                    if stale { set(url) }
                    return url
                }
            }
        }

        // Fallback – no bookmark yet
        let fallback = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("JournalEntries", isDirectory: true)
        cachedURL = fallback
        return fallback
    }

    /// Persists a new directory for journal entries using a security-scoped
    /// bookmark so the sandbox remembers the permission across launches.
    static func set(_ url: URL) {
        // Stop access to any previous URL
        cachedURL?.stopAccessingSecurityScopedResource()

        if let data = try? url.bookmarkData(options: [.withSecurityScope],
                                           includingResourceValuesForKeys: nil,
                                           relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        }

        cachedURL = url
        _ = url.startAccessingSecurityScopedResource()
    }
} 