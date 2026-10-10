import AppKit
import ApplicationServices

/// Pastes text into whatever field has focus: copy, ⌘V, then restore the old clipboard.
/// Posting ⌘V to other apps needs Accessibility. Without it, or with auto-paste off, the text stays on the clipboard.
@MainActor
enum TextInserter {
    private static let keyV: CGKeyCode = 9

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// macOS only shows its prompt once per app, so also open the Accessibility pane where the user can enable MacTalk.
    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Returns false when the text was only copied (auto-paste off, or no Accessibility permission).
    @discardableResult
    static func insert(_ text: String, paste: Bool) -> Bool {
        let pasteboard = NSPasteboard.general
        let previous = pasteboard.string(forType: .string)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard paste, isAccessibilityTrusted else { return false }

        let source = CGEventSource(stateID: .combinedSessionState)
        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: keyV, keyDown: keyDown)
            event?.flags = .maskCommand
            event?.post(tap: .cgAnnotatedSessionEventTap)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let previous, pasteboard.string(forType: .string) == text else { return }
            pasteboard.clearContents()
            pasteboard.setString(previous, forType: .string)
        }
        return true
    }
}
