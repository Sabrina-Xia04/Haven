@preconcurrency import AVFoundation

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
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
            }
        }
    }

    // MARK: - Start
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        print("🎤 [Capture] AVAudioSession active. sampleRate=\(session.sampleRate) inputChannels=\(session.inputNumberOfChannels)")

        let input = engine.inputNode
        let inputFmt = input.outputFormat(forBus: 0)
        print("🎤 [Capture] inputNode format: \(inputFmt)")
        print("🎤 [Capture] targetFormat: \(targetFormat)")

        guard inputFmt.sampleRate > 0 else {
            print("❌ [Capture] inputNode returned zero sample rate — aborting")
            throw NSError(domain: "AudioCapture", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Input node has zero sample rate"])
        }

        // Capture targetFormat by value so the audio thread never touches @MainActor self
        let outFmt = targetFormat
        var tapCount = 0

        input.installTap(onBus: 0, bufferSize: 4096, format: inputFmt) { [weak self] buf, _ in
            // ── Audio thread ───────────────────────────────────────────────
            tapCount += 1
            if tapCount == 1 { print("🎤 [Capture] first tap fired! frameLength=\(buf.frameLength)") }

            // RMS level — copy frames out before touching anything actor-isolated
            var rms: Float = 0
            if let ch = buf.floatChannelData?[0] {
                let n = Int(buf.frameLength)
                var sum: Float = 0
                for i in 0..<n { sum += ch[i] * ch[i] }
                rms = sqrt(sum / Float(max(n, 1)))
            }

            // Resample to 16-kHz int16 — pure static, no actor isolation needed
            guard let pcm = AudioCaptureService.resample(buf, to: outFmt),
                  let ptr = pcm.int16ChannelData else {
                if tapCount <= 3 { print("⚠️ [Capture] resample returned nil on tap #\(tapCount)") }
                return
            }
            // Copy bytes off the audio buffer before dispatching to main actor
            let frameCount = Int(pcm.frameLength)
            let data = Data(bytes: ptr[0], count: frameCount * 2)
            guard !data.isEmpty else { return }

            Task { @MainActor in
                self?.level = min(rms * 25, 1.0)
                self?.onChunk?(data)
            }
        }

        try engine.start()
        print("🎤 [Capture] AVAudioEngine started")
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
