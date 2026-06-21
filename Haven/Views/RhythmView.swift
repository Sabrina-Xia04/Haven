import SwiftUI

struct RhythmView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background — dark blue-purple matching cloud mascot theme
            RadialGradient(
                colors: [Color(hex: "1e3050"), Color(hex: "182438"), Color(hex: "0e1828")],
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
                        .foregroundColor(Color(hex: "8cbdd4"))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color(hex: "cde8f6").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "cde8f6").opacity(0.18), lineWidth: 1)
                        )
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
                        .foregroundColor(Color(hex: "8cbdd4").opacity(0.85))

                    Text("a gentle forecast")
                        .font(.custom("Georgia-Italic", size: 20))
                        .foregroundColor(Color(hex: "e6f4fc").opacity(0.9))
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
        .onChange(of: vm.currentPanel) { _, panel in
            if panel == .rhythm {
                appeared = false
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78).delay(0.05)) {
                    appeared = true
                }
            } else {
                appeared = false
            }
        }
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
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.75))

                Text(block.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "e6f4fc"))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(hex: "c4e2f5").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(hex: "cde8f6").opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 12, y: 5)
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
                .foregroundColor(Color(hex: "8cbdd4").opacity(0.75))

            Text("Today looks a little heavier. Let's not rush.")
                .font(.custom("Georgia-Italic", size: 18))
                .foregroundColor(Color(hex: "e6f4fc"))
                .lineSpacing(4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "cde8f6").opacity(0.12), Color(hex: "7ecdb8").opacity(0.10)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(hex: "cde8f6").opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    RhythmView(vm: HavenViewModel())
}
