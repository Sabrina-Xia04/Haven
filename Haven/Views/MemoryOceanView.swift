import SwiftUI

struct MemoryOceanView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Deep ocean background
            LinearGradient(
                colors: [
                    Color(hex: "f7e0cd").opacity(0.5),
                    Color(hex: "6e8c8c").opacity(0.85),
                    Color(hex: "4a686c").opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle light rays
            OceanLightRays()
                .opacity(0.15)

            // Memory bubbles
            GeometryReader { geo in
                ForEach(vm.memoryItems) { item in
                    MemoryBubbleCard(item: item, appeared: appeared)
                        .position(
                            x: geo.size.width * item.xFraction,
                            y: geo.size.height * item.yFraction
                        )
                }
            }

            // Header
            VStack {
                // Back button
                HStack {
                    Button(action: { vm.navigateTo(.home) }) {
                        HStack(spacing: 6) {
                            Text("◂")
                            Text("aquarium")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.leading, 24)
                    .padding(.top, 68)

                    Spacer()
                }

                // Title
                VStack(spacing: 6) {
                    Text("Memory Ocean")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(4)
                        .textCase(.uppercase)
                        .foregroundColor(.white.opacity(0.8))

                    Text("things I remember about you")
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { appeared = true } }
        .onDisappear { appeared = false }
    }
}

// MARK: - Memory Bubble Card
struct MemoryBubbleCard: View {
    let item: MemoryItem
    let appeared: Bool
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.88), Color(hex: "bed4ea").opacity(0.55)],
                        center: UnitPoint(x: 0.35, y: 0.28),
                        startRadius: 0,
                        endRadius: item.size / 2
                    )
                )
                .frame(width: item.size, height: item.size)
                .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.18), radius: 16, y: 6)

            VStack(spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "43585a"))
                    .multilineTextAlignment(.center)

                Text(item.subtitle)
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundColor(Color(hex: "5c7274"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(16)
            .frame(width: item.size - 16)
        }
        .offset(y: floatOffset)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.4)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.72).delay(item.animDelay),
            value: appeared
        )
        .onAppear {
            let magnitude = CGFloat.random(in: 6...14)
            withAnimation(.easeInOut(duration: Double.random(in: 4.5...7.0)).repeatForever(autoreverses: true).delay(item.animDelay)) {
                floatOffset = magnitude
            }
        }
    }
}

// MARK: - Ocean Light Rays
struct OceanLightRays: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<5) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40 + CGFloat(i) * 8)
                    .rotationEffect(.degrees(Double(i - 2) * 8))
                    .offset(x: geo.size.width * CGFloat(i + 1) / 6 - 20)
                    .blur(radius: 18)
            }
        }
    }
}

#Preview {
    MemoryOceanView(vm: HavenViewModel())
}
