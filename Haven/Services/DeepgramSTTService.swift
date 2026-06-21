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
            .init(name: "endpointing",      value: "400"),   // 400 ms silence → final
            .init(name: "utterance_end_ms", value: "1000"),
            .init(name: "smart_format",     value: "true"),
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("Token \(HavenConfig.deepgramAPIKey)", forHTTPHeaderField: "Authorization")

        wsTask = urlSession.webSocketTask(with: req)
        wsTask?.resume()
        connected = true
        receive()
    }

    // MARK: - Send audio chunk
    func send(_ data: Data) {
        guard connected, let task = wsTask else { return }
        task.send(.data(data)) { _ in }
    }

    // MARK: - Disconnect
    func disconnect() {
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
                    if case .string(let json) = msg { self.parse(json) }
                    self.receive()
                case .failure:
                    self.connected = false
                }
            }
        }
    }

    // MARK: - Parse Deepgram response
    private func parse(_ json: String) {
        guard let data = json.data(using: .utf8),
              let obj  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chan  = obj["channel"] as? [String: Any],
              let alts  = chan["alternatives"] as? [[String: Any]],
              let text  = alts.first?["transcript"] as? String,
              !text.isEmpty
        else { return }

        let isFinal     = obj["is_final"]      as? Bool ?? false
        let speechFinal = obj["speech_final"]  as? Bool ?? false

        Task { @MainActor in
            self.interimTranscript = text
            if isFinal && speechFinal {
                self.finalTranscript = text
                self.interimTranscript = ""
            }
        }
    }
}
