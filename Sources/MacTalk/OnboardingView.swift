import AVFoundation
import SwiftUI

/// First-run window. Downloads the speech model automatically and asks for permissions.
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var downloader: ModelDownloader
    @State private var micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    @State private var accessibilityTrusted = TextInserter.isAccessibilityTrusted
    @State private var modelInstalled = SpeechModel.isInstalled
    var onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to MacTalk")
                    .font(.system(size: 26, weight: .semibold))
                Text("Dictate anywhere on your Mac. Speech is recognized on this Mac, not in the cloud.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            step(number: 1, title: "Speech model", subtitle: "Parakeet TDT v3 · about 640 MB, downloaded once.") {
                if modelInstalled {
                    Label("Ready", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                } else if downloader.isBusy {
                    HStack(spacing: 8) {
                        ProgressView(value: downloader.progress).frame(width: 140)
                        Text(downloader.phase == .verifying ? "Verifying…" : "\(Int(downloader.progress * 100))%")
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Retry download") { downloader.download() }
                }
            }

            step(number: 2, title: "Microphone", subtitle: "MacTalk only listens while the shortcut is active.") {
                if micStatus == .authorized {
                    Label("Allowed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    Button("Allow microphone") {
                        AVCaptureDevice.requestAccess(for: .audio) { _ in
                            Task { @MainActor in micStatus = AVCaptureDevice.authorizationStatus(for: .audio) }
                        }
                    }
                }
            }

            step(number: 3, title: "Auto-paste", subtitle: "Optional. Lets MacTalk paste the text for you. Otherwise it is copied.") {
                if accessibilityTrusted {
                    Label("Allowed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    Button("Allow accessibility") { TextInserter.requestAccessibility() }
                }
            }

            Divider().opacity(0.4)

            HStack {
                Text("Shortcut: \(settings.shortcut.display) to start, \(settings.shortcut.display) again to stop.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Start using MacTalk") {
                    onFinish()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!modelInstalled)
            }
        }
        .padding(32)
        .frame(width: 620)
        .background(Color(white: 0.055))
        .preferredColorScheme(.dark)
        .onAppear {
            if !SpeechModel.isInstalled { downloader.download() }
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
        .onChange(of: downloader.phase) { _, _ in refresh() }
    }

    private func refresh() {
        micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        accessibilityTrusted = TextInserter.isAccessibilityTrusted
        modelInstalled = SpeechModel.isInstalled
    }

    private func step<Trailing: View>(
        number: Int,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text("\(number)")
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(0.1)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .medium))
                Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            trailing()
        }
    }
}
