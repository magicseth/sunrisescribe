import SwiftUI
import AppKit

/// A multi-line editor that lets Tab / Shift-Tab switch focus like a normal form.
struct TabbableTextEditor: NSViewRepresentable {
    @Binding var text: String
    let focusID: FocusID                          // identifies this editor
    let focusBinding: FocusState<FocusID?>.Binding

    enum FocusID { case yesterday, today }

    // MARK: – NSViewRepresentable
    func makeNSView(context: Context) -> NSTextView {
        let textView = TabbableNSTextView()
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.delegate = context.coordinator
        textView.string = text
        textView.enclosingScrollView?.hasHorizontalScroller = false

        // Give the key-loop a place to go next/previous
        textView.nextKeyView = nil    // will be wired automatically by SwiftUI

        // Store our own identifier
        textView.focusID = focusID
        textView.focusBinding = focusBinding
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.string != text { nsView.string = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: – Coordinator for NSTextViewDelegate
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TabbableTextEditor
        init(_ parent: TabbableTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }
}

// ---------------------------------------------------------------------------
//  MARK:  Private NSTextView subclass
// ---------------------------------------------------------------------------

private final class TabbableNSTextView: NSTextView {

    // These are injected from makeNSView
    fileprivate var focusID: TabbableTextEditor.FocusID?
    fileprivate var focusBinding: FocusState<TabbableTextEditor.FocusID?>.Binding?

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == kVK_Tab else {      // use Carbon constant
            super.keyDown(with: event)
            return
        }

        // 1. Switch SwiftUI focus binding
        if let id = focusID, let binding = focusBinding {
            binding.wrappedValue = event.modifierFlags.contains(.shift) ?
                                   previous(of: id) :
                                   next(of: id)
        }

        // 2. Hop the AppKit key-view ring so NSResponder chain stays happy
        if event.modifierFlags.contains(.shift) {
            window?.selectPreviousKeyView(self)
        } else {
            window?.selectNextKeyView(self)
        }
    }

    private func next(of id: TabbableTextEditor.FocusID)
                     -> TabbableTextEditor.FocusID {
        id == .yesterday ? .today : .yesterday
    }
    private func previous(of id: TabbableTextEditor.FocusID)
                         -> TabbableTextEditor.FocusID {
        next(of: id)     // only two fields, so next == previous
    }
}

import Carbon.HIToolbox   // for kVK_Tab
