import SwiftUI
import AppKit

/// A multi-line editor that lets Tab / Shift-Tab switch focus like a normal form.
struct TabbableTextEditor: NSViewRepresentable {
    @Binding var text: String
    let focusID: FocusID                          // identifies this editor
    let focusBinding: FocusState<FocusID?>.Binding
    var minHeight: CGFloat = 100                  // Default minimum height

    enum FocusID { case yesterday, today }

    // MARK: – NSViewRepresentable
    func makeNSView(context: Context) -> NSScrollView {
        // Create the text view with frame to ensure proper initialization
        let textView = TabbableNSTextView(frame: NSRect(x: 0, y: 0, width: 100, height: minHeight))
        
        // Configure basic text settings
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        
        // Use dynamic colors that adapt to system appearance
        if #available(macOS 10.14, *) {
            textView.textColor = .labelColor
            textView.backgroundColor = .textBackgroundColor
        } else {
            textView.textColor = .textColor
            textView.backgroundColor = .textBackgroundColor
        }
        
        textView.drawsBackground = true
        textView.delegate = context.coordinator
        textView.string = text
        
        // Set up minimum height constraints
        textView.minSize = NSSize(width: 0, height: minHeight)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        
        // Enable proper text wrapping
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 5
        textView.layoutManager?.allowsNonContiguousLayout = true
        
        // Create and configure the scroll view
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 100, height: minHeight))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height] // Make it resize with parent
        
        // Ensure proper text wrapping
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.textContainer?.size = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        
        // Fix text wrapping and visualization
        textView.isHorizontallyResizable = false
        
        // Update the view to use the full width
        let contentWidth = scrollView.contentSize.width
        textView.frame.size.width = contentWidth
        textView.textContainer?.containerSize = NSSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
        
        // Use dynamic background color for scroll view
        if #available(macOS 10.14, *) {
            scrollView.backgroundColor = .windowBackgroundColor
        } else {
            scrollView.backgroundColor = .controlBackgroundColor
        }
        
        // Text container setup
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        
        // Connect text view to scroll view
        scrollView.documentView = textView
        
        // Give the key-loop a place to go next/previous
        textView.nextKeyView = nil    // will be wired automatically by SwiftUI
        
        // Store our own identifier
        textView.focusID = focusID
        textView.focusBinding = focusBinding
        
        // Make the scroll view pass on clicks to the text view
        scrollView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollViewFrameChanged(_:)),
            name: NSView.frameDidChangeNotification,
            object: scrollView
        )
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text { textView.string = text }
        textView.minSize = NSSize(width: 0, height: minHeight)
        
        // Update text container width to match scroll view width
        textView.textContainer?.size = NSSize(
            width: nsView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        
        // Ensure focus state is correctly reflected
        if let textView = nsView.documentView as? TabbableNSTextView {
            if focusBinding.wrappedValue == focusID {
                if nsView.window?.firstResponder != textView {
                    nsView.window?.makeFirstResponder(textView)
                }
            }
        }
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
        
        func textDidBeginEditing(_ notification: Notification) {
            guard let tv = notification.object as? TabbableNSTextView else { return }
            
            // Update focus when editing begins
            if let id = tv.focusID, let binding = tv.focusBinding {
                binding.wrappedValue = id
            }
        }
        
        @objc func scrollViewFrameChanged(_ notification: Notification) {
            guard let scrollView = notification.object as? NSScrollView,
                  let textView = scrollView.documentView as? TabbableNSTextView else { return }
            
            // Ensure text container width matches scroll view width
            textView.textContainer?.containerSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
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

    // Disable any special handling that might interfere with normal clicks
    override var acceptsFirstResponder: Bool { return true }
    
    // Ensure we properly process mouse events
    override func mouseDown(with event: NSEvent) {
        // Set ourselves as first responder before handling the click
        if let window = window, window.firstResponder != self {
            window.makeFirstResponder(self)
        }
        
        // Now let the regular mouseDown handle it
        super.mouseDown(with: event)
        
        // Update SwiftUI focus binding as well
        if let id = focusID, let binding = focusBinding {
            binding.wrappedValue = id
        }
    }

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
        if let window = self.window {
            if event.modifierFlags.contains(.shift) {
                window.selectPreviousKeyView(self)
            } else {
                window.selectNextKeyView(self)
            }
        }
    }
    
    // Override to update SwiftUI focus state when this view becomes first responder
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        
        // Update SwiftUI focus binding when we become first responder
        if result, let id = focusID, let binding = focusBinding {
            DispatchQueue.main.async {
                binding.wrappedValue = id
            }
        }
        
        return result
    }
    
    // Handle click activation
    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        if result == self {
            // If we're being clicked, ensure we update focus state
            if let id = focusID, let binding = focusBinding {
                DispatchQueue.main.async {
                    binding.wrappedValue = id
                }
            }
        }
        return result
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
