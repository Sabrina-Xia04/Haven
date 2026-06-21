import AVFoundation

/// Captures microphone audio and streams 16-kHz linear-16 PCM chunks.
@MainActor
class AudioCaptureService: ObservableObject {

    @Published var level: Float = 0
    @Published var isCapturing = false

    var onChunk: ((Data) -> Void)?

    private let engine = AVAudioEngine()

    // Immutable — safe to capture into audio-thread closure
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

    // MARK: - Start
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = engine.inputNode
        let inputFmt = input.outputFormat(forBus: 0)

        // Capture targetFormat by value so the audio thread never touches @MainActor self
        let outFmt = targetFormat

        input.installTap(onBus: 0, bufferSize: 4096, format: inputFmt) { [weak self] buf, _ in
            // ── Audio thread ───────────────────────────────────────────────

            // RMS level — post to main actor
            if let ch = buf.floatChannelData?[0] {
                let n = Int(buf.frameLength)
                var sum: Float = 0
                for i in 0..<n { sum += ch[i] * ch[i] }
                let rms = sqrt(sum / Float(max(n, 1)))
                Task { @MainActor in self?.level = min(rms * 25, 1.0) }
            }

            // Resample — pure static, no actor isolation needed
            guard let pcm = AudioCaptureService.resample(buf, to: outFmt),
                  let ptr = pcm.int16ChannelData else { return }
            let data = Data(bytes: ptr[0], count: Int(pcm.frameLength) * 2)
            guard !data.isEmpty else { return }

            Task { @MainActor in self?.onChunk?(data) }
        }

        try engine.start()
        isCapturing = true
    }

    // MARK: - Stop
    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
        level = 0
    }

    // MARK: - Resample (nonisolated static — safe on any thread)
    private nonisolated static func resample(
        _ buf: AVAudioPCMBuffer,
        to fmt: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        guard let conv = AVAudioConverter(from: buf.format, to: fmt) else { return nil }
        let ratio = fmt.sampleRate / buf.format.sampleRate
        let cap = AVAudioFrameCount(Double(buf.frameLength) * ratio + 1)
        guard let out = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: cap) else { return nil }
        var done = false
        let status = conv.convert(to: out, error: nil) { _, outStatus in
            if done { outStatus.pointee = .noDataNow; return nil }
            done = true; outStatus.pointee = .haveData; return buf
        }
        return status == .error ? nil : out
    }
}
