import AVFoundation
import Combine
import Foundation

/// Glue between the ⌘E hotkey, the mic, Parakeet, the island and the paste step.
@MainActor
final class DictationController: ObservableObject {
    enum Phase: Equatable {
        case idle, listening, transcribing
    }

    @Published private(set) var phase: Phase = .idle

    private let settings: AppSettings
    private let hotkey = GlobalHotkey()
    private let recorder = AudioRecorder()
    private let recognizer = Recognizer()
    private let island = IslandWindow()
    private var cancellables = Set<AnyCancellable>()

    /// Shorter presses are accidental taps, not dictation.
    private let minimumSamples = 16_000 / 3

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        hotkey.onPress = { [weak self] in MainActor.assumeIsolated { self?.keyDown() } }
        hotkey.onRelease = { [weak self] in MainActor.assumeIsolated { self?.keyUp() } }

        // Combine emits the new value in willSet, so use the emitted values rather than re-reading settings.
        settings.$dictationEnabled
            .combineLatest(settings.$shortcut)
            .sink { [weak self] enabled, shortcut in
                guard let self else { return }
                if enabled {
                    self.hotkey.register(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers)
                } else {
                    self.hotkey.unregister()
                }
            }
            .store(in: &cancellables)

        if SpeechModel.isInstalled { recognizer.preload() }
    }

    private func keyDown() {
        switch settings.mode {
        case .toggle:
            if phase == .listening { finish() } else { begin() }
        case .hold:
            begin()
        }
    }

    private func keyUp() {
        if settings.mode == .hold { finish() }
    }

    private func begin() {
        guard phase == .idle else { return }
        guard SpeechModel.isInstalled else {
            island.flash(String(localized: "Download the speech model in Settings"))
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            startRecording()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                Task { @MainActor in
                    if granted { self.startRecording() } else { self.island.flash(String(localized: "Allow the microphone in System Settings")) }
                }
            }
        default:
            island.flash(String(localized: "Allow the microphone in System Settings"))
        }
    }

    private func startRecording() {
        do {
            try recorder.start(deviceUID: settings.microphoneUID)
            phase = .listening
            island.show(.listening)
        } catch {
            island.flash(String(localized: "Microphone unavailable"))
        }
    }

    private func finish() {
        guard phase == .listening else { return }
        let samples = recorder.stop()

        guard samples.count >= minimumSamples else {
            phase = .idle
            island.hide()
            return
        }

        phase = .transcribing
        island.show(.transcribing)

        Task {
            let text = await recognizer.transcribe(samples)
            phase = .idle
            island.hide()
            guard !text.isEmpty else { return }

            let pasted = TextInserter.insert(text + " ", paste: settings.autoPaste)
            if !pasted {
                island.flash(String(localized: "Copied. Paste with ⌘V"), seconds: 3)
            }
        }
    }
}
