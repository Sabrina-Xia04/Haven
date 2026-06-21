import AVFoundation

/// Queues and plays MP3/PCM audio data sequentially.
/// Clears the queue immediately when interrupted.
@MainActor
class AudioPlayerService: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published var isPlaying = false

    private var queue: [Data] = []
    private var player: AVAudioPlayer?

    // MARK: - Enqueue audio data
    func enqueue(_ data: Data) {
        queue.append(data)
        if !isPlaying { playNext() }
    }

    // MARK: - Stop everything
    func stop() {
        player?.stop()
        player = nil
        queue.removeAll()
        isPlaying = false
    }

    // MARK: - Private
    private func playNext() {
        guard !queue.isEmpty else { isPlaying = false; return }
        let data = queue.removeFirst()
        do {
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            playNext()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        playNext()
    }
}
