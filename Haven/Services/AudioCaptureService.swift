import AVFoundation
import Combine

/// Captures microphone audio and streams 16-kHz linear-16 PCM chunks.
/// Publishes an RMS level (0–1) for the waveform visualiser.
@MainActor
class AudioCaptureService: ObservableObject {

    @Published var level: Float = 0
    @Published var isCapturing = false

    /// Called on the main actor with each raw PCM chunk (linear16, 16 kHz, mono).
    var onChunk: ((Data) -> Void)?

    private let engine = AVAudioEngine()
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16_000, channels: 1, interleaved: true)!

    // MARK: - Permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission {
                cont.resume(returning: $0)
            }
        }
    }

    // MARK: - Start / Stop
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = engine.inputNode
        let inputFmt = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 4096, format: inputFmt) { [weak self] buf, _ in
            guard let self else { return }
            // RMS level for waveform
            if let ch = buf.floatChannelData?[0] {
                let n = Int(buf.frameLength)
                var sum: Float = 0
                for i in 0..<n { sum += ch[i] * ch[i] }
                let rms = sqrt(sum / Float(max(n, 1)))
                Task { @MainActor in self.level = min(rms * 25, 1.0) }
            }
            // Resample → 16 kHz int16 and forward
            if let pcm = self.resample(buf, to: self.targetFormat) {
                let data = pcm.int16ChannelData.map {
                    Data(bytes: $0, count: Int(pcm.frameLength) * 2)
                } ?? Data()
                if !data.isEmpty {
                    Task { @MainActor in self.onChunk?(data) }
                }
            }
        }

        try engine.start()
        isCapturing = true
    }

    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        isCapturing = false
        level = 0
    }

    // MARK: - Private
    private func resample(_ buf: AVAudioPCMBuffer, to fmt: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let conv = AVAudioConverter(from: buf.format, to: fmt) else { return nil }
        let ratio = fmt.sampleRate / buf.format.sampleRate
        let cap = AVAudioFrameCount(Double(buf.frameLength) * ratio + 1)
        guard let out = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: cap) else { return nil }
        var done = false
        let st = conv.convert(to: out, error: nil) { _, status in
            if done { status.pointee = .noDataNow; return nil }
            done = true; status.pointee = .haveData; return buf
        }
        return st == .error ? nil : out
    }
}
