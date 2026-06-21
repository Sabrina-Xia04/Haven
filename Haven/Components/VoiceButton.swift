import SwiftUI

/// Small circular mic button that lives at the bottom of HomeView.
struct VoiceButton: View {
    let isActive: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulse ring (visible when active)
                Circle()
                    .stroke(Color(hex: "cde8f6").opacity(pulseOpacity), lineWidth: 1.5)
                    .frame(width: 58, height: 58)
                    .scaleEffect(pulseScale)

                // Button body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "1e4a62").opacity(0.95),
                                     Color(hex: "0e1e2c").opacity(0.98)],
                            center: .center, startRadius: 0, endRadius: 24
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(Color(hex: "cde8f6").opacity(isActive ? 0.6 : 0.28),
                                        lineWidth: 1.2)
                    )
                    .shadow(color: Color(hex: "cde8f6").opacity(isActive ? 0.35 : 0.12),
                            radius: isActive ? 12 : 6)

                // Mic icon
                Image(systemName: isActive ? "waveform" : "mic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "cde8f6").opacity(isActive ? 1.0 : 0.75))
                    .symbolEffect(.bounce, value: isActive)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: isActive) { active in
            if active { startPulse() } else { stopPulse() }
        }
    }

    private func startPulse() {
        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
            pulseScale   = 1.55
            pulseOpacity = 0.0
        }
        pulseOpacity = 0.55
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale   = 1.0
            pulseOpacity = 0.0
        }
    }
}
