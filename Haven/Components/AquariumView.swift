import SwiftUI

// MARK: - Aquarium globe
struct AquariumView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var bubbles: [BubbleDef] = []
    @State private var particles: [ParticleDef] = []

    var body: some View {
        ZStack {
            // Globe background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "fff7ec").opacity(0.96),
                            Color(hex: "f4ceb0").opacity(0.32),
                            Color(hex: "cebdec").opacity(0.40),
                            Color(hex: "bed4ea").opacity(0.50),
                        ],
                        center: UnitPoint(x: 0.5, y: 0.16),
                        startRadius: 0,
                        endRadius: 170
                    )
                )
                .frame(width: 300, height: 300)
                .shadow(color: Color(hex: "9682aa").opacity(0.55), radius: 30, y: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
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

            // Seaweed growths
            ForEach(0..<5) { i in
                SeaweedView()
                    .offset(x: CGFloat(i) * 42 - 80, y: 110)
            }

            // Jellyfish
            JellyfishView(
                onTap: { vm.jellyfishTapped() },
                onLongPress: { vm.jellyfishLongPressed() }
            )
            .offset(y: -10)

            // Speech bubble
            if let speech = vm.speechText {
                SpeechBubble(text: speech)
                    .offset(y: -120)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }

            // Memory bubble (long-press)
            if let mem = vm.memoryText {
                MemoryBubble(text: mem)
                    .offset(y: -130)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }

            // Returning hug bubble
            if vm.isReturning {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.95), Color(hex: "f4ceb0").opacity(0.45)],
                            center: UnitPoint(x: 0.35, y: 0.30),
                            startRadius: 0, endRadius: 23
                        )
                    )
                    .frame(width: 46, height: 46)
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                    .shadow(color: Color(hex: "f4ceb0").opacity(0.6), radius: 10)
                    .offset(x: 70, y: 30)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 300, height: 300)
        .clipShape(Circle())
        .onAppear { generateAmbient() }
    }

    private func generateAmbient() {
        let tints: [Color] = [
            Color(hex: "ffecf2").opacity(0.95),
            Color(hex: "cebdec").opacity(0.95),
            Color(hex: "bfe3d2").opacity(0.95),
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

// MARK: - Seaweed
struct SeaweedView: View {
    @State private var sway: Double = -12

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color(hex: "bfe3d2"), Color(hex: "9fcdbb")], startPoint: .top, endPoint: .bottom))
                .frame(width: 6, height: 14)

            // Left leaf
            Ellipse()
                .fill(Color(hex: "bfe3d2"))
                .frame(width: 11, height: 8)
                .rotationEffect(.degrees(-20))
                .offset(x: -5, y: -9)

            // Right leaf
            Ellipse()
                .fill(Color(hex: "cdebdb"))
                .frame(width: 11, height: 8)
                .rotationEffect(.degrees(20))
                .offset(x: 1, y: -11)
        }
        .rotationEffect(.degrees(sway), anchor: .bottom)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
                sway = 12
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
                    .foregroundColor(Color(hex: "5f546c"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color(hex: "8c78a0").opacity(0.6), radius: 11, y: 4)

                // Tail
                Triangle()
                    .fill(Color.white.opacity(0.92))
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
            .foregroundColor(Color(hex: "5a4f68"))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.95), Color(hex: "cebdec").opacity(0.55)],
                            center: UnitPoint(x: 0.5, y: 0.2),
                            startRadius: 0, endRadius: 80
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "9678aa").opacity(0.6), radius: 15, y: 6)
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
