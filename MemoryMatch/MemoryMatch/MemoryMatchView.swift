import SwiftUI

private struct MemoryCard: Identifiable {
    let id: Int
    let emoji: String
    var isFlipped = false
    var isMatched = false
}

struct MemoryMatchView: View {
    private let emojis = ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    @ObservedObject private var center = GameCenter.shared
    @State private var showTutorial = !GameCenter.shared.hasSeenTutorial(for: .memoryMatch)
    @StateObject private var sleepySession = SleepySession()

    private var mismatchDelay: TimeInterval {
        switch center.difficultyLevel(for: .memoryMatch) {
        case .easy:   return 1.6
        case .medium: return 1.2
        case .hard:   return 0.8
        }
    }

    @State private var cards: [MemoryCard] = []
    @State private var firstIndex: Int? = nil
    @State private var secondIndex: Int? = nil
    @State private var score = 0
    @State private var moves = 0
    @State private var isChecking = false
    @State private var won = false
    @State private var backgroundVariant = SleepyBackgroundVariant.allCases.randomElement()!
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            switch backgroundVariant {
            case .normal: Color(red: 0.08, green: 0.0, blue: 0.18).ignoresSafeArea()
            case .alt: Color(red: 0.0, green: 0.08, blue: 0.18).ignoresSafeArea()
            case .photo: SleepyPhotoBackgroundView().ignoresSafeArea()
            }
            VStack(spacing: 16) {
                Text("🃏 Sleepy Memory Match")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)

                HStack {
                    Label("\(score)/8 pairs", systemImage: "star.fill")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .opacity(sleepySession.shouldHideScore ? 0 : 1)
                    Spacer()
                    Label("\(moves) moves", systemImage: "hand.tap")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .opacity(sleepySession.shouldHideScore ? 0 : 1)
                    MusicMuteButton()
                    SleepyModeButton()
                    ParentalSettingsButton()
                }
                .padding(.horizontal)

                HStack {
                    StarRatingView(stars: center.stars(for: .memoryMatch))
                    Spacer()
                    DifficultyPicker(game: .memoryMatch)
                }
                .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cards) { card in
                        CardTile(card: card)
                            .onTapGesture { flipCard(card) }
                    }
                }
                .padding(.horizontal)

                if won {
                    winBanner
                }
                Spacer()
            }
            .padding(.top)

            SleepyOverlay(progress: sleepySession.progress)
            if sleepySession.hasEnded {
                GoodnightCard {
                    sleepySession.reset()
                    setupGame()
                }
            }

            if showTutorial {
                TutorialOverlay(
                    emoji: "🃏", title: "Sleepy Memory Match",
                    instructions: "Flip two cards at a time.\nFind matching pairs.\nMatch all 8 to win!"
                ) {
                    showTutorial = false
                    GameCenter.shared.markTutorialSeen(for: .memoryMatch)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active { backgroundVariant = SleepyBackgroundVariant.allCases.randomElement()! }
        }
        .onAppear {
            backgroundVariant = SleepyBackgroundVariant.allCases.randomElement()!
            setupGame()
            sleepySession.start()
            MusicPlayer.shared.play(.memoryMatch)
        }
        .onDisappear {
            sleepySession.stop()
            MusicPlayer.shared.stop()
        }
    }

    // MARK: – Win banner

    private var winBanner: some View {
        VStack(spacing: 12) {
            Text("🎉 You Win!")
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Text("\(moves) moves")
                .font(.system(size: 18, design: .monospaced))
                .foregroundColor(.white)
            PrimaryGameButton(label: "Play Again 🔄", color: .yellow) { setupGame() }
        }
        .padding(.top, 8)
    }

    // MARK: – Game logic

    private func setupGame() {
        let shuffled = (emojis + emojis).shuffled()
        cards = shuffled.enumerated().map { MemoryCard(id: $0.offset, emoji: $0.element) }
        firstIndex = nil
        secondIndex = nil
        score = 0
        moves = 0
        won = false
    }

    private func flipCard(_ card: MemoryCard) {
        guard !sleepySession.hasEnded, !isChecking, !card.isFlipped, !card.isMatched else { return }
        cards[card.id].isFlipped = true
        Haptics.tap()

        if firstIndex == nil {
            firstIndex = card.id
        } else if secondIndex == nil {
            secondIndex = card.id
            moves += 1
            checkForMatch()
        }
    }

    private func checkForMatch() {
        guard let a = firstIndex, let b = secondIndex else { return }
        isChecking = true

        if cards[a].emoji == cards[b].emoji {
            cards[a].isMatched = true
            cards[b].isMatched = true
            score += 1
            firstIndex = nil
            secondIndex = nil
            isChecking = false
            Haptics.success()
            if score == emojis.count {
                won = true
                let earned = moves <= 12 ? 3 : moves <= 18 ? 2 : moves <= 26 ? 1 : 0
                center.recordStars(earned, for: .memoryMatch)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + mismatchDelay) {
                cards[a].isFlipped = false
                cards[b].isFlipped = false
                firstIndex = nil
                secondIndex = nil
                isChecking = false
            }
        }
    }
}

// MARK: – Card tile view

private struct CardTile: View {
    let card: MemoryCard

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(card.isMatched ? Color.green.opacity(0.55)
                      : card.isFlipped ? Color.white
                      : Color.purple)
                .frame(height: 76)

            if card.isFlipped || card.isMatched {
                Text(card.emoji)
                    .font(.system(size: 38))
            } else {
                Text("?")
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: card.isFlipped)
        .animation(.easeInOut(duration: 0.25), value: card.isMatched)
        .accessibilityLabel(card.isFlipped || card.isMatched ? "\(card.emoji) card" : "Hidden card")
    }
}

#Preview {
    MemoryMatchView()
}
