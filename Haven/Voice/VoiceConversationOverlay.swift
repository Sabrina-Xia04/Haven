import SwiftUI

// MARK: - Main overlay
struct VoiceConversationOverlay: View {
    @ObservedObject var manager: VoiceConversationManager
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Background — deep blur
            Color(hex: "050e18").opacity(0.94)
                .ignoresSafeArea()
                .onTapGesture { } // absorb taps

            VStack(spacing: 0) {
                // Top bar
                topBar

                Spacer()

                // Cloud + waveform
                cloudSection

                Spacer()

                // Text area
                textSection

                Spacer(minLength: 28)

                // Agent chips
                agentChips

                Spacer(minLength: 36)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            // Phase label
            Text(phaseLabel)
                .font(.system(size: 11, weight: .semibold))
                .kerning(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: "8cbdd4").opacity(0.7))

            Spacer()

            // Close
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

    // MARK: - Cloud + waveform
    private var cloudSection: some View {
        ZStack {
            // Waveform ring
            WaveformRing(level: manager.audioLevel,
                         isListening: manager.phase == .listening)

            // Cloud mascot — glow reacts to phase
            Image("HavenMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(color: cloudGlow.opacity(cloudGlowOpacity),
                        radius: cloudGlowRadius)
                .scaleEffect(manager.phase == .speaking ? 1.04 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatWhileTrue(
                    manager.phase == .speaking), value: manager.phase)
        }
        .frame(width: 200, height: 200)
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

    // MARK: - Text area
    private var textSection: some View {
        VStack(spacing: 16) {
            // User transcript
            if !manager.transcript.isEmpty {
                Text(manager.transcript)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
                    .transition(.opacity)
            }

            // Haven's response
            if !manager.havenResponse.isEmpty {
                Text(manager.havenResponse)
                    .font(.custom("Georgia-Italic", size: 18))
                    .foregroundColor(Color(hex: "e6f4fc"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 28)
                    .transition(.opacity)
            }

            // Thinking dots
            if manager.phase == .thinking && manager.havenResponse.isEmpty {
                ThinkingDots()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: manager.havenResponse)
        .animation(.easeInOut(duration: 0.25), value: manager.transcript)
    }

    // MARK: - Agent chips
    private var agentChips: some View {
        HStack(spacing: 8) {
            ForEach(manager.recentAgents, id: \.rawValue) { ag in
                AgentChip(agent: ag)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .frame(height: 32)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: manager.recentAgents)
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
