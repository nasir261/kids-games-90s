import SwiftUI

private struct Pipe: Identifiable {
    let id: Int
    var x: CGFloat
    let gapCenterY: CGFloat
    var passed = false
}

/// A gentle, 90s-style "flap to fly" game — an original take on the tap-to-flap
/// genre, starring a bee dodging flower-stem pipes instead of the usual bird/pipes.
struct BeeBopView: View {
    private let pipeWidth: CGFloat = 64
    private let pipeSpacing: CGFloat = 260
    private let beeX: CGFloat = 110
    private let beeSize: CGFloat = 44

    @ObservedObject private var center = GameCenter.shared
    @State private var showTutorial = !GameCenter.shared.hasSeenTutorial(for: .beeBop)
    @StateObject private var sleepySession = SleepySession()

    private var gravity: CGFloat {
        switch center.difficultyLevel(for: .beeBop) {
        case .easy:   return 0.32
        case .medium: return 0.44
        case .hard:   return 0.58
        }
    }
    private var flapImpulse: CGFloat {
        switch center.difficultyLevel(for: .beeBop) {
        case .easy:   return -7.2
        case .medium: return -8.0
        case .hard:   return -8.8
        }
    }
    private var pipeGap: CGFloat {
        switch center.difficultyLevel(for: .beeBop) {
        case .easy:   return 280
        case .medium: return 225
        case .hard:   return 180
        }
    }
    private var pipeSpeed: CGFloat {
        switch center.difficultyLevel(for: .beeBop) {
        case .easy:   return 2.4
        case .medium: return 3.2
        case .hard:   return 4.2
        }
    }

    @State private var beeY: CGFloat = 0
    @State private var beeVelocity: CGFloat = 0
    @State private var pipes: [Pipe] = []
    @State private var nextPipeID = 0
    @State private var score = 0
    @State private var isPlaying = false
    @State private var isPaused = false
    @State private var gameOver = false
    @State private var gameTimer: Timer?
    @State private var backgroundVariant = SleepyBackgroundVariant.allCases.randomElement()!
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar

