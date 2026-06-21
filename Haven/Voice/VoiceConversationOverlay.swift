import SwiftUI

// MARK: - Main overlay
struct VoiceConversationOverlay: View {
    @ObservedObject var manager: VoiceConversationManager
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "050e18").opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                cloudSection
                Spacer(minLength: 0)
                transcriptSection
                Spacer(minLength: 0)
                bottomSection
                Spacer(minLength: 48)
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

            Button(action: {
                manager.endConversation()
                onDismiss()
            }) {
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
            WaveformRing(level: manager.audioLevel,
                         isListening: manager.phase == .listening)

            Image("HavenMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .shadow(color: cloudGlow.opacity(cloudGlowOpacity), radius: cloudGlowRadius)
                .scaleEffect(manager.phase == .speaking ? 1.04 : 1.0)
                .animation(
                    manager.phase == .speaking
                        ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                        : .default,
                    value: manager.phase
                )
        }
        .frame(width: 190, height: 190)
        .padding(.vertical, 8)
    }

    private var cloudGlow: Color { Color(hex: "cde8f6") }
    private var cloudGlowOpacity: Double {
        switch manager.phase {
        case .idle:      return 0.2
        case .listening: return 0.45
        case .thinking:  return 0.3
        case .speaking:  return 0.7
        }
    }
    private var cloudGlowRadius: CGFloat {
        switch manager.phase {
        case .idle: return 14; case .listening: return 24
        case .thinking: return 18; case .speaking: return 32
        }
    }

    // MARK: - Transcript / response text
    private var transcriptSection: some View {
        ZStack {
            // User's live transcript — large, prominent
            if manager.phase == .listening || manager.phase == .thinking {
                VStack(spacing: 10) {
                    if !manager.transcript.isEmpty {
                        Text(manager.transcript)
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 32)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else if manager.phase == .listening {
                        Text("say something…")
                            .font(.custom("Georgia-Italic", size: 18))
                            .foregroundColor(Color(hex: "8cbdd4").opacity(0.4))
                            .transition(.opacity)
                    }
                }
            }

            // Haven's streamed response
            if manager.phase == .speaking || manager.phase == .thinking {
                VStack(spacing: 14) {
                    if !manager.havenResponse.isEmpty {
                        Text(manager.havenResponse)
                            .font(.custom("Georgia-Italic", size: 20))
                            .foregroundColor(Color(hex: "e6f4fc"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 28)
                            .transition(.opacity)
                    } else if manager.phase == .thinking {
                        ThinkingDots()
                    }
                }
            }
        }
        .frame(minHeight: 120)
        .animation(.easeInOut(duration: 0.25), value: manager.transcript)
        .animation(.easeInOut(duration: 0.3),  value: manager.havenResponse)
        .animation(.easeInOut(duration: 0.2),  value: manager.phase)
    }

    // MARK: - Bottom: send button (listening) or agent chips (response)
    private var bottomSection: some View {
        ZStack {
            // Send / done button — always tappable while listening
            if manager.phase == .listening {
                VStack(spacing: 12) {
                    MicPulse(level: manager.audioLevel)

                    Button(action: { manager.sendCurrentTranscript() }) {
                        ZStack {
                            Circle()
                                .fill(
                                    manager.transcript.isEmpty
                                        ? Color(hex: "cde8f6").opacity(0.12)
                                        : Color(hex: "7ecdb8").opacity(0.28)
                                )
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Circle().stroke(
                                        manager.transcript.isEmpty
                                            ? Color(hex: "cde8f6").opacity(0.3)
                                            : Color(hex: "7ecdb8").opacity(0.7),
                                        lineWidth: 1.5
                                    )
                                )

                            Image(systemName: manager.transcript.isEmpty ? "stop.fill" : "arrow.up")
                                .font(.system(size: manager.transcript.isEmpty ? 18 : 22, weight: .semibold))
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
                            .transition(.opacity)
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

            // Agent chips — while thinking or speaking
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
        }
        .frame(minHeight: 110)
        .animation(.easeInOut(duration: 0.25), value: manager.phase)
    }
}

// MARK: - Mic pulse indicator
struct MicPulse: View {
    let level: Float

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<9, id: \.self) { i in
                let center = 4
                let distFromCenter = abs(i - center)
                let baseHeight: CGFloat = 4
                let maxExtra: CGFloat = 18
                let randomBoost = CGFloat.random(in: 0.6...1.4)
                let liveHeight = baseHeight + CGFloat(level) * maxExtra * randomBoost
                                    * max(0, 1 - CGFloat(distFromCenter) * 0.18)

                Capsule()
                    .fill(Color(hex: "7ecdb8").opacity(0.7))
                    .frame(width: 3, height: max(baseHeight, liveHeight))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
        .frame(height: 28)
    }
}

// MARK: - Waveform ring (unchanged)
struct WaveformRing: View {
    let level: Float
    let isListening: Bool

    private let barCount = 28
    @State private var idlePhase: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<barCount, id: \.self) { i in
                let angle = Double(i) / Double(barCount) * 2 * .pi
                let idleH = isListening
                    ? 0.0
                    : abs(sin(idlePhase + Double(i) * 0.5)) * 6 + 2
                let liveH = isListening
                    ? CGFloat(level) * CGFloat.random(in: 18...32) + 4
                    : CGFloat(idleH)

                Capsule()
                    .fill(Color(hex: "cde8f6").opacity(isListening ? 0.55 : 0.22))
                    .frame(width: 3, height: liveH)
                    .offset(y: -85)
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

// MARK: - Animation helper
extension Animation {
    func repeatWhileTrue(_ condition: Bool) -> Animation {
        condition ? self.repeatForever(autoreverses: true) : self
    }
}
