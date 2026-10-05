import Combine
import Foundation
import SwiftUI

// MARK: - Demo script
struct DemoTurn {
    let userText: String?       // nil = Haven opens without user input
    let havenText: String
    let agentActivations: [AgentType]
    let actions: [DemoAction]
}
enum DemoAction {
    case addSeed(String)
    case storeMemory(String)
    case flagInsight(String)
}

private let demoScript: [DemoTurn] = [
    DemoTurn(
        userText: nil,
        havenText: "Hey. I'm here. What's on your mind?",
        agentActivations: [.companion],
        actions: []
    ),
    DemoTurn(
        userText: "I'm really stressed about my research proposal. I don't even know where to start.",
        havenText: "I heard you. That kind of overwhelm — where you can't even find the beginning — it's exhausting on its own. I've added the proposal to your Seeds so you don't have to hold it in your head anymore. What's the very first tiny thing that would make it feel less impossible?",
        agentActivations: [.seeds, .memory],
        actions: [.addSeed("Research Proposal"),
                  .storeMemory("User overwhelmed by research proposal")]
    ),
    DemoTurn(
        userText: "Maybe just outlining the intro section?",
        havenText: "Done. Outline the intro — just that, nothing else. That's a real seed now. Start there and stop there if you need to. That's enough.",
        agentActivations: [.seeds],
        actions: [.addSeed("Outline intro section")]
    ),
    DemoTurn(
        userText: "I've been avoiding this for days. It's kind of embarrassing.",
        havenText: "I noticed something just now — you've mentioned things other people will judge a few times. I'm not diagnosing anything. But I'm holding onto that pattern. It might become an insight worth looking at together.",
        agentActivations: [.insight],
        actions: [.flagInsight("Avoidance around high-judgment tasks")]
    ),
]

// MARK: - Conversation state
enum VoicePhase {
    case idle
    case listening
    case thinking
    case speaking
}

struct ConversationTurn: Identifiable {
    let id = UUID()
    let userText: String
    let havenText: String   // may contain markdown
}

// MARK: - Manager
@MainActor
class VoiceConversationManager: ObservableObject {

    // ── Published UI state ──────────────────────────────────────────────
    @Published var phase: VoicePhase = .idle
    @Published var transcript    = ""    // current user speech (interim)
    @Published var havenResponse = ""    // Haven's streamed reply (current turn)
    @Published var activeAgent: AgentType = .companion
    @Published var recentAgents: [AgentType] = []
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String? = nil
    @Published var debugStatus: String = ""
    @Published var turnHistory: [ConversationTurn] = []  // completed turns

    private func setStatus(_ msg: String) {
        print("ℹ️ [VCM] \(msg)")
        debugStatus = msg
    }

    // ── Services ────────────────────────────────────────────────────────
    private let capture  = AudioCaptureService()
    private let stt      = DeepgramSTTService()
    private let tts      = DeepgramTTSService()
    private let player   = AudioPlayerService()
    private let agent    = HavenAgentOrchestrator()

    // ── Weak ref to app VM for tool actions ────────────────────────────
    weak var vm: HavenViewModel?

    // ── Demo state ──────────────────────────────────────────────────────
    private var demoIndex = 0
    private var demoListening = false

    init() { wireUp() }

