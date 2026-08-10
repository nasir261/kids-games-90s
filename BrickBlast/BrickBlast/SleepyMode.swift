import SwiftUI

/// Global "Sleepy Mode" toggle. When on, a game session gradually winds down
/// after a calm period, then ends gently — dimming visuals, slowing motion,
/// hiding the score, and softening music — so kids naturally stop playing
/// instead of a hard cutoff.
final class SleepyMode: ObservableObject {
    static let shared = SleepyMode()

    @Published private(set) var isEnabled = false

    private init() {}

    func toggle() {
        isEnabled.toggle()
        MusicPlayer.shared.setDuckingScale(1)
    }

    /// How long a session plays normally before winding down.
    static let calmDuration: TimeInterval = 5 * 60
    /// How long the wind-down ramp lasts once calmDuration has passed
    /// (gameplay ends naturally ~7.5 minutes later — the middle of the
    /// requested 5–10 minute range).
    static let windDownDuration: TimeInterval = 7.5 * 60
    static var endAfter: TimeInterval { calmDuration + windDownDuration }

    /// 0 while calm, ramping linearly to 1 by the time the session should end.
    static func progress(elapsed: TimeInterval) -> Double {
        guard elapsed > calmDuration else { return 0 }
        return min(1, max(0, (elapsed - calmDuration) / windDownDuration))
    }

    static func hasEnded(elapsed: TimeInterval) -> Bool {
        elapsed >= endAfter
    }
}

/// Drives a single game session's elapsed time and derived wind-down values.
/// Each game view owns one of these (created fresh per game, not shared).
/// The countdown persists across "Play Again" restarts within the same
/// session — only `reset()` (used by the "Wake Up" button) starts it over.
final class SleepySession: ObservableObject {
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var hasEnded = false
    private var timer: Timer?

    /// 0 while calm, ramping to 1 as the session winds down.
    var progress: Double { SleepyMode.progress(elapsed: elapsed) }
    /// Slows game motion up to 65% by the time the session ends.
    var speedMultiplier: Double { 1 - progress * 0.65 }
    /// Fully hidden once winding down has begun at all.
    var shouldHideScore: Bool { progress > 0 }

    /// Call at the start of every round. Safe to call repeatedly — it only
    /// begins counting once, and lets an already-running countdown continue.
    func start() {
        guard SleepyMode.shared.isEnabled, timer == nil else { return }
        elapsed = 0
        hasEnded = false
        scheduleTimer()
    }

    /// Fully restarts the wind-down countdown (used by "Wake Up").
    func reset() {
        stop()
        start()
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsed += 1
            MusicPlayer.shared.setDuckingScale(Float(1 - self.progress * 0.7))
            if SleepyMode.hasEnded(elapsed: self.elapsed) {
                self.hasEnded = true
                self.timer?.invalidate()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        MusicPlayer.shared.setDuckingScale(1)
    }
}

/// Moon toggle button shown in each game's header, next to the mute button.
struct SleepyModeButton: View {
    @ObservedObject private var sleepy = SleepyMode.shared

    var body: some View {
        Button {
            sleepy.toggle()
            Haptics.tap()
        } label: {
            Image(systemName: sleepy.isEnabled ? "moon.stars.fill" : "moon.stars")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sleepy.isEnabled ? "Turn off Sleepy Mode" : "Turn on Sleepy Mode")
    }
}

/// Full-screen darkening scrim that eases in as a session winds down.
struct SleepyOverlay: View {
    let progress: Double

    var body: some View {
        Color.black.opacity(progress * 0.75)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 1), value: progress)
    }
}

/// Simple 4-digit passcode gate so only a grown-up can dismiss the
/// "Goodnight" screen and let a wound-down session keep playing. The
/// passcode is stored on-device and changeable from the parent settings screen.
enum ParentalGate {
    private static let key = "parentalPasscode"
    private static let defaultPasscode = "1234"

    static var passcode: String {
        get { UserDefaults.standard.string(forKey: key) ?? defaultPasscode }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

struct ParentalGateSheet: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var entry = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 16) {
            Text("👪 Grown-up Check")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text("Enter the parent passcode to keep playing.")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            SecureField("Passcode", text: $entry)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .padding(12)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .foregroundColor(.white)
                .frame(width: 160)

            if showError {
                Text("That's not right — ask a grown-up for help.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.red)
            }

            HStack(spacing: 14) {
                PrimaryGameButton(label: "Cancel", color: .gray, action: onCancel)
                PrimaryGameButton(label: "Unlock 🔓", color: .green) {
                    if entry == ParentalGate.passcode {
                        entry = ""
                        showError = false
                        onSuccess()
                    } else {
                        showError = true
                    }
                }
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.92))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}

/// Shown once a wound-down session reaches its natural end. "Wake Up"
/// requires the parental passcode before gameplay can resume.
struct GoodnightCard: View {
    let action: () -> Void
    @State private var showGate = false

    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                Text("😴 Goodnight!")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Time to rest. Sweet dreams! 🌙")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                PrimaryGameButton(label: "Wake Up ☀️", color: .yellow) {
                    showGate = true
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.85))
            .cornerRadius(20)

            if showGate {
                ParentalGateSheet(
                    onSuccess: {
                        showGate = false
                        action()
                    },
                    onCancel: { showGate = false }
                )
            }
        }
    }
}

/// Lets a grown-up set a new parental passcode.
struct ParentalSettingsSheet: View {
    let onDone: () -> Void

    @State private var newCode = ""
    @State private var confirmCode = ""
    @State private var message: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("👪 Parent Settings")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text("Set a new 4-digit passcode used to wake up from Sleepy Mode.")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            SecureField("New passcode", text: $newCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .padding(10)
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
                .foregroundColor(.white)
                .frame(width: 180)

            SecureField("Confirm passcode", text: $confirmCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .padding(10)
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
                .foregroundColor(.white)
                .frame(width: 180)

            if let message {
                Text(message)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 14) {
                PrimaryGameButton(label: "Cancel", color: .gray, action: onDone)
                PrimaryGameButton(label: "Save 💾", color: .green) {
                    guard newCode.count == 4, newCode.allSatisfy(\.isNumber) else {
                        message = "Passcode must be 4 digits."
                        return
                    }
                    guard newCode == confirmCode else {
                        message = "Passcodes don't match."
                        return
                    }
                    ParentalGate.passcode = newCode
                    onDone()
                }
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.92))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}

/// Gear button shown in each game's header. Requires the current passcode
/// before letting a parent set a new one.
struct ParentalSettingsButton: View {
    @State private var showGate = false
    @State private var showSettings = false

    var body: some View {
        Button {
            showGate = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Parent Settings")
        .sheet(isPresented: $showGate) {
            ZStack {
                Color.black.ignoresSafeArea()
                ParentalGateSheet(
                    onSuccess: {
                        showGate = false
                        showSettings = true
                    },
                    onCancel: { showGate = false }
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            ZStack {
                Color.black.ignoresSafeArea()
                ParentalSettingsSheet(onDone: { showSettings = false })
            }
        }
    }
}
