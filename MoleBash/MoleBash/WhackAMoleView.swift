import SwiftUI

struct WhackAMoleView: View {
    private let holeCount = 9
    private let gameDuration = 30
    private let smashDisplayDuration: TimeInterval = 0.35 // was 0.25

    @ObservedObject private var center = GameCenter.shared
    @State private var showTutorial = !GameCenter.shared.hasSeenTutorial(for: .whackAMole)
    @StateObject private var sleepySession = SleepySession()

    private var moleVisibleDuration: TimeInterval {
        switch center.difficultyLevel(for: .whackAMole) {
        case .easy:   return 1.8
        case .medium: return 1.4
        case .hard:   return 1.0
        }
    }
    private var spawnInterval: TimeInterval {
        switch center.difficultyLevel(for: .whackAMole) {
        case .easy:   return 1.1
        case .medium: return 0.9
        case .hard:   return 0.65
        }
    }

    @State private var activeMoles: Set<Int> = []
    @State private var smashedMoles: Set<Int> = []
    @State private var score = 0
    @State private var timeLeft = 30
    @State private var isPlaying = false
    @State private var isPaused = false
    @State private var gameOver = false
    @State private var moleTimer: Timer?
    @State private var countdownTimer: Timer?
    // Bumped each time a game starts. Lets delayed async closures from a
    // previous round detect they're stale and bail out instead of mutating
    // the *new* round's mole/smash state (was a latent bug before).
    @State private var round = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.55, blue: 0.05), Color(red: 0.35, green: 0.75, blue: 0.15)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Text("🔨 Sleepy Mole Bash")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    if isPlaying && !gameOver {
                        Spacer()
                        PauseButton(isPaused: $isPaused)
                    }
                }
                .padding(.horizontal)

                HStack {
                    Label("\(score)", systemImage: "star.fill")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .opacity(sleepySession.shouldHideScore ? 0 : 1)
                    Spacer()
                    Label("\(timeLeft)s", systemImage: "clock.fill")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(timeLeft <= 5 ? .red : .white)
                        .opacity(sleepySession.shouldHideScore ? 0 : 1)
                    MusicMuteButton()
                    SleepyModeButton()
                    ParentalSettingsButton()
                }
                .padding(.horizontal)

                ZStack {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(0..<holeCount, id: \.self) { index in
                            MoleHole(
                                hasMole: activeMoles.contains(index),
                                isSmashed: smashedMoles.contains(index)
                            )
                            .onTapGesture { whack(index) }
                        }
                    }
                    .padding(.horizontal)

                    if isPaused && isPlaying && !gameOver {
                        PauseOverlay { isPaused = false }
                    }
                    SleepyOverlay(progress: sleepySession.progress)
                }

                if !isPlaying && !gameOver {
                    VStack(spacing: 14) {
                        StarRatingView(stars: center.stars(for: .whackAMole))
                        DifficultyPicker(game: .whackAMole)
                        PrimaryGameButton(label: "Start! 🔨", color: .brown) { startGame() }
                    }
                }

                if sleepySession.hasEnded {
                    GoodnightCard {
                        sleepySession.reset()
                        restartGame()
                    }
                } else if gameOver {
                    gameOverCard
                }

                Spacer()
            }
            .padding(.top)

            if showTutorial {
                TutorialOverlay(
                    emoji: "🔨", title: "Sleepy Mole Bash",
                    instructions: "Tap the moles 🦔 as soon as they pop up.\nBe quick — you only have 30 seconds!"
                ) {
                    showTutorial = false
                    GameCenter.shared.markTutorialSeen(for: .whackAMole)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { MusicPlayer.shared.play(.whackAMole) }
        .onDisappear {
            stopTimers()
            sleepySession.stop()
            MusicPlayer.shared.stop()
        }
    }

    // MARK: – Game Over card

    private var gameOverCard: some View {
        VStack(spacing: 12) {
            Text("⏰ Time's Up!")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Text("Score: \(score) 🌟")
                .font(.system(size: 22, design: .monospaced))
                .foregroundColor(.white)
            PrimaryGameButton(label: "Play Again 🔄", color: .brown) { restartGame() }
        }
        .padding(20)
        .background(Color.black.opacity(0.45))
        .cornerRadius(18)
        .padding(.horizontal)
    }

    // MARK: – Game logic

    private func startGame() {
        round += 1
        let currentRound = round

        score = 0
        timeLeft = gameDuration
        activeMoles = []
        smashedMoles = []
        isPlaying = true
        isPaused = false
        gameOver = false
        sleepySession.start()

        moleTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { _ in
            guard !isPaused else { return }
            spawnMole(round: currentRound)
        }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard !isPaused else { return }
            if sleepySession.hasEnded {
                endGame()
            } else if timeLeft > 0 {
                timeLeft -= 1
            } else {
                endGame()
            }
        }
    }

    private func restartGame() {
        stopTimers()
        startGame()
    }

    private func spawnMole(round spawnRound: Int) {
        let available = (0..<holeCount).filter { !activeMoles.contains($0) }
        guard let hole = available.randomElement() else { return }
        activeMoles.insert(hole)
        DispatchQueue.main.asyncAfter(deadline: .now() + moleVisibleDuration / sleepySession.speedMultiplier) {
            guard spawnRound == round else { return }
            activeMoles.remove(hole)
        }
    }

    private func whack(_ index: Int) {
        guard isPlaying, !isPaused, activeMoles.contains(index) else { return }
        let currentRound = round
        activeMoles.remove(index)
        smashedMoles.insert(index)
        score += 1
        Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + smashDisplayDuration) {
            guard currentRound == round else { return }
            smashedMoles.remove(index)
        }
    }

    private func endGame() {
        stopTimers()
        activeMoles = []
        isPlaying = false
        gameOver = true
        Haptics.tap()
        center.recordScore(score, thresholds: (10, 18, 26), for: .whackAMole)
    }

    private func stopTimers() {
        moleTimer?.invalidate()
        countdownTimer?.invalidate()
    }
}

// MARK: – Mole hole view

private struct MoleHole: View {
    let hasMole: Bool
    let isSmashed: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.3, green: 0.18, blue: 0.04))
                .frame(height: 95)

            if hasMole || isSmashed {
                Text(isSmashed ? "💫" : "🦔")
                    .font(.system(size: 54))
                    .offset(y: isSmashed ? -22 : 0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.5), value: isSmashed)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(height: 95)
        .animation(.spring(response: 0.25), value: hasMole)
        .accessibilityLabel(hasMole ? "Mole, tap to whack" : "Empty hole")
    }
}

#Preview {
    WhackAMoleView()
}
