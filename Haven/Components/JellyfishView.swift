import SwiftUI

// MARK: - Mascot View
struct JellyfishView: View {
    var onTap: () -> Void
    var onLongPress: () -> Void

    // Idle float — start at negative so animation is symmetric around 0
    @State private var floatOffset: CGFloat = -11
    @State private var swayOffset: CGFloat = -4
    @State private var breathScale: CGFloat = 1.0
    @State private var tiltAngle: Double = -2

    // Ambient glow — applied as .shadow, never touches image pixels
    @State private var glowOpacity: Double = 0.28
    @State private var glowRadius: CGFloat = 14

    // Tap feedback
    @State private var tapScale: CGFloat = 1.0
    @State private var tapGlowOpacity: Double = 0

    var body: some View {
        Image("HavenMascot")
            .resizable()
            .scaledToFit()
            .frame(width: 128, height: 128)
            .scaleEffect(breathScale * tapScale)
            .rotationEffect(.degrees(tiltAngle))
            // Shadow-based glow: renders only around the image outline,
            // never modifies the cloud's own pixel colours
            .shadow(color: Color(hex: "cde8f6").opacity(glowOpacity), radius: glowRadius, x: 0, y: 0)
            .shadow(color: Color(hex: "9fd8f0").opacity(tapGlowOpacity), radius: 38, x: 0, y: 0)
            .offset(x: swayOffset, y: floatOffset)
            .frame(width: 150, height: 150)
            .onAppear { startIdleAnimations() }
            .onTapGesture {
                triggerTapFeedback()
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.6) { onLongPress() }
    }

    // MARK: - Idle
    private func startIdleAnimations() {
        withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
            floatOffset = 11   // -11 → 11, centered at 0
        }
        withAnimation(.easeInOut(duration: 6.8).repeatForever(autoreverses: true)) {
            swayOffset = 4     // -4 → 4, centered at 0
        }
        withAnimation(.easeInOut(duration: 6.8).repeatForever(autoreverses: true)) {
            tiltAngle = 2      // -2 → 2, centered at 0
        }
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            breathScale = 1.05
        }
        // Glow pulses between dim and brighter — only affects the halo, not cloud colour
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.55
            glowRadius = 22
        }
    }

    // MARK: - Tap feedback
    private func triggerTapFeedback() {
        // Gentle bounce: slightly bigger, then spring back
        withAnimation(.spring(response: 0.18, dampingFraction: 0.38)) {
            tapScale = 1.11
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                tapScale = 1.0
            }
        }
        // Glow burst around the halo
        withAnimation(.easeOut(duration: 0.12)) {
            tapGlowOpacity = 0.65
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.65)) {
                tapGlowOpacity = 0
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "162e3e").ignoresSafeArea()
        JellyfishView(onTap: {}, onLongPress: {})
    }
}
