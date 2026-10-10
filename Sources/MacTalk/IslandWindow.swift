import AppKit
import SwiftUI
import ThinkingOrbsKit

@MainActor
final class IslandModel: ObservableObject {
    enum State: Equatable {
        case hidden
        case listening
        case transcribing
        case message(String)
    }

    @Published var state: State = .hidden
}

/// The top-center "island" pill. Floats above the menu bar and never takes focus.
@MainActor
final class IslandWindow {
    private static let size = NSSize(width: 300, height: 36)

    private let model = IslandModel()
    private var hideWork: DispatchWorkItem?

    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.contentView = NSHostingView(rootView: IslandView(model: model))
        return panel
    }()

    func show(_ state: IslandModel.State) {
        hideWork?.cancel()
        model.state = state
        position()
        panel.orderFrontRegardless()
    }

    func hide() {
        model.state = .hidden
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.model.state == .hidden else { return }
            self.panel.orderOut(nil)
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func flash(_ text: String, seconds: Double = 2.5) {
        show(.message(text))
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            if case .message = self?.model.state { self?.hide() }
        }
    }

    private func position() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        // Top-aligned with the screen so it reads as part of the notch / menu bar.
        let origin = NSPoint(x: screen.frame.midX - Self.size.width / 2,
                             y: screen.frame.maxY - Self.size.height)
        panel.setFrame(NSRect(origin: origin, size: Self.size), display: true)
    }
}

private struct IslandView: View {
    @ObservedObject var model: IslandModel

    var body: some View {
        HStack(spacing: 10) {
            if let orb {
                ThinkingOrb(state: orb, size: .px20, theme: .dark)
            }
            if let label {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(
            UnevenRoundedRectangle(bottomLeadingRadius: 18, bottomTrailingRadius: 18)
                .fill(.black)
        )
        .opacity(model.state == .hidden ? 0 : 1)
        .scaleEffect(model.state == .hidden ? 0.9 : 1, anchor: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.state)
    }

    private var orb: OrbState? {
        switch model.state {
        case .listening: return .listening
        case .transcribing: return .solving
        case .hidden, .message: return nil
        }
    }

    private var label: String? {
        switch model.state {
        case .listening: return String(localized: "Dictating…")
        case .transcribing: return String(localized: "Transcribing…")
        case .message(let text): return text
        case .hidden: return nil
        }
    }
}
