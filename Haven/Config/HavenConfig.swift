import Foundation

enum HavenConfig {
    // ── Fill in your API keys ──────────────────────────────────────────────
    static let deepgramAPIKey  = "YOUR_DEEPGRAM_API_KEY"
    static let anthropicAPIKey = "YOUR_ANTHROPIC_API_KEY"

    // ── Deepgram models ───────────────────────────────────────────────────
    static let sttModel  = "nova-3"          // lowest latency STT
    static let ttsVoice  = "aura-2-luna-en"  // warm, soft female voice

    // ── Claude model ──────────────────────────────────────────────────────
    static let agentModel = "claude-haiku-4-5-20251001"  // fastest Claude

    // ── Demo mode (auto-enabled when keys are placeholders) ───────────────
    static var isDemoMode: Bool {
        deepgramAPIKey.hasPrefix("YOUR_") || anthropicAPIKey.hasPrefix("YOUR_")
    }
}
