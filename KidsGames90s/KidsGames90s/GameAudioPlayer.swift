import AVFoundation

final class GameAudioPlayer {
    static let shared = GameAudioPlayer()

    private var player: AVAudioPlayer?
    private var currentTrack: String?

    private init() { }

    func play(track: String) {
        guard currentTrack != track || player?.isPlaying != true else { return }
        guard let url = Bundle.main.url(forResource: track, withExtension: nil) else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.35
            player?.prepareToPlay()
            player?.play()
            currentTrack = track
        } catch {
            player = nil
            currentTrack = nil
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentTrack = nil
    }
}
