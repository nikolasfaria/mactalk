import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    let settings = AppSettings()
    let downloader = ModelDownloader()
    let dictation: DictationController

    private init() {
        dictation = DictationController(settings: settings)
        dictation.start()
    }
}

@main
struct MacTalkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var app = AppModel.shared

    var body: some Scene {
        MenuBarExtra("MacTalk", systemImage: "mic.fill") {
            MenuContent(settings: app.settings)
        }
        .menuBarExtraStyle(.menu)

        Window("MacTalk Settings", id: "settings") {
            SettingsView()
                .environmentObject(app)
                .environmentObject(app.settings)
                .environmentObject(app.downloader)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

private struct MenuContent: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Voice Dictation (\(settings.shortcut.display))", isOn: $settings.dictationEnabled)

        Divider()

        Button("Settings…") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit MacTalk") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
