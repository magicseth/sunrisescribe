# Sunrise Scribe (JournalLock)

Sunrise Scribe is a macOS menubar/login‐item that gently locks your screen each morning (and whenever you unlock your Mac) until you jot down **two quick journal entries:**

1. **Yesterday** – What happened? What did you learn?
2. **Today** – What are your intentions, hopes & dreams?

It is designed to build a sustainable daily reflection habit while keeping **all of your data 100 % offline and under your sole control.**

---

## ✨ Features

- **Full-screen, distraction-free UI** built with SwiftUI.
- **Auto-launch at login** and **re-appears on every screen unlock** until today's entry is saved.
- **Kiosk mode** – disables ⌘-Tab, Force-Quit, Dock & menu bar to keep you focused.
- **Two-pane editor** with Tab ⇥ / Shift-Tab ⇤ navigation.
- **Skip for now** button (unlocks after a 30 s countdown) for the occasional busy morning.
- **Custom storage location** – default `~/JournalEntries` folder, but you can pick any directory (including iCloud Drive, Dropbox, external disk, etc.).
- **Plain-text Markdown** files named `YYYY-MM-DD.txt`, so your entries are future-proof and portable.
- **Security-scoped bookmarks** remember folder permissions across launches.
- **Offline-first & privacy-first** – the app has zero network code. Your words never leave your Mac. (See [Privacy Policy](PRIVACY_POLICY.md).)

---

## 🏁 Quick Start

1. **Clone the repo**

   ```bash
   git clone https://github.com/your-username/JournalLock.git
   cd JournalLock
   ```

2. **Open in Xcode 15** (or newer) and hit `Run ▶︎`.

   The first build will create the helper login-item bundle automatically.

3. On first launch you will see the full-screen window. Type your entries and press **Save and start the day**.

4. Your note is saved to `~/JournalEntries/2025-04-29.txt` (example) and revealed in Finder.

5. Every subsequent Mac unlock will show the window until today's file exists.

> **Tip** – Click **Change Folder…** at the bottom-left to pick a different location (e.g. a synced cloud folder). The permission is securely stored using a sandbox security-scoped bookmark.

---

## 🛠️ Building from Source

The project is a standard Swift 5 / SwiftUI macOS app.

```text
macOS 14 Sonoma or later
Xcode 15 or later
Swift 5.9+
```

1. Open `JournalLock.xcodeproj` in Xcode.
2. Select the `JournalLock` scheme.
3. Build & run (`⌘R`).
4. (Optional) Run `⌘U` to execute the included unit/UI tests.

### Sandboxed Login Item

`ServiceManagement` is used to install *Sunrise Scribe Login Item*, a tiny helper that launches the main app at user login. Xcode signs both targets automatically when you use your own Team ID.

---

## 📂 File Format

Each entry is written in Markdown with two headings:

```markdown
## Yesterday
<your text>

## Today
<your text>
```

This makes it trivial to parse or migrate elsewhere later.

---

## 🔒 Privacy & Security

Sunrise Scribe contains **no analytics, no trackers, and no networking code whatsoever**. Everything you type is saved only to the folder you choose. Read the full [Privacy Policy](PRIVACY_POLICY.md) for details.

If you store journal files in iCloud Drive or another sync service, the usual cloud provider security rules apply.

---

## 🤝 Contributing

Pull requests and issues are welcome! If you have feature ideas, bug reports, or suggestions, feel free to open an issue or PR.

1. Fork the repo and create a feature branch.
2. Make your changes.
3. Run the tests (`⌘U`).
4. Submit a PR with a clear description.

---

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 👤 Author

Seth Raphael – [@magicseth](https://github.com/magicseth) – sunrise@magicseth.com

Happy journaling! ✍️ 