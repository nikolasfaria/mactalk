import AppKit
import ServiceManagement
import SwiftUI

enum SettingsTab {
    case voice, about
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .voice
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var downloader: ModelDownloader
    @StateObject private var recorder = ShortcutRecorder()
    @State private var inputs: [InputDevice] = []
    @State private var accessibilityTrusted = TextInserter.isAccessibilityTrusted
    @State private var modelInstalled = SpeechModel.isInstalled
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().opacity(0.4)
            content
        }
        .frame(width: 860, height: 620)
        .background(Color(white: 0.055))
        .preferredColorScheme(.dark)
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
        .onChange(of: downloader.phase) { _, _ in refresh() }
        .onDisappear { recorder.stop() }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("MacTalk: launch at login change failed: \(error.localizedDescription)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func refresh() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
        inputs = AudioDevices.inputs()
        accessibilityTrusted = TextInserter.isAccessibilityTrusted
        modelInstalled = SpeechModel.isInstalled
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 44)
                .padding(.bottom, 14)

            Text("CAPABILITIES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.bottom, 6)

            sidebarItem(.voice, icon: "mic.fill", title: "Voice")
            sidebarItem(.about, icon: "info.circle", title: "About")

            Spacer()
        }
        .frame(width: 220)
        .background(Color.white.opacity(0.02))
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .voice: voiceContent
        case .about:
            ScrollView { AboutView() }
        }
    }

    private func sidebarItem(_ tab: SettingsTab, icon: String, title: LocalizedStringKey) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).frame(width: 16)
                Text(title).font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(selectedTab == tab ? 0.08 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    private var voiceContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Voice")
                    .font(.system(size: 26, weight: .semibold))
                Text("Local speech-to-text dictation with on-device models.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .padding(.bottom, 26)

                VStack(spacing: 0) {
                    row(title: "Enable Voice Dictation",
                        subtitle: "Press \(settings.shortcut.display) to dictate text into any focused field.") {
                        Toggle("", isOn: $settings.dictationEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    Divider().opacity(0.5)

                    row(title: "Open at login",
                        subtitle: "Start MacTalk automatically when you log in to your Mac.") {
                        Toggle("", isOn: Binding(get: { launchAtLogin }, set: setLaunchAtLogin))
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    Divider().opacity(0.5)

                    row(title: "Shortcut",
                        subtitle: "Click the button, then press the new shortcut. Press Esc to cancel.") {
                        Button(recorder.isRecording ? "Press keys…" : settings.shortcut.display) {
                            recorder.toggle { settings.shortcut = $0 }
                        }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .frame(minWidth: 110)
                    }
                    Divider().opacity(0.5)

                    row(title: "Dictation Mode",
                        subtitle: "Toggle: press the shortcut to start, press it again to stop. Hold: dictate while the shortcut is held.") {
                        Picker("", selection: $settings.mode) {
                            ForEach(DictationMode.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 160)
                    }
                    Divider().opacity(0.5)

                    row(title: "Paste automatically",
                        subtitle: "When you stop, the text is pasted where your cursor is.") {
                        Toggle("", isOn: $settings.autoPaste)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    Divider().opacity(0.5)

                    row(title: "Microphone",
                        subtitle: "Input device used for voice dictation. System default follows the OS microphone setting.") {
                        Picker("", selection: $settings.microphoneUID) {
                            Text("System default").tag("")
                            ForEach(inputs) { Text($0.name).tag($0.uid) }
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }
                    Divider().opacity(0.5)

                    row(title: "Speech Model",
                        subtitle: "Parakeet TDT v3 · Recognizes 25 European languages, with punctuation and capitalization.",
                        footer: modelFooter) {
                        modelControl
                    }
                    Divider().opacity(0.5)

                    row(title: "Accessibility",
                        subtitle: "Needed to paste automatically. Without it, text is copied to the clipboard.") {
                        if accessibilityTrusted {
                            Label("Granted", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 12, weight: .medium))
                        } else {
                            Button("Grant access") {
                                TextInserter.requestAccessibility()
                            }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.035))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
                )
            }
            .padding(36)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var modelControl: some View {
        if downloader.isBusy {
            HStack(spacing: 10) {
                ProgressView(value: downloader.progress)
                    .frame(width: 120)
                Text(downloader.phase == .verifying ? "Verifying…" : "\(Int(downloader.progress * 100))%")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.secondary)
                Button("Cancel") { downloader.cancel() }
            }
        } else if modelInstalled {
            HStack(spacing: 12) {
                Label("Installed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 12, weight: .medium))
                Button("Remove") {
                    try? SpeechModel.remove()
                    refresh()
                }
            }
        } else {
            HStack(spacing: 12) {
                Button("Use existing model…") {
                    downloader.importExisting()
                }
                Button("Download (≈640 MB)") {
                    downloader.download()
                }
            }
        }
    }

    private var modelFooter: String? {
        if case .failed(let message) = downloader.phase { return message }
        return nil
    }

    private func row<Trailing: View>(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        footer: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let footer {
                    Text(verbatim: footer).font(.system(size: 12)).foregroundStyle(.red)
                }
            }
            Spacer(minLength: 12)
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
