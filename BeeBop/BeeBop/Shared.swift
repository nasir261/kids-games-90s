import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: – CGFloat clamping
// Was duplicated privately in BreakoutView and PongView; now shared.

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: – Haptics
// Lightweight tactile feedback. Kept gentle (no hard "error" buzz) since
// these games are for 5–6 year-olds — losing a point/life shouldn't feel
// like punishment.

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func impact() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    /// Soft "heads up" feedback for losing a life/round — warning, not error.
    static func failure() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}

// MARK: – Shared "Tap to Play" button
// Was reimplemented per-file as overlayButton()/actionButton()/startButton().

struct PrimaryGameButton: View {
    let label: String
    var color: Color = .yellow
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 30)
                .padding(.vertical, 14)
                .background(color)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: – Shared result card (game over / win)
// Was reimplemented per-file as resultOverlay()/gameOverOverlay()/winOverlay().

struct GameResultCard: View {
    let title: String
    var titleColor: Color = .yellow
    let subtitle: String
    let buttonLabel: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(titleColor)
            Text(subtitle)
                .font(.system(size: 20, design: .monospaced))
                .foregroundColor(.white)
            PrimaryGameButton(label: buttonLabel, color: .yellow, action: action)
        }
        .padding(22)
        .background(Color.black.opacity(0.78))
        .cornerRadius(18)
    }
}

// MARK: – Shared pause button + overlay
// New: none of the games had a pause option before, which is rough for
// young kids who need a snack/bathroom break mid-round.

struct PauseButton: View {
    @Binding var isPaused: Bool

    var body: some View {
        Button {
            Haptics.tap()
            isPaused.toggle()
        } label: {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPaused ? "Resume" : "Pause")
    }
}

struct PauseOverlay: View {
    let resume: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("⏸️ Paused")
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            PrimaryGameButton(label: "Resume ▶️", color: .green, action: resume)
        }
        .padding(24)
        .background(Color.black.opacity(0.8))
        .cornerRadius(18)
    }
}
