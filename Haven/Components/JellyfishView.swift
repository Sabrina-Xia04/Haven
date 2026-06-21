import SwiftUI

// MARK: - Animated Jellyfish
struct JellyfishView: View {
    var onTap: () -> Void
    var onLongPress: () -> Void

    @State private var floatOffset: CGFloat = 0
    @State private var swayAngle: Double = -7
    @State private var breathScale: CGFloat = 1.0

    private let tentacleOffsets: [(CGFloat, CGFloat, Double)] = [
        (-34, 84,  5.0),
        (-22, 106, 4.5),
        (-11, 122, 4.0),
        (  2, 126, 4.0),
        ( 14, 118, 4.5),
        ( 25, 102, 4.5),
        ( 35, 80,  5.0),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            // Tentacles
            ForEach(Array(tentacleOffsets.enumerated()), id: \.offset) { i, t in
                TentacleView(swayAngle: swayAngle, xOffset: t.0, height: t.1, delay: Double(i) * 0.28)
                    .offset(y: 68)
            }

            // Bell (dome)
            ZStack {
                // Main dome
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "eee5fa").opacity(0.96),
                                Color(hex: "cebdec").opacity(0.90),
                                Color(hex: "b8a2e0").opacity(0.78),
                            ],
                            center: UnitPoint(x: 0.5, y: 0.34),
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 118, height: 84)
                    .shadow(color: Color(hex: "c9b8e8").opacity(0.65), radius: 23)
                    .overlay(
                        // Highlight
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.85), Color.clear],
                                    center: UnitPoint(x: 0.4, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 28
                                )
                            )
                            .frame(width: 35, height: 22)
                            .offset(x: -14, y: -18)
                        , alignment: .center
                    )
                    .scaleEffect(breathScale)

                // Inner glow circles (frill texture)
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color(hex: "cebdec").opacity(0.18 - Double(i) * 0.05), lineWidth: 1)
                        .frame(width: CGFloat(60 + i * 18), height: CGFloat(48 + i * 14))
                        .offset(y: 10)
                }
            }
            .frame(width: 118, height: 84)

            // Sub-bell orbs
            HStack(spacing: 3) {
                Circle().fill(Color(hex: "cebdec").opacity(0.85)).frame(width: 14, height: 14)
                Circle().fill(Color(hex: "cebdec").opacity(0.85)).frame(width: 16, height: 16)
                Circle().fill(Color(hex: "cebdec").opacity(0.85)).frame(width: 16, height: 16)
                Circle().fill(Color(hex: "cebdec").opacity(0.85)).frame(width: 14, height: 14)
            }
            .offset(y: 74)
        }
        .frame(width: 118, height: 130)
        .offset(y: floatOffset)
        .onAppear { startAnimations() }
        .onTapGesture { onTap() }
        .onLongPressGesture(minimumDuration: 0.6) { onLongPress() }
    }

    private func startAnimations() {
        // Float up and down
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            floatOffset = 18
        }
        // Breathe
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathScale = 1.05
        }
        // Sway (tentacles)
        withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
            swayAngle = 7
        }
    }
}

// MARK: - Single Tentacle
struct TentacleView: View {
    var swayAngle: Double
    var xOffset: CGFloat
    var height: CGFloat
    var delay: Double

    @State private var localSway: Double = -7

    var body: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "cebdec").opacity(0.85), Color(hex: "cebdec").opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4.5, height: height)
            .rotationEffect(.degrees(localSway), anchor: .top)
            .offset(x: xOffset)
            .blur(radius: 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.6 + delay * 0.1).repeatForever(autoreverses: true).delay(delay)) {
                    localSway = 7
                }
            }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "efe6ec").ignoresSafeArea()
        JellyfishView(onTap: {}, onLongPress: {})
    }
}
