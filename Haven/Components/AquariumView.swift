import SwiftUI

// MARK: - Aquarium globe
struct AquariumView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var bubbles: [BubbleDef] = []
    @State private var particles: [ParticleDef] = []

    var body: some View {
        // Outer ZStack is NOT clipped — speech bubbles can exceed the circle
        ZStack {

            // ── Inner clipped globe ──────────────────────────────────────
            ZStack {
                // Globe background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "1e4a62").opacity(0.96),
                                Color(hex: "152e3e").opacity(0.92),
                                Color(hex: "0e1e2c").opacity(0.95),
                            ],
                            center: UnitPoint(x: 0.5, y: 0.16),
                            startRadius: 0,
                            endRadius: 170
                        )
                    )
                    .frame(width: 300, height: 300)
                    .shadow(color: Color(hex: "0a1a28").opacity(0.7), radius: 30, y: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "cde8f6").opacity(0.18), lineWidth: 1)
                    )
                    .overlay(
                        // Specular highlight
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.9), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 90, height: 55)
                            .offset(x: -42, y: -80)
                        , alignment: .center
                    )
                    .clipShape(Circle())

                // Ambient particles (sparkles)
                ForEach(particles) { p in
                    SparkleView(def: p)
                }

                // Rising bubbles
                ForEach(bubbles) { b in
                    RisingBubble(def: b)
                }

                // Cloud mascot — no color changes, only animation
                JellyfishView(
                    onTap: { vm.jellyfishTapped() },
                    onLongPress: { vm.jellyfishLongPressed() }
                )
                .offset(y: -10)

                // Returning hug glow (stays inside globe)
                if vm.isReturning {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "cde8f6").opacity(0.7), Color.clear],
                                center: UnitPoint(x: 0.35, y: 0.30),
                                startRadius: 0, endRadius: 23
                            )
                        )
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(Color(hex: "cde8f6").opacity(0.4), lineWidth: 1))
                        .shadow(color: Color(hex: "cde8f6").opacity(0.5), radius: 10)
                        .offset(x: 70, y: 30)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 300, height: 300)
            .clipShape(Circle())

            // ── Speech bubble — outside clip, floats above ─────────────
            if let speech = vm.speechText {
                SpeechBubble(text: speech)
                    .offset(y: -200)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .zIndex(10)
            }

            // ── Memory bubble — outside clip, floats above ─────────────
            if let mem = vm.memoryText {
                MemoryBubble(text: mem)
                    .offset(y: -210)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        // Tall enough frame so speech bubbles above the globe are fully visible
        .frame(width: 320, height: 440)
        .onAppear { generateAmbient() }
    }

    private func generateAmbient() {
        let tints: [Color] = [
            Color(hex: "cde8f6").opacity(0.95),
            Color(hex: "8cbdd4").opacity(0.90),
            Color(hex: "7ecdb8").opacity(0.90),
            Color(hex: "bed4ea").opacity(0.95),
        ]
        particles = (0..<16).map { i in
            ParticleDef(
                x: CGFloat.random(in: -100...100),
                y: CGFloat.random(in: -80...80),
                size: CGFloat.random(in: 2.5...5),
                color: tints[i % tints.count],
                duration: Double.random(in: 2.4...5.0),
                delay: Double.random(in: 0...4)
            )
        }
        bubbles = (0..<11).map { _ in
            BubbleDef(
                x: CGFloat.random(in: -100...100),
                size: CGFloat.random(in: 6...16),
                duration: Double.random(in: 7...13),
                delay: Double.random(in: 0...8)
            )
        }
    }
}

// MARK: - Particle definitions
struct ParticleDef: Identifiable {
    let id = UUID()
    let x, y, size: CGFloat
    let color: Color
    let duration, delay: Double
}

struct BubbleDef: Identifiable {
    let id = UUID()
    let x, size: CGFloat
    let duration, delay: Double
}

// MARK: - Sparkle
struct SparkleView: View {
    let def: ParticleDef
    @State private var opacity: Double = 0.15

    var body: some View {
        Circle()
            .fill(def.color)
            .shadow(color: def.color, radius: 3)
            .frame(width: def.size, height: def.size)
            .offset(x: def.x, y: def.y)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: def.duration).repeatForever(autoreverses: true).delay(def.delay)) {
                    opacity = 0.85
                }
            }
    }
}

// MARK: - Rising Bubble
struct RisingBubble: View {
    let def: BubbleDef
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.92), Color.white.opacity(0.12)],
                    center: UnitPoint(x: 0.35, y: 0.30),
                    startRadius: 0,
                    endRadius: def.size / 2
                )
            )
            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
            .frame(width: def.size, height: def.size)
            .offset(x: def.x, y: 100 + offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: def.duration).repeatForever(autoreverses: false).delay(def.delay)) {
                    offsetY = -340
                    opacity = 0
                }
                withAnimation(.linear(duration: 0.5).delay(def.delay + 0.5)) {
                    opacity = 0.75
                }
            }
    }
}

// MARK: - Speech Bubble
struct SpeechBubble: View {
    let text: String

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text(text)
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundColor(Color(hex: "e6f4fc"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Color(hex: "1a3a52").opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "cde8f6").opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 12, y: 4)

                // Tail
                Triangle()
                    .fill(Color(hex: "1a3a52").opacity(0.95))
                    .frame(width: 12, height: 8)
            }
        }
    }
}

// MARK: - Memory Bubble
struct MemoryBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Georgia-Italic", size: 16))
            .foregroundColor(Color(hex: "e6f4fc"))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(hex: "1a3a52").opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color(hex: "cde8f6").opacity(0.28), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.5), radius: 15, y: 6)
    }
}

// MARK: - Triangle shape for bubble tail
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
