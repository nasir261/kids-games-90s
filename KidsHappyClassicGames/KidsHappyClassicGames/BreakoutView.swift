import SwiftUI

private struct Brick: Identifiable {
    let id: Int
    var rect: CGRect
    let color: Color
    var alive = true
}

struct BreakoutView: View {
    private let paddleH: CGFloat = 14
    private let ballR: CGFloat = 8
    private let brickRows = 4
    private let brickCols = 7
    private let brickColors: [Color] = [
        .red, .orange,
        Color(red: 1.0, green: 0.92, blue: 0.1),  // brighter, less "gold/brown" looking yellow
        .green,
    ]

    @ObservedObject private var center = GameCenter.shared
    @State private var showTutorial = !GameCenter.shared.hasSeenTutorial(for: .breakout)
    @StateObject private var sleepySession = SleepySession()

    private var paddleW: CGFloat {
        switch center.difficultyLevel(for: .breakout) {
        case .easy:   return 140
        case .medium: return 100
        case .hard:   return 68
        }
    }
    private var initialBallVel: CGPoint {
        switch center.difficultyLevel(for: .breakout) {
        case .easy:   return CGPoint(x: 1.8, y: -3.0)
        case .medium: return CGPoint(x: 2.6, y: -4.4)
        case .hard:   return CGPoint(x: 3.6, y: -6.2)
        }
    }

    @State private var bricks: [Brick] = []
    @State private var ballPos = CGPoint.zero
    @State private var ballVel = CGPoint(x: 2.6, y: -4.4)
    @State private var paddleX: CGFloat = 0
    @State private var score = 0
    @State private var lives = 3
    @State private var isPlaying = false
    @State private var isPaused = false
    @State private var gameOver = false
    @State private var won = false
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
        .onAppear { MusicPlayer.shared.play(.breakout) }
        .onDisappear {
            gameTimer?.invalidate()
            sleepySession.stop()
            MusicPlayer.shared.stop()
        }
    }

    // MARK: – Header

    private var headerBar: some View {
        HStack {
            Text("🧱 Breakout")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Spacer()
            Text("Score: \(score)")
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .opacity(sleepySession.shouldHideScore ? 0 : 1)
            Text(String(repeating: "❤️", count: lives))
                .font(.system(size: 16))
            MusicMuteButton()
            SleepyModeButton()
            ParentalSettingsButton()
            if isPlaying && !gameOver && !won {
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

            // Bricks
            ForEach(bricks.filter { $0.alive }) { brick in
                RoundedRectangle(cornerRadius: 5)
                    .fill(brick.color)
                    .frame(width: brick.rect.width - 4, height: brick.rect.height - 4)
                    .position(x: brick.rect.midX, y: brick.rect.midY)
            }

            // Ball
            Circle()
                .fill(Color.white)
                .frame(width: ballR * 2, height: ballR * 2)
                .position(ballPos)

            // Paddle
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.cyan)
                .frame(width: paddleW, height: paddleH)
                .position(x: paddleX, y: size.height - 42)

            if !isPlaying && !gameOver && !won {
                VStack(spacing: 14) {
                    StarRatingView(stars: center.stars(for: .breakout))
                    DifficultyPicker(game: .breakout)
                    PrimaryGameButton(label: "Tap to Play! 🧱") {
                        setup(size: size)
                        startGame(size: size)
                    }
                }
            }
            if gameOver {
                GameResultCard(
                    title: "😵 Game Over!", titleColor: .red,
                    subtitle: "Score: \(score)",
                    buttonLabel: "Try Again 🔄"
                ) { setup(size: size); startGame(size: size) }
            }
            if won {
                GameResultCard(
                    title: "🎉 You Win!", titleColor: .yellow,
                    subtitle: "Score: \(score)",
                    buttonLabel: "Play Again 🔄"
                ) { setup(size: size); startGame(size: size) }
            }
            if isPaused && isPlaying && !gameOver && !won {
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
                    emoji: "🧱", title: "Sleepy Brick Blast",
                    instructions: "Drag your paddle to bounce the ball.\nBreak all the bricks.\nDon't miss or you'll lose a life!"
                ) {
                    showTutorial = false
                    GameCenter.shared.markTutorialSeen(for: .breakout)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { val in
                    guard isPlaying, !isPaused else { return }
                    paddleX = val.location.x.clamped(to: paddleW / 2 ... size.width - paddleW / 2)
                },
            including: isPlaying ? .all : .subviews
        )
        .onAppear { setup(size: size) }
        .onChange(of: size) { newSize in
            guard !isPlaying else { return }
            setup(size: newSize)
        }
    }

    // MARK: – Game logic

    private func setup(size: CGSize) {
        let bW = size.width / CGFloat(brickCols)
        let bH: CGFloat = 32
        let topPad: CGFloat = 56
        bricks = (0..<brickRows).flatMap { row in
            (0..<brickCols).map { col in
                Brick(
                    id: row * brickCols + col,
                    rect: CGRect(x: CGFloat(col) * bW, y: topPad + CGFloat(row) * bH, width: bW, height: bH),
                    color: brickColors[row % brickColors.count]
                )
            }
        }
        ballPos = CGPoint(x: size.width / 2, y: size.height / 2)
        ballVel = initialBallVel
        paddleX = size.width / 2
        score = 0
        lives = 3
        gameOver = false
        won = false
        isPaused = false
        isPlaying = false
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
        guard isPlaying, !isPaused else { return }
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
        // Top wall
        if ballPos.y <= ballR {
            ballVel.y = abs(ballVel.y)
        }

        // Paddle collision (ball moving down)
        let paddleY = size.height - 42
        if ballVel.y > 0,
           ballPos.y + ballR >= paddleY - paddleH / 2,
           ballPos.y - ballR <= paddleY + paddleH / 2,
           abs(ballPos.x - paddleX) < paddleW / 2 + ballR {
            ballVel.y = -abs(ballVel.y)
            let offset = (ballPos.x - paddleX) / (paddleW / 2)
            ballVel.x = offset * abs(initialBallVel.y)
            Haptics.impact()
        }

        // Brick collisions
        for i in bricks.indices where bricks[i].alive {
            let b = bricks[i].rect
            guard ballPos.x + ballR > b.minX,
                  ballPos.x - ballR < b.maxX,
                  ballPos.y + ballR > b.minY,
                  ballPos.y - ballR < b.maxY else { continue }

            bricks[i].alive = false
            score += 10
            Haptics.tap()

            // Determine axis of reflection
            let overlapX = min(ballPos.x + ballR - b.minX, b.maxX - (ballPos.x - ballR))
            let overlapY = min(ballPos.y + ballR - b.minY, b.maxY - (ballPos.y - ballR))
            if overlapY < overlapX { ballVel.y *= -1 } else { ballVel.x *= -1 }
            break
        }

        // Win check
        if bricks.allSatisfy({ !$0.alive }) {
            gameTimer?.invalidate()
            won = true
            isPlaying = false
            Haptics.success()
            center.recordScore(score, thresholds: (100, 200, 280), for: .breakout)
            return
        }

        // Ball falls off bottom
        if ballPos.y > size.height + ballR {
            lives -= 1
            Haptics.failure()
            if lives <= 0 {
                gameTimer?.invalidate()
                gameOver = true
                isPlaying = false
                center.recordScore(score, thresholds: (100, 200, 280), for: .breakout)
            } else {
                ballPos = CGPoint(x: size.width / 2, y: size.height / 2)
                ballVel = initialBallVel
            }
        }
    }
}

#Preview {
    BreakoutView()
}