    // MARK: - Wire services together
    private var chunksReceived = 0
    private func wireUp() {
        // Audio level + forward chunks to STT
        capture.onChunk = { [weak self] data in
            guard let self else { return }
            self.chunksReceived += 1
            self.audioLevel = self.capture.level
            if self.chunksReceived == 1 || self.chunksReceived % 50 == 0 {
                print("🎵 [VCM] audio chunk #\(self.chunksReceived), \(data.count) bytes")
            }
            self.stt.send(data)
        }

        // TTS queue empty → resume listening for next turn
        player.onQueueEmpty = { [weak self] in
            guard let self, self.phase == .speaking else { return }
            print("🔊 [VCM] TTS queue empty — resuming listening")
            self.resumeListening()
        }

        // Interim STT → show transcript live
        stt.$interimTranscript
            .receive(on: RunLoop.main)
            .assign(to: &$transcript)

        // Final STT → call agent (only if still listening to prevent double-trigger)
        stt.$finalTranscript
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] text in
                guard let self, !text.isEmpty, self.phase == .listening else { return }
                print("📝 [VCM] finalTranscript fired: \"\(text)\"")
                Task { await self.runAgentTurn(userText: text) }
            }
            .store(in: &cancellables)

        // Agent text chunks → stream into havenResponse + TTS
        agent.onTextChunk = { [weak self] chunk in
            guard let self else { return }
            self.havenResponse += chunk
            Task {
                if let sentence = await self.tts.feed(chunk) {
                    await self.synthesizeAndPlay(sentence)
                }
            }
        }

        // Agent active agent → republish
        agent.$activeAgent
            .receive(on: RunLoop.main)
            .sink { [weak self] ag in
                guard let self else { return }
                self.activeAgent = ag
                if ag != .companion { self.flashAgent(ag) }
            }
            .store(in: &cancellables)

        // Agent actions → update HavenViewModel
        agent.onAction = { [weak self] action in
            self?.applyAction(action)
        }
    }
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Start / Stop conversation
    func startConversation() {
        guard phase == .idle else { return }
        havenResponse = ""
        transcript    = ""
        recentAgents  = []

        if HavenConfig.isDemoMode {
            startDemo()
        } else {
            startLive()
        }
    }

    func endConversation() {
        capture.stop()
        stt.disconnect()
        player.stop()
        phase = .idle
        demoListening = false
        audioLevel = 0
        turnHistory = []
        havenResponse = ""
        transcript = ""
    }

    /// User taps the send/stop button while listening.
    func sendCurrentTranscript() {
        print("🔴 [VCM] sendCurrentTranscript called, phase=\(phase), transcript=\"\(transcript)\"")
        guard phase == .listening else {
            print("⚠️ [VCM] sendCurrentTranscript: ignored — phase is \(phase), not .listening")
            return
        }
        let text = transcript.trimmingCharacters(in: .whitespaces)
        capture.stop()
        stt.disconnect()
        if text.isEmpty {
            // Nothing heard — show hint and restart listening after a moment
            errorMessage = "Didn't catch that — try again"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                self.errorMessage = nil
                self.resumeListening()
            }
        } else {
            Task { await runAgentTurn(userText: text) }
        }
    }

    // MARK: - Live mode
    private func startLive() {
        Task {
            setStatus("requesting mic permission…")
            let granted = await capture.requestPermission()
            setStatus("mic permission = \(granted)")
            guard granted else {
                errorMessage = "Microphone access denied — check Settings"
                phase = .idle
                return
            }
            setStatus("starting audio engine…")
            do {
                try capture.start()
                setStatus("audio engine running, connecting to Deepgram…")
            } catch {
                print("❌ [VCM] AudioCaptureService start error: \(error)")
                errorMessage = "Mic error: \(error.localizedDescription)"
                setStatus("ERROR: \(error.localizedDescription)")
                phase = .idle
                return
            }
            stt.connect()
            setStatus("Deepgram connected — listening")
            phase = .listening
        }
    }

    private func runAgentTurn(userText: String) async {
        capture.stop()
        stt.disconnect()
        phase = .thinking
        havenResponse = ""

        await agent.respond(to: userText)

        // Flush any remaining partial sentence to TTS
        if let last = await tts.flushRemaining() {
            await synthesizeAndPlay(last)
        }

        // Save completed turn to history
        let completedResponse = havenResponse
        if !userText.isEmpty || !completedResponse.isEmpty {
            turnHistory.append(ConversationTurn(userText: userText, havenText: completedResponse))
        }

        phase = .speaking

        // If TTS has nothing queued (e.g. TTS disabled / error), resume immediately
        if !player.isPlaying {
            print("🔊 [VCM] no TTS playing — resuming listening immediately")
            resumeListening()
        }
        // Otherwise onQueueEmpty callback handles resumeListening()
    }

    private func resumeListening() {
        havenResponse = ""
        transcript    = ""
        chunksReceived = 0
        print("🎙 [VCM] resumeListening — restarting capture + STT")
        do {
            try capture.start()
        } catch {
            print("❌ [VCM] resumeListening capture.start failed: \(error)")
            errorMessage = "Mic restart failed — tap to retry"
            phase = .idle
            return
        }
        stt.connect()
        phase = .listening
    }

    private func synthesizeAndPlay(_ text: String) async {
        guard let data = try? await tts.synthesize(text) else { return }
        await MainActor.run { player.enqueue(data) }
    }

    // MARK: - Demo mode
    private func startDemo() {
        demoIndex = 0
        phase = .listening
        playDemoTurn()
    }

    private func playDemoTurn() {
        guard demoIndex < demoScript.count else {
            phase = .idle
            return
        }
        let turn = demoScript[demoIndex]

        if let userText = turn.userText {
            // Simulate user speaking
            phase = .listening
            audioLevel = 0
            simulateListening(text: userText) { [weak self] in
                self?.runDemoResponse(turn)
            }
        } else {
            // Haven opens
            runDemoResponse(turn)
        }
    }

    private func simulateListening(text: String, completion: @escaping () -> Void) {
        let words = text.split(separator: " ")
        var built = ""
        for (i, word) in words.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
                built += (built.isEmpty ? "" : " ") + word
                self.transcript  = built
                self.audioLevel  = Float.random(in: 0.3...0.9)
            }
        }
        let duration = Double(words.count) * 0.12 + 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.audioLevel = 0
            completion()
        }
    }

    private func runDemoResponse(_ turn: DemoTurn) {
        phase = .thinking
        transcript = ""
        havenResponse = ""

        // Fire agent activations with staggered delay
        for (i, ag) in turn.agentActivations.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.7) {
                self.flashAgent(ag)
                // Apply actions for this agent
                let matchingActions = turn.actions.filter { action in
                    switch (ag, action) {
                    case (.seeds,   .addSeed):      return true
                    case (.memory,  .storeMemory):  return true
                    case (.insight, .flagInsight):  return true
                    default: return false
                    }
                }
                for action in matchingActions { self.applyDemoAction(action) }
            }
        }

        // Stream response text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.phase = .speaking
            self.streamText(turn.havenText) { [weak self] in
                self?.demoIndex += 1
                // Wait a beat then auto-advance to next turn (simulating user speaking)
                if self?.demoIndex ?? 0 < demoScript.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.playDemoTurn()
                    }
                } else {
                    self?.phase = .idle
                }
            }
        }
    }

    private func streamText(_ text: String, completion: @escaping () -> Void) {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        var built = ""
        for (i, word) in words.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.055) {
                built += (built.isEmpty ? "" : " ") + word
                self.havenResponse = built
            }
        }
        let dur = Double(words.count) * 0.055 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + dur) { completion() }
    }

    // MARK: - Agent chip flash
    private func flashAgent(_ ag: AgentType) {
        activeAgent = ag
        recentAgents.insert(ag, at: 0)
        if recentAgents.count > 3 { recentAgents.removeLast() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.activeAgent = .companion
        }
    }

    // MARK: - Apply tool actions to HavenViewModel
    private func applyAction(_ action: AgentAction) {
        switch action.kind {
        case .addSeed(let label):
            vm?.addSeed(label: label)
        case .completeSeed(let label):
            vm?.completeSeed(label: label)
        case .storeMemory(let text):
            vm?.addMemory(title: text, subtitle: "")
        case .flagInsight(let pattern, _):
            vm?.addMemory(title: "Pattern noticed", subtitle: pattern)
        case .navigate(let dest):
            switch dest {
            case "seeds":    vm?.navigateTo(.seeds)
            case "rhythm":   vm?.navigateTo(.rhythm)
            case "insights": vm?.navigateTo(.insights)
            case "memory":   vm?.navigateTo(.memory)
            default:         vm?.navigateTo(.home)
            }
        }
    }

    private func applyDemoAction(_ action: DemoAction) {
        switch action {
        case .addSeed(let label):         vm?.addSeed(label: label)
        case .storeMemory(let text):      vm?.addMemory(title: text, subtitle: "")
        case .flagInsight(let text):      vm?.addMemory(title: "Pattern noticed", subtitle: text)
        }
    }
}

// MARK: - HavenViewModel extensions for voice
extension HavenViewModel {
    func addSeed(label: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            seeds.append(Seed(label: label))
        }
    }
    func completeSeed(label: String) {
        if let idx = seeds.firstIndex(where: { $0.label.lowercased() == label.lowercased() }) {
            withAnimation { seeds[idx].done = true }
        }
    }
}
