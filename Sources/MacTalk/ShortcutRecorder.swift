import AppKit
import Carbon.HIToolbox

/// Captures the next key combination pressed while the Settings window is focused.
@MainActor
final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    private var monitor: Any?

    func toggle(onRecord: @escaping (Shortcut) -> Void) {
        isRecording ? stop() : start(onRecord: onRecord)
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    private func start(onRecord: @escaping (Shortcut) -> Void) {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            // Esc cancels.
            if event.keyCode == UInt16(kVK_Escape) {
                self.stop()
                return nil
            }

            let modifiers = Shortcut.carbonModifiers(from: event.modifierFlags.intersection(.deviceIndependentFlagsMask))
            let label = (event.charactersIgnoringModifiers ?? "").uppercased()

            // Require a modifier and a single letter or digit, so typing in other fields still works.
            guard modifiers != 0, label.count == 1, let scalar = label.unicodeScalars.first,
                  CharacterSet.alphanumerics.contains(scalar) else {
                return nil
            }

            onRecord(Shortcut(keyCode: Int(event.keyCode), modifiers: modifiers, keyLabel: label))
            self.stop()
            return nil
        }
    }
}
