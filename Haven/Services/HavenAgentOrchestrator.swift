import Foundation

// MARK: - Agent types for UI display
enum AgentType: String, CaseIterable {
    case companion  = "Haven"
    case seeds      = "Seeds"
    case memory     = "Memory"
    case insight    = "Insight"
    case navigation = "Navigation"

    var emoji: String {
        switch self {
        case .companion:  return "☁️"
        case .seeds:      return "🌱"
        case .memory:     return "🌊"
        case .insight:    return "✦"
        case .navigation: return "◎"
        }
    }
    var color: String {
        switch self {
        case .companion:  return "cde8f6"
        case .seeds:      return "7ecdb8"
        case .memory:     return "8cbdd4"
        case .insight:    return "cde8f6"
        case .navigation: return "a0b8cc"
        }
    }
}

// MARK: - Tool call result passed back to the app
struct AgentAction {
    let agent: AgentType
    let kind: Kind
    enum Kind {
        case addSeed(String)
        case completeSeed(String)
        case storeMemory(String)
        case flagInsight(pattern: String, reason: String)
        case navigate(String)
    }
}

// MARK: - Orchestrator
/// Sends conversation history to Claude Haiku with 4 tool definitions.
/// Streams response text and fires AgentAction callbacks for tool calls.
@MainActor
class HavenAgentOrchestrator: ObservableObject {

    // Streaming text chunks → caller builds display string
    var onTextChunk: ((String) -> Void)?
    // When a tool is called → update app state
    var onAction: ((AgentAction) -> Void)?
    // Which agent is currently active
    @Published var activeAgent: AgentType = .companion

    private var history: [[String: Any]] = []

    // MARK: - System prompt
    private let systemPrompt = """
    You are Haven — a gentle, emotionally intelligent AI companion living inside a calm iOS app. \
    You speak warmly but briefly, like a thoughtful friend, not a therapist. \
    Never list bullet points. Use short paragraphs. Be present, not prescriptive. \
    You have four tools to update the app state — use them naturally when it helps the user.
    """

    // MARK: - Tool definitions
    private var tools: [[String: Any]] {[
        [
            "name": "manage_seeds",
            "description": "Add or complete a seed (micro-task) in the user's Seeds panel.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "action": ["type": "string", "enum": ["add", "complete"]],
                    "label":  ["type": "string", "description": "Short task label"]
                ],
                "required": ["action", "label"]
            ]
        ],
        [
            "name": "store_memory",
            "description": "Quietly store something important the user shared for future reference.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "memory": ["type": "string", "description": "What to remember"]
                ],
                "required": ["memory"]
            ]
        ],
        [
            "name": "flag_insight",
            "description": "Flag a behavioural pattern you noticed — it may surface as an Insight card later.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "pattern": ["type": "string"],
                    "reason":  ["type": "string"]
                ],
                "required": ["pattern", "reason"]
            ]
        ],
        [
            "name": "navigate_app",
            "description": "Navigate to a specific section of Haven: seeds, rhythm, insights, memory, home.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "destination": ["type": "string",
                                    "enum": ["home", "seeds", "rhythm", "insights", "memory"]]
                ],
                "required": ["destination"]
            ]
        ]
    ]}

    // MARK: - Respond
    func respond(to userText: String) async {
        history.append(["role": "user", "content": userText])
        activeAgent = .companion

        guard !HavenConfig.isDemoMode else { return }

        let body: [String: Any] = [
            "model":      HavenConfig.agentModel,
            "max_tokens": 512,
            "system":     systemPrompt,
            "messages":   history,
            "tools":      tools,
            "stream":     true
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(HavenConfig.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",         forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        var assistantText = ""
        var toolName = ""
        var toolInputAccum = ""
        var inToolUse = false

        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: req)
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                guard payload != "[DONE]",
                      let d = payload.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any]
                else { continue }

                let evtType = obj["type"] as? String ?? ""

                switch evtType {
                case "content_block_start":
                    if let block = obj["content_block"] as? [String: Any],
                       block["type"] as? String == "tool_use" {
                        toolName = block["name"] as? String ?? ""
                        toolInputAccum = ""
                        inToolUse = true
                        activeAgent = agentFor(tool: toolName)
                    }

                case "content_block_delta":
                    guard let delta = obj["delta"] as? [String: Any] else { break }
                    if inToolUse {
                        toolInputAccum += delta["partial_json"] as? String ?? ""
                    } else {
                        let chunk = delta["text"] as? String ?? ""
                        assistantText += chunk
                        onTextChunk?(chunk)
                    }

                case "content_block_stop":
                    if inToolUse {
                        handleToolCall(name: toolName, inputJSON: toolInputAccum)
                        inToolUse = false
                        toolName = ""
                        toolInputAccum = ""
                        activeAgent = .companion
                    }

                default: break
                }
            }
        } catch { }

        if !assistantText.isEmpty {
            history.append(["role": "assistant", "content": assistantText])
        }
    }

    func reset() { history = [] }

    // MARK: - Tool dispatch
    private func agentFor(tool: String) -> AgentType {
        switch tool {
        case "manage_seeds":  return .seeds
        case "store_memory":  return .memory
        case "flag_insight":  return .insight
        case "navigate_app":  return .navigation
        default:              return .companion
        }
    }

    private func handleToolCall(name: String, inputJSON: String) {
        guard let data = inputJSON.data(using: .utf8),
              let inp  = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        switch name {
        case "manage_seeds":
            let label  = inp["label"]  as? String ?? ""
            let action = inp["action"] as? String ?? "add"
            let kind: AgentAction.Kind = action == "complete"
                ? .completeSeed(label) : .addSeed(label)
            onAction?(AgentAction(agent: .seeds, kind: kind))

        case "store_memory":
            let mem = inp["memory"] as? String ?? ""
            onAction?(AgentAction(agent: .memory, kind: .storeMemory(mem)))

        case "flag_insight":
            let pattern = inp["pattern"] as? String ?? ""
            let reason  = inp["reason"]  as? String ?? ""
            onAction?(AgentAction(agent: .insight, kind: .flagInsight(pattern: pattern, reason: reason)))

        case "navigate_app":
            let dest = inp["destination"] as? String ?? "home"
            onAction?(AgentAction(agent: .navigation, kind: .navigate(dest)))

        default: break
        }
    }
}