                GeometryReader { geo in
                    gameCanvas(geo: geo)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active { backgroundVariant = SleepyBackgroundVariant.allCases.randomElement()! }
        }
        .onAppear {
            backgroundVariant = SleepyBackgroundVariant.allCases.randomElement()!
            MusicPlayer.shared.play(.beeBop)
        }
        .onDisappear {
            gameTimer?.invalidate()
            sleepySession.stop()
            MusicPlayer.shared.stop()
        }
    }

    // MARK: – Header

    private var headerBar: some View {
        HStack {
            Text("🐝 Sleepy Bee Bop")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Spacer()
            Text("Score: \(score)")
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .opacity(sleepySession.shouldHideScore ? 0 : 1)
            MusicMuteButton()
            SleepyModeButton()
            ParentalSettingsButton()
            if isPlaying {
                PauseButton(isPaused: $isPaused)
                    .padding(.leading, 6)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: – Canvas

    private func gameCanvas(geo: GeometryProxy) -> some View {
        let size = geo.size
        return ZStack {
            switch backgroundVariant {
            case .normal:
                Rectangle().fill(Color(red: 0.53, green: 0.81, blue: 0.92))
            case .alt:
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.6, blue: 0.4), Color(red: 0.4, green: 0.2, blue: 0.5)],
                    startPoint: .top, endPoint: .bottom
                )
            case .photo:
                SleepyPhotoBackgroundView()
            }

            // Pipes rendered as flower-stem columns (top + bottom).
            ForEach(pipes) { pipe in
                let topHeight = max(0, pipe.gapCenterY - pipeGap / 2)
                let bottomY = pipe.gapCenterY + pipeGap / 2
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green)
                    .frame(width: pipeWidth, height: topHeight)
                    .position(x: pipe.x, y: topHeight / 2)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green)
                    .frame(width: pipeWidth, height: max(0, size.height - bottomY))
                    .position(x: pipe.x, y: bottomY + max(0, size.height - bottomY) / 2)
            }

            // The bee. The 🐝 glyph faces left by default; mirror it to face
            // right, the direction it's actually flying through the pipes.
            Text("🐝")
                .font(.system(size: beeSize))
                .scaleEffect(x: -1, y: 1)
                .rotationEffect(.degrees(min(35, max(-30, Double(beeVelocity) * 3))))
                .position(x: beeX, y: beeY)

            if !isPlaying && !gameOver {
                VStack(spacing: 14) {
                    StarRatingView(stars: center.stars(for: .beeBop))
                    DifficultyPicker(game: .beeBop)
                    PrimaryGameButton(label: "Tap to Fly! 🐝") {
                        setup(size: size)
                        startGame(size: size)
                    }
                }
            }
            if gameOver {
                GameResultCard(
                    title: "😵 Ouch!", titleColor: .red,
                    subtitle: "Score: \(score)",
                    buttonLabel: "Try Again 🔄"
                ) { setup(size: size); startGame(size: size) }
            }
            if isPaused && isPlaying && !gameOver {
                PauseOverlay { isPaused = false }
            }
            SleepyOverlay(progress: sleepySession.progress)
            if sleepySession.hasEnded {
                GoodnightCard {
                    sleepySession.reset()
                    setup(size: size); startGame(size: size)
                }
            }
            if showTutorial {
                TutorialOverlay(
                    emoji: "🐝", title: "Sleepy Bee Bop",
                    instructions: "Tap anywhere to flap and fly.\nWeave through the flower stems.\nDon't hit them or the ground!"
                ) {
                    showTutorial = false
                    GameCenter.shared.markTutorialSeen(for: .beeBop)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isPlaying, !isPaused else { return }
            beeVelocity = flapImpulse
            Haptics.tap()
        }
        .onAppear { setup(size: size) }
        .onChange(of: size) { newSize in
            guard !isPlaying else { return }
            setup(size: newSize)
        }
    }

    // MARK: – Game logic

    private func setup(size: CGSize) {
        beeY = size.height / 2
        beeVelocity = 0
        nextPipeID = 0
        pipes = [
            Pipe(id: nextPipeID, x: size.width + 200, gapCenterY: size.height * 0.45),
        ]
        nextPipeID += 1
        score = 0
        gameOver = false
        isPlaying = false
        isPaused = false
    }

    private func startGame(size: CGSize) {
        isPlaying = true
        isPaused = false
        beeVelocity = flapImpulse / 1.4
        sleepySession.start()
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            updateGame(size: size)
        }
    }

    private func updateGame(size: CGSize) {
        guard isPlaying, !isPaused else { return }
        guard !sleepySession.hasEnded else {
            gameTimer?.invalidate()
            isPlaying = false
            return
        }
        let slow = sleepySession.speedMultiplier

        beeVelocity += gravity * slow
        beeY += beeVelocity * slow

        // Ground / ceiling collision.
        if beeY - beeSize / 2 <= 0 || beeY + beeSize / 2 >= size.height {
            endGame()
            return
        }

        // Move pipes and spawn new ones.
        for i in pipes.indices { pipes[i].x -= pipeSpeed * slow }
        pipes.removeAll { $0.x < -pipeWidth }

        if let last = pipes.last, size.width - last.x >= pipeSpacing {
            let gapCenter = CGFloat.random(in: size.height * 0.25 ... size.height * 0.75)
            pipes.append(Pipe(id: nextPipeID, x: size.width + pipeWidth, gapCenterY: gapCenter))
            nextPipeID += 1
        }

        // Collision + scoring.
        for i in pipes.indices {
            let pipe = pipes[i]
            let withinX = abs(pipe.x - beeX) < pipeWidth / 2 + beeSize / 2.4
            if withinX {
                let topHeight = pipe.gapCenterY - pipeGap / 2
                let bottomY = pipe.gapCenterY + pipeGap / 2
                if beeY - beeSize / 2.4 < topHeight || beeY + beeSize / 2.4 > bottomY {
                    endGame()
                    return
                }
            }
            if !pipe.passed, pipe.x + pipeWidth / 2 < beeX {
                pipes[i].passed = true
                score += 1
                Haptics.tap()
            }
        }
    }

    private func endGame() {
        gameTimer?.invalidate()
        isPlaying = false
        gameOver = true
        Haptics.failure()
        center.recordScore(score, thresholds: (5, 12, 20), for: .beeBop)
    }
}

#Preview {
    BeeBopView()
}
