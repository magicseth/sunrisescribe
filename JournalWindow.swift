// JournalWindow.swift
import AppKit
import SwiftUI

/// Full-screen window that ignores the Escape key.
final class JournalWindow: NSWindow {

    /// 1. Prevent leaving full-screen
    override func cancelOperation(_ sender: Any?) {
        /* do nothing – swallow Esc / Cmd-. */
    }

    /// 2. Prevent AppKit’s fallback ESC handling
    override func keyDown(with event: NSEvent) {
        if event.keyCode == kVK_Escape { return }   // ignore
        super.keyDown(with: event)
    }
}
import Carbon.HIToolbox   // for kVK_Tab
