import AVFoundation
import SwiftUI

/// Loops the shared bundled background music track while a game is active.
final class MusicPlayer: ObservableObject {
    static let shared = MusicPlayer()

    enum Tune {
        case snake, pong, breakout, whackAMole, memoryMatch, beeBop
    }

    @Published private(set) var isMuted = false

    private let volumeLevel: Float = 0.5
    private var duckingScale: Float = 1
    private var player: AVAudioPlayer?
    private var isActive = false

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        guard let url = Bundle.main.url(forResource: "GameplayMusic", withExtension: "m4a") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.volume = volumeLevel
        player?.prepareToPlay()
    }

    func play(_ tune: Tune) {
        guard !isActive else { return }
        isActive = true
        player?.currentTime = 0
        player?.play()
    }

    func stop() {
        isActive = false
        player?.stop()
    }

    func toggleMute() {
        isMuted.toggle()
        applyVolume()
    }

    /// Softens the music for Sleepy Mode's wind-down (1 = full volume, 0 = silent).
    func setDuckingScale(_ scale: Float) {
        duckingScale = max(0, min(1, scale))
        applyVolume()
    }

    private func applyVolume() {
        player?.volume = isMuted ? 0 : volumeLevel * duckingScale
    }
}

/// Small speaker button that toggles the shared game music on/off.
struct MusicMuteButton: View {
    @ObservedObject private var music = MusicPlayer.shared

    var body: some View {
        Button {
            music.toggleMute()
        } label: {
            Image(systemName: music.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(music.isMuted ? "Unmute music" : "Mute music")
    }
}
