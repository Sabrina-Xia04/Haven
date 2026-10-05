import SwiftUI

// MARK: - Main overlay
struct VoiceConversationOverlay: View {
    @ObservedObject var manager: VoiceConversationManager
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "050e18").opacity(0.96).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                cloudSection
                    .padding(.top, 4)
                conversationArea   // history + current turn
                    .frame(maxHeight: .infinity)
                bottomSection
                Spacer(minLength: 40)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Text(phaseLabel)
                .font(.system(size: 11, weight: .semibold))
                .kerning(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: "8cbdd4").opacity(0.7))
            Spacer()
            Button(action: { manager.endConversation(); onDismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "cde8f6").opacity(0.10))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 64)
    }

    private var phaseLabel: String {
        switch manager.phase {
        case .idle:      return "Haven"
        case .listening: return "Listening…"
        case .thinking:  return "Thinking…"
        case .speaking:  return "Haven"
        }
    }

    // MARK: - Cloud
    private var cloudSection: some View {
        ZStack {
            WaveformRing(level: manager.audioLevel, isListening: manager.phase == .listening)
            Image("HavenMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .shadow(color: cloudGlow.opacity(cloudGlowOpacity), radius: cloudGlowRadius)
                .scaleEffect(manager.phase == .speaking ? 1.04 : 1.0)
                .animation(
                    manager.phase == .speaking
                        ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                        : .default,
                    value: manager.phase
                )
        }
        .frame(width: 160, height: 160)
    }

    private var cloudGlow: Color { Color(hex: "cde8f6") }
    private var cloudGlowOpacity: Double {
        switch manager.phase {
        case .idle: return 0.2; case .listening: return 0.45
        case .thinking: return 0.3; case .speaking: return 0.7
        }
    }
    private var cloudGlowRadius: CGFloat {
        switch manager.phase {
        case .idle: return 14; case .listening: return 24
        case .thinking: return 18; case .speaking: return 32
        }
    }

    // MARK: - Conversation area (history + live turn)
    private var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    // Past turns
                    ForEach(manager.turnHistory) { turn in
                        TurnView(turn: turn)
                            .id(turn.id)
                    }

                    // Current live turn
                    if manager.phase == .listening {
                        liveSpeechBubble
                            .id("live")
                    }
                    if manager.phase == .thinking || manager.phase == .speaking {
                        liveHavenBubble
                            .id("live")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .onChange(of: manager.transcript) { _, _ in
                withAnimation { proxy.scrollTo("live", anchor: .bottom) }
            }
            .onChange(of: manager.havenResponse) { _, _ in
                withAnimation { proxy.scrollTo("live", anchor: .bottom) }
            }
            .onChange(of: manager.turnHistory.count) { _, _ in
                withAnimation { proxy.scrollTo("live", anchor: .bottom) }
            }
        }
    }

    // User's live speech
    private var liveSpeechBubble: some View {
        HStack {
            Spacer()
            Group {
                if manager.transcript.isEmpty {
                    Text("say something…")
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundColor(Color(hex: "8cbdd4").opacity(0.4))
                } else {
                    Text(manager.transcript)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "e6f4fc"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "cde8f6").opacity(0.10))
            )
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // Haven's live streaming response
    private var liveHavenBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            Image("HavenMascot")
                .resizable()
                .frame(width: 24, height: 24)
                .clipShape(Circle())

            Group {
                if manager.phase == .thinking && manager.havenResponse.isEmpty {
                    ThinkingDots()
                        .padding(.vertical, 4)
                } else {
                    MarkdownText(manager.havenResponse)
                        .font(.custom("Georgia-Italic", size: 17))
                        .foregroundColor(Color(hex: "e6f4fc"))
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "1a3a52").opacity(0.6))
            )

            Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Bottom section
    private var bottomSection: some View {
        ZStack {
            if manager.phase == .listening {
                VStack(spacing: 10) {
                    MicPulse(level: manager.audioLevel)

                    Button(action: { manager.sendCurrentTranscript() }) {
                        ZStack {
                            Circle()
                                .fill(
                                    manager.transcript.isEmpty
                                        ? Color(hex: "cde8f6").opacity(0.12)
                                        : Color(hex: "7ecdb8").opacity(0.28)
                                )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle().stroke(
                                        manager.transcript.isEmpty
                                            ? Color(hex: "cde8f6").opacity(0.3)
                                            : Color(hex: "7ecdb8").opacity(0.7),
                                        lineWidth: 1.5
                                    )
                                )
                            Image(systemName: manager.transcript.isEmpty ? "stop.fill" : "arrow.up")
                                .font(.system(size: manager.transcript.isEmpty ? 16 : 20, weight: .semibold))
                                .foregroundColor(
                                    manager.transcript.isEmpty
                                        ? Color(hex: "8cbdd4").opacity(0.6)
                                        : Color(hex: "e6f4fc")
                                )
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: manager.transcript.isEmpty)

                    if let err = manager.errorMessage {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "e8a0a0").opacity(0.85))
                    } else {
                        Text(manager.transcript.isEmpty ? "listening…" : "tap ↑ to send")
                            .font(.system(size: 11))
                            .kerning(1.5)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: "8cbdd4").opacity(0.5))
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if manager.phase == .thinking || manager.phase == .speaking {
                HStack(spacing: 8) {
                    ForEach(manager.recentAgents, id: \.rawValue) { ag in
                        AgentChip(agent: ag)
                            .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                }
                .frame(height: 32)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: manager.recentAgents)
                .transition(.opacity)
            }

            if manager.phase == .idle {
                VStack(spacing: 14) {
                    if let err = manager.errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "e8a0a0"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else if !manager.debugStatus.isEmpty {
                        Text(manager.debugStatus)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8cbdd4").opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Tap to restart listening from idle
                    Button(action: { manager.startConversation() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "mic")
                                .font(.system(size: 14))
                            Text("tap to speak")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "cde8f6").opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(hex: "cde8f6").opacity(0.10))
                                .overlay(Capsule().stroke(Color(hex: "cde8f6").opacity(0.2), lineWidth: 1))
                        )
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(minHeight: 100)
        .animation(.easeInOut(duration: 0.25), value: manager.phase)
    }
}

