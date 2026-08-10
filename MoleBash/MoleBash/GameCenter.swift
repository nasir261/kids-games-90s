import SwiftUI

enum GameID: String, CaseIterable {
    case snake, pong, breakout, whackAMole, memoryMatch, beeBop
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }
}

/// Tracks per-game best star rating, chosen difficulty, and first-launch tutorial
/// state. Backed by UserDefaults so progress survives relaunches.
final class GameCenter: ObservableObject {
    static let shared = GameCenter()

    @Published private var bestStars: [GameID: Int] = [:]
    @Published private var difficultyByGame: [GameID: Difficulty] = [:]

    private let defaults = UserDefaults.standard

    private init() {
        for game in GameID.allCases {
            bestStars[game] = defaults.integer(forKey: "stars.\(game.rawValue)")
            if let raw = defaults.string(forKey: "difficulty.\(game.rawValue)"),
               let level = Difficulty(rawValue: raw) {
                difficultyByGame[game] = level
            } else {
                difficultyByGame[game] = .medium
            }
        }
    }

    func stars(for game: GameID) -> Int { bestStars[game] ?? 0 }

    func difficultyLevel(for game: GameID) -> Difficulty { difficultyByGame[game] ?? .medium }

    func setDifficulty(_ level: Difficulty, for game: GameID) {
        difficultyByGame[game] = level
        defaults.set(level.rawValue, forKey: "difficulty.\(game.rawValue)")
    }

    /// Rates a run against 1/2/3-star score thresholds and, if it beats the
    /// previous best, saves it. Returns the stars earned by this run.
    @discardableResult
    func recordScore(_ score: Int, thresholds: (Int, Int, Int), for game: GameID) -> Int {
        let earned: Int
        if score >= thresholds.2 { earned = 3 }
        else if score >= thresholds.1 { earned = 2 }
        else if score >= thresholds.0 { earned = 1 }
        else { earned = 0 }
        recordStars(earned, for: game)
        return earned
    }

    /// Saves a pre-computed star rating if it beats the previous best.
    func recordStars(_ earned: Int, for game: GameID) {
        guard earned > stars(for: game) else { return }
        bestStars[game] = earned
        defaults.set(earned, forKey: "stars.\(game.rawValue)")
    }

    func hasSeenTutorial(for game: GameID) -> Bool {
        defaults.bool(forKey: "tutorialSeen.\(game.rawValue)")
    }

    func markTutorialSeen(for game: GameID) {
        defaults.set(true, forKey: "tutorialSeen.\(game.rawValue)")
    }
}

/// Row of 3 stars reflecting a 0–3 rating.
struct StarRatingView: View {
    let stars: Int
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(.yellow)
            }
        }
    }
}

/// Segmented Easy/Medium/Hard picker shown on a game's pre-play screen.
struct DifficultyPicker: View {
    let game: GameID
    @ObservedObject private var center = GameCenter.shared

    var body: some View {
        Picker("Difficulty", selection: Binding(
            get: { center.difficultyLevel(for: game) },
            set: { center.setDifficulty($0, for: game) }
        )) {
            ForEach(Difficulty.allCases) { level in
                Text(level.rawValue).tag(level)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 260)
    }
}

/// One-time "how to play" card shown the first time a game is opened.
struct TutorialOverlay: View {
    let emoji: String
    let title: String
    let instructions: String
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("\(emoji) \(title)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Text(instructions)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            PrimaryGameButton(label: "Got it! 👍", color: .green, action: dismiss)
        }
        .padding(24)
        .background(Color.black.opacity(0.85))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}
