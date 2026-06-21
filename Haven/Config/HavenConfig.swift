import Foundation

enum HavenConfig {
    // Keys are loaded from Secrets.swift (gitignored — never committed)
    static let deepgramAPIKey  = Secrets.deepgramAPIKey
    static let anthropicAPIKey = Secrets.anthropicAPIKey

    // Deepgram models
    static let sttModel = "nova-3"          // lowest latency STT
    static let ttsVoice = "aura-2-luna-en"  // warm, soft female voice

    // Claude model
    static let agentModel = "claude-haiku-4-5-20251001"  // fastest Claude

    // Demo mode: auto-enabled when keys are still placeholders
    static var isDemoMode: Bool {
        deepgramAPIKey.hasPrefix("YOUR_") || anthropicAPIKey.hasPrefix("YOUR_")
    }
}
