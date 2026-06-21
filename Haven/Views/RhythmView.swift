import SwiftUI

struct RhythmView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Warm background
            RadialGradient(
                colors: [Color(hex: "f8efe4"), Color(hex: "f1e3d6"), Color(hex: "ecdcce")],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Back button
                HStack {
                    Spacer()
                    Button(action: { vm.navigateTo(.home) }) {
                        HStack(spacing: 6) {
                            Text("aquarium")
                            Text("▸")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "7a6c84"))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 68)
                }

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Rhythm")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: "786c84").opacity(0.7))

                    Text("a gentle forecast")
                        .font(.custom("Georgia-Italic", size: 20))
                        .foregroundColor(Color(hex: "6a5d76"))
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)

                // Rhythm blocks
                VStack(spacing: 14) {
                    ForEach(Array(vm.rhythmBlocks.enumerated()), id: \.element.id) { i, block in
                        RhythmCard(block: block)
                            .opacity(appeared ? 1 : 0)
                            .offset(x: appeared ? 0 : -30)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.78).delay(Double(i) * 0.08),
                                value: appeared
                            )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)

                // Guardian note
                GuardianNote()
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.3), value: appeared)

                Spacer()
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .onDisappear { appeared = false }
    }
}

// MARK: - Rhythm Card
struct RhythmCard: View {
    let block: RhythmBlock

    var body: some View {
        HStack(spacing: 16) {
            // Color dot
            Circle()
                .fill(block.color)
                .frame(width: 36, height: 36)
                .shadow(color: block.color.opacity(0.5), radius: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(block.tag)
                    .font(.system(size: 11))
                    .kerning(1.5)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: "786c84").opacity(0.6))

                Text(block.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "5f546c"))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color(hex: "8c78a0").opacity(0.35), radius: 12, y: 5)
        )
    }
}

// MARK: - Guardian Note
struct GuardianNote: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Guardian note")
                .font(.system(size: 11))
                .kerning(1.5)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: "786c84").opacity(0.65))

            Text("Today looks a little heavier. Let's not rush.")
                .font(.custom("Georgia-Italic", size: 18))
                .foregroundColor(Color(hex: "5f546c"))
                .lineSpacing(4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "cebdec").opacity(0.5), Color(hex: "bfe3d2").opacity(0.45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
        )
    }
}

#Preview {
    RhythmView(vm: HavenViewModel())
}
