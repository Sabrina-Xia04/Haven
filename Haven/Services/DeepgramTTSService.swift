import Foundation
import AVFoundation

/// Converts text to speech using Deepgram Aura-2 (REST).
/// Splits Claude's streaming output at sentence boundaries for low latency.
actor DeepgramTTSService {

    private var pendingSentence = ""

    // MARK: - Synthesise full text → audio data
    func synthesize(_ text: String) async throws -> Data {
        guard !HavenConfig.isDemoMode else { throw TTSError.demoMode }

        var comps = URLComponents(string: "https://api.deepgram.com/v1/speak")!
        comps.queryItems = [.init(name: "model", value: HavenConfig.ttsVoice)]

        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.setValue("Token \(HavenConfig.deepgramAPIKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["text": text])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw TTSError.httpError
        }
        return data
    }

    // MARK: - Sentence-streaming helper
    /// Feed Claude streaming chunks here. Returns a complete sentence when one finishes.
    func feed(_ chunk: String) -> String? {
        pendingSentence += chunk
        // Split at sentence boundary followed by space/newline or end-of-string
        let pattern = "([.!?][\\s\\n]|[.!?]$)"
        if let range = pendingSentence.range(of: pattern, options: .regularExpression) {
            let sentence = String(pendingSentence[pendingSentence.startIndex...range.upperBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            pendingSentence = String(pendingSentence[range.upperBound...])
            return sentence.isEmpty ? nil : sentence
        }
        return nil
    }

    func flushRemaining() -> String? {
        let s = pendingSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingSentence = ""
        return s.isEmpty ? nil : s
    }

    enum TTSError: Error { case demoMode, httpError }
}
