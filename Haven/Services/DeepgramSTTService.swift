import Foundation

/// Streams audio to Deepgram Nova-3 over WebSocket and publishes transcripts.
/// Publishes `interimTranscript` continuously; `finalTranscript` when speech ends.
@MainActor
class DeepgramSTTService: NSObject, ObservableObject {

    @Published var interimTranscript = ""
    @Published var finalTranscript: String? = nil

    private var wsTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var connected = false

    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
    }

    // MARK: - Connect
    func connect() {
        guard !HavenConfig.isDemoMode else { return }

        var comps = URLComponents(string: "wss://api.deepgram.com/v1/listen")!
        comps.queryItems = [
            .init(name: "model",            value: HavenConfig.sttModel),
            .init(name: "encoding",         value: "linear16"),
            .init(name: "sample_rate",      value: "16000"),
            .init(name: "channels",         value: "1"),
            .init(name: "interim_results",  value: "true"),
            .init(name: "endpointing",      value: "400"),
            .init(name: "utterance_end_ms", value: "1000"),
            .init(name: "smart_format",     value: "true"),
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("Token \(HavenConfig.deepgramAPIKey)", forHTTPHeaderField: "Authorization")

        print("🔌 [STT] connecting to \(comps.url!)")
        print("🔌 [STT] API key prefix = \(String(HavenConfig.deepgramAPIKey.prefix(8)))...")
        wsTask = urlSession.webSocketTask(with: req)
        wsTask?.resume()
        connected = true
        print("🔌 [STT] wsTask resumed, starting receive loop")
        receive()
    }

    // MARK: - Send audio chunk
    private var chunksSent = 0
    func send(_ data: Data) {
        guard connected, let task = wsTask else {
            if chunksSent == 0 { print("⚠️ [STT] send called but not connected or no task") }
            return
        }
        chunksSent += 1
        if chunksSent == 1 || chunksSent % 50 == 0 {
            print("📤 [STT] sent chunk #\(chunksSent), size=\(data.count) bytes")
        }
        task.send(.data(data)) { err in
            if let err { print("❌ [STT] send error: \(err)") }
        }
    }

    // MARK: - Disconnect
    func disconnect() {
        print("🔌 [STT] disconnect called (chunksSent=\(chunksSent))")
        chunksSent = 0
        wsTask?.cancel(with: .normalClosure, reason: nil)
        connected = false
        interimTranscript = ""
    }

    // MARK: - Receive loop
    private func receive() {
        wsTask?.receive { [weak self] result in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let msg):
                    switch msg {
                    case .string(let json):
                        print("📥 [STT] received text (\(json.count) chars): \(json.prefix(200))")
                        self.parse(json)
                    case .data(let d):
                        print("📥 [STT] received binary data: \(d.count) bytes")
                    @unknown default:
                        print("📥 [STT] received unknown message type")
                    }
                    self.receive()
                case .failure(let err):
                    print("❌ [STT] WebSocket error: \(err)")
                    self.connected = false
                }
            }
        }
    }

    // MARK: - Parse Deepgram response
    private func parse(_ json: String) {
        guard let data = json.data(using: .utf8),
              let obj  = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            print("⚠️ [STT] parse: invalid JSON")
            return
        }

        // Log non-results messages (metadata, errors, etc.)
        if let type_ = obj["type"] as? String, type_ != "Results" {
            print("ℹ️ [STT] Deepgram msg type=\(type_): \(json.prefix(300))")
            return
        }

        guard let chan  = obj["channel"] as? [String: Any],
              let alts  = chan["alternatives"] as? [[String: Any]],
              let text  = alts.first?["transcript"] as? String,
              !text.isEmpty
        else {
            // Empty result (silence) — normal, don't spam
            return
        }

        let isFinal     = obj["is_final"]      as? Bool ?? false
        let speechFinal = obj["speech_final"]  as? Bool ?? false
        print("📝 [STT] transcript: \"\(text)\" isFinal=\(isFinal) speechFinal=\(speechFinal)")

        interimTranscript = text
        if isFinal && speechFinal {
            finalTranscript = text
            interimTranscript = ""
        }
    }
}
