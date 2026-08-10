import SwiftUI

struct PongView: View {
    private let paddleH: CGFloat = 14
    private let ballR: CGFloat = 9

    @ObservedObject private var center = GameCenter.shared
    @State private var showTutorial = !GameCenter.shared.hasSeenTutorial(for: .pong)
    @StateObject private var sleepySession = SleepySession()

    private var paddleW: CGFloat {
        switch center.difficultyLevel(for: .pong) {
        case .easy:   return 132
        case .medium: return 92
        case .hard:   return 58
        }
    }
    private var aiSpeedMax: CGFloat {
        switch center.difficultyLevel(for: .pong) {
        case .easy:   return 1.6
        case .medium: return 3.0
        case .hard:   return 5.6
        }
    }
    private var ballSpeed: CGFloat {
        switch center.difficultyLevel(for: .pong) {
        case .easy:   return 2.8
        case .medium: return 3.8
        case .hard:   return 5.4
        }
    }

    @State private var ballPos = CGPoint.zero
    @State private var ballVel = CGPoint.zero
    @State private var playerX: CGFloat = 0
    @State private var aiX: CGFloat = 0
    @State private var playerScore = 0
    @State private var aiScore = 0
    @State private var isPlaying = false
    @State private var isPaused = false
    @State private var gameTimer: Timer?

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
        .onAppear { MusicPlayer.shared.play(.pong) }
        .onChange(of: playerScore) { center.recordScore($0, thresholds: (3, 6, 10), for: .pong) }
        .onDisappear {
            gameTimer?.invalidate()
            sleepySession.stop()
            MusicPlayer.shared.stop()
        }
    }

    // MARK: – Header

    private var headerBar: some View {
        HStack {
            Text("🏓 Sleepy Paddle Bounce")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Spacer()
            Text("You \(playerScore)  –  \(aiScore) CPU")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
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
            Rectangle().fill(Color(white: 0.04))

            // Centre dashed line
            Path { p in
                p.move(to: CGPoint(x: size.width / 2, y: 0))
                p.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            }
            .stroke(Color.white.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 8]))

            // AI paddle (top)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red)
                .frame(width: paddleW, height: paddleH)
                .position(x: aiX, y: 32)

            // Player paddle (bottom)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 1.0, green: 0.92, blue: 0.1))  // brighter yellow than system .yellow, which reads brownish on black
                .frame(width: paddleW, height: paddleH)
                .position(x: playerX, y: size.height - 32)

            // Ball
            Circle()
                .fill(Color.white)
                .frame(width: ballR * 2, height: ballR * 2)
                .position(ballPos)

            if !isPlaying {
                VStack(spacing: 14) {
                    StarRatingView(stars: center.stars(for: .pong))
                    DifficultyPicker(game: .pong)
                    PrimaryGameButton(label: "Tap to Play! 🏓") {
                        resetBall(size: size)
                        startGame(size: size)
                    }
                }
            }
            if isPaused && isPlaying {
                PauseOverlay { isPaused = false }
            }
            SleepyOverlay(progress: sleepySession.progress)
            if sleepySession.hasEnded {
                GoodnightCard {
                    sleepySession.reset()
                    resetBall(size: size)
                    startGame(size: size)
                }
            }
            if showTutorial {
                TutorialOverlay(
                    emoji: "🏓", title: "Sleepy Paddle Bounce",
                    instructions: "Drag to move your paddle.\nBounce the ball back.\nDon't let it get past you!"
                ) {
                    showTutorial = false
                    GameCenter.shared.markTutorialSeen(for: .pong)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { val in
                    guard isPlaying, !isPaused else { return }
                    playerX = val.location.x.clamped(to: paddleW / 2 ... size.width - paddleW / 2)
                },
            including: isPlaying ? .all : .subviews
        )
        .onAppear { resetBall(size: size); playerX = size.width / 2; aiX = size.width / 2 }
        .onChange(of: size) { newSize in
            guard !isPlaying else { return }
            resetBall(size: newSize)
            playerX = newSize.width / 2
            aiX = newSize.width / 2
        }
    }

    // MARK: – Game logic

    private func resetBall(size: CGSize) {
        ballPos = CGPoint(x: size.width / 2, y: size.height / 2)
        let angle = Double.random(in: -0.35...0.35)
        ballVel = CGPoint(
            x: ballSpeed * CGFloat(sin(angle)),
            y: ballSpeed * (Bool.random() ? 1 : -1)
        )
    }

    private func startGame(size: CGSize) {
        isPlaying = true
        isPaused = false
        sleepySession.start()
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            updateGame(size: size)
        }
    }

    private func updateGame(size: CGSize) {
        guard !isPaused else { return }
        guard !sleepySession.hasEnded else {
            gameTimer?.invalidate()
            isPlaying = false
            return
        }
        let slow = sleepySession.speedMultiplier

        ballPos.x += ballVel.x * slow
        ballPos.y += ballVel.y * slow

        // Side walls
        if ballPos.x <= ballR || ballPos.x >= size.width - ballR {
            ballVel.x *= -1
            ballPos.x = ballPos.x.clamped(to: ballR ... size.width - ballR)
        }

        // AI tracks ball with speed cap
        let aiDiff = ballPos.x - aiX
        aiX += min(abs(aiDiff), aiSpeedMax * slow) * (aiDiff > 0 ? 1 : -1)
        aiX = aiX.clamped(to: paddleW / 2 ... size.width - paddleW / 2)

        // Player paddle collision (ball moving down)
        let playerPaddleY = size.height - 32
        if ballVel.y > 0,
           ballPos.y + ballR >= playerPaddleY - paddleH / 2,
           ballPos.y - ballR <= playerPaddleY + paddleH / 2,
           abs(ballPos.x - playerX) < paddleW / 2 + ballR {
            ballVel.y = -abs(ballVel.y)
            ballVel.x = ((ballPos.x - playerX) / (paddleW / 2)) * ballSpeed
            Haptics.impact()
        }

        // AI paddle collision (ball moving up)
        if ballVel.y < 0,
           ballPos.y - ballR <= 32 + paddleH / 2,
           ballPos.y + ballR >= 32 - paddleH / 2,
           abs(ballPos.x - aiX) < paddleW / 2 + ballR {
            ballVel.y = abs(ballVel.y)
            ballVel.x = ((ballPos.x - aiX) / (paddleW / 2)) * ballSpeed
        }

        // Scoring
        if ballPos.y > size.height + ballR {
            aiScore += 1
            Haptics.tap()
            resetBall(size: size)
        } else if ballPos.y < -ballR {
            playerScore += 1
            Haptics.success()
            resetBall(size: size)
        }
    }
}

#Preview {
    PongView()
}
