import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        Text("🎮 Cozy Sleep Time Games")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                            .padding(.top, 14)

                        GameMenuButton(game: .breakout, title: "🧱  Sleepy Brick Blast",     color: .red,    destination: AnyView(BreakoutView()))
                        GameMenuButton(game: .snake, title: "🐍  Sleepy Apple Muncher", color: .green,  destination: AnyView(SnakeGameView()))
                        GameMenuButton(game: .pong, title: "🏓  Sleepy Paddle Bounce", color: .purple, destination: AnyView(PongView()))
                        GameMenuButton(game: .whackAMole, title: "🔨  Sleepy Mole Bash", color: .orange, destination: AnyView(WhackAMoleView()))
                        GameMenuButton(game: .memoryMatch, title: "🃏  Sleepy Memory Match", color: .blue,   destination: AnyView(MemoryMatchView()))
                        GameMenuButton(game: .beeBop, title: "🐝  Sleepy Bee Bop", color: .indigo, destination: AnyView(BeeBopView()))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct GameMenuButton: View {
    let game: GameID
    let title: String
    let color: Color
    let destination: AnyView
    @ObservedObject private var center = GameCenter.shared

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                StarRatingView(stars: center.stars(for: game), size: 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(color)
            .cornerRadius(22)
            .shadow(color: color.opacity(0.6), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
