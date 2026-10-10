import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var onboardingWindow: NSWindow?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !AppSettings.onboardingCompleted {
            showOnboarding()
        }
    }

    @MainActor
    private func showOnboarding() {
        let view = OnboardingView(onFinish: { [weak self] in
            AppSettings.onboardingCompleted = true
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        })
        .environmentObject(AppModel.shared)
        .environmentObject(AppModel.shared.settings)
        .environmentObject(AppModel.shared.downloader)

        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = String(localized: "Welcome to MacTalk")
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }
}