// MARK: - Past turn view
struct TurnView: View {
    let turn: ConversationTurn

    var body: some View {
        VStack(spacing: 8) {
            // User bubble (right-aligned)
            HStack {
                Spacer()
                Text(turn.userText)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "cde8f6").opacity(0.75))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "cde8f6").opacity(0.08))
                    )
            }

            // Haven bubble (left-aligned)
            if !turn.havenText.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image("HavenMascot")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .clipShape(Circle())
                        .opacity(0.6)

                    MarkdownText(turn.havenText)
                        .font(.custom("Georgia-Italic", size: 15))
                        .foregroundColor(Color(hex: "e6f4fc").opacity(0.6))
                        .lineSpacing(3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "1a3a52").opacity(0.35))
                        )

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Markdown renderer
/// Renders markdown inline styles (bold, italic, code) using AttributedString.
struct MarkdownText: View {
    private let attributed: AttributedString
    private let fallback: String

    init(_ text: String) {
        self.fallback = text
        if let attr = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            self.attributed = attr
        } else {
            self.attributed = AttributedString(text)
        }
    }

    var body: some View {
        Text(attributed)
    }
}

// MARK: - Mic pulse
struct MicPulse: View {
    let level: Float
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<9, id: \.self) { i in
                let center = 4
                let dist = abs(i - center)
                let base: CGFloat = 4
                let liveH = base + CGFloat(level) * 18 * CGFloat.random(in: 0.6...1.4)
                              * max(0, 1 - CGFloat(dist) * 0.18)
                Capsule()
                    .fill(Color(hex: "7ecdb8").opacity(0.7))
                    .frame(width: 3, height: max(base, liveH))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
        .frame(height: 28)
    }
}

// MARK: - Waveform ring
struct WaveformRing: View {
    let level: Float
    let isListening: Bool
    private let barCount = 28
    @State private var idlePhase: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<barCount, id: \.self) { i in
                let angle = Double(i) / Double(barCount) * 2 * .pi
                let idleH = isListening ? 0.0 : abs(sin(idlePhase + Double(i) * 0.5)) * 6 + 2
                let liveH = isListening
                    ? CGFloat(level) * CGFloat.random(in: 14...26) + 4
                    : CGFloat(idleH)
                Capsule()
                    .fill(Color(hex: "cde8f6").opacity(isListening ? 0.55 : 0.22))
                    .frame(width: 3, height: liveH)
                    .offset(y: -68)
                    .rotationEffect(.degrees(angle * 180 / .pi))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                idlePhase = 2 * .pi
            }
        }
    }
}

// MARK: - Agent chip
struct AgentChip: View {
    let agent: AgentType
    var body: some View {
        HStack(spacing: 5) {
            Text(agent.emoji).font(.system(size: 11))
            Text(agent.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .kerning(0.5)
        }
        .foregroundColor(Color(hex: "e6f4fc"))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color(hex: agent.color).opacity(0.22))
                .overlay(Capsule().stroke(Color(hex: agent.color).opacity(0.4), lineWidth: 1))
        )
    }
}

// MARK: - Thinking dots
struct ThinkingDots: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.42, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color(hex: "8cbdd4").opacity(phase == i ? 0.9 : 0.25))
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.2 : 0.85)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}

extension Animation {
    func repeatWhileTrue(_ condition: Bool) -> Animation {
        condition ? self.repeatForever(autoreverses: true) : self
    }
}
