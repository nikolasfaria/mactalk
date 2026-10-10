import AppKit
import Carbon.HIToolbox
import Foundation
import SwiftUI

enum DictationMode: String, CaseIterable, Identifiable {
    case toggle, hold

    var id: String { rawValue }
    var label: LocalizedStringKey { self == .toggle ? "Toggle" : "Hold" }
}

/// A global shortcut as Carbon sees it: a virtual key code plus Carbon modifier bits.
struct Shortcut: Equatable {
    var keyCode: Int
    var modifiers: Int
    var keyLabel: String

    /// Default: ⌃E. The user can record any other combination in Settings.
    static let `default` = Shortcut(keyCode: kVK_ANSI_E, modifiers: controlKey, keyLabel: "E")

    /// e.g. "⌃E", "⌥⇧D"
    var display: String {
        var s = ""
        if modifiers & controlKey != 0 { s += "⌃" }
        if modifiers & optionKey != 0 { s += "⌥" }
        if modifiers & shiftKey != 0 { s += "⇧" }
        if modifiers & cmdKey != 0 { s += "⌘" }
        return s + keyLabel
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var result = 0
        if flags.contains(.command) { result |= cmdKey }
        if flags.contains(.control) { result |= controlKey }
        if flags.contains(.option) { result |= optionKey }
        if flags.contains(.shift) { result |= shiftKey }
        return result
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private static let defaults = UserDefaults.standard
    private let defaults = AppSettings.defaults

    /// False until the first-run window has been finished.
    static var onboardingCompleted: Bool {
        get { defaults.bool(forKey: "onboardingCompleted") }
        set { defaults.set(newValue, forKey: "onboardingCompleted") }
    }

    @Published var dictationEnabled: Bool {
        didSet { defaults.set(dictationEnabled, forKey: "dictationEnabled") }
    }
    @Published var mode: DictationMode {
        didSet { defaults.set(mode.rawValue, forKey: "dictationMode") }
    }
    @Published var shortcut: Shortcut {
        didSet {
            defaults.set(shortcut.keyCode, forKey: "shortcutKeyCode")
            defaults.set(shortcut.modifiers, forKey: "shortcutModifiers")
            defaults.set(shortcut.keyLabel, forKey: "shortcutKeyLabel")
        }
    }
    /// Paste the transcription automatically when dictation stops. Off = only copy to the clipboard.
    @Published var autoPaste: Bool {
        didSet { defaults.set(autoPaste, forKey: "autoPaste") }
    }
    /// CoreAudio UID of the input device. Empty means the system default.
    @Published var microphoneUID: String {
        didSet { defaults.set(microphoneUID, forKey: "microphoneUID") }
    }

    init() {
        dictationEnabled = defaults.object(forKey: "dictationEnabled") as? Bool ?? true
        mode = DictationMode(rawValue: defaults.string(forKey: "dictationMode") ?? "") ?? .toggle
        autoPaste = defaults.object(forKey: "autoPaste") as? Bool ?? true
        microphoneUID = defaults.string(forKey: "microphoneUID") ?? ""

        if let keyCode = defaults.object(forKey: "shortcutKeyCode") as? Int,
           let modifiers = defaults.object(forKey: "shortcutModifiers") as? Int,
           let label = defaults.string(forKey: "shortcutKeyLabel") {
            shortcut = Shortcut(keyCode: keyCode, modifiers: modifiers, keyLabel: label)
        } else {
            shortcut = .default
        }
    }
}
