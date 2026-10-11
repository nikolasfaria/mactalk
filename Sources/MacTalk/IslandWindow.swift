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
    /// Width of the camera housing on notched Macs; the island keeps clear of it. 0 when there is no notch.
    @Published var notchWidth: CGFloat = 0
}

/// The island. On notched Macs it wraps the camera housing with a wing on each side, so nothing is drawn under the camera.
/// Elsewhere it is a centred pill at the top of the screen. It floats above the menu bar and never takes focus.
@MainActor
final class IslandWindow {
    private static let wingWidth: CGFloat = 170
    private static let pillSize = NSSize(width: 300, height: 36)

    private let model = IslandModel()
    private var hideWork: DispatchWorkItem?

    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.pillSize),
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
        let geometry = Self.geometry(for: screen)
        model.notchWidth = geometry.notchWidth
        panel.setFrame(geometry.frame, display: true)
    }

    /// Notched screen: a strip the height of the menu bar, spanning the notch plus a wing on each side.
    /// Other screens: a centred pill at the top edge.
    private static func geometry(for screen: NSScreen) -> (frame: NSRect, notchWidth: CGFloat) {
        let inset = screen.safeAreaInsets.top
        if inset > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            let notchWidth = max(0, screen.frame.width - left.width - right.width)
            let width = notchWidth + 2 * wingWidth
            let frame = NSRect(x: screen.frame.midX - width / 2, y: screen.frame.maxY - inset, width: width, height: inset)
            return (frame, notchWidth)
        }
        let frame = NSRect(x: screen.frame.midX - pillSize.width / 2, y: screen.frame.maxY - pillSize.height,
                           width: pillSize.width, height: pillSize.height)
        return (frame, 0)
    }
}

private struct IslandView: View {
    @ObservedObject var model: IslandModel

    var body: some View {
        HStack(spacing: 0) {
            leftWing
            Color.clear.frame(width: model.notchWidth)
            rightWing
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            UnevenRoundedRectangle(bottomLeadingRadius: 16, bottomTrailingRadius: 16)
                .fill(.black)
        )
        .opacity(model.state == .hidden ? 0 : 1)
        .scaleEffect(model.state == .hidden ? 0.9 : 1, anchor: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.state)
    }

    /// Orb sits right next to the notch on notched Macs, and at the centre of a pill otherwise.
    private var leftWing: some View {
        HStack {
            Spacer(minLength: 0)
            if let orb {
                ThinkingOrb(state: orb, size: .px20, theme: .dark)
            }
        }
        .padding(.trailing, 12)
        .frame(width: wing)
    }

    private var rightWing: some View {
        HStack {
            if let label {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 12)
        .frame(width: wing)
    }

    /// Wing width; the notched layout uses the same wing as the pill's halves.
    private var wing: CGFloat { 170 }

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
