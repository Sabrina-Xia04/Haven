import SwiftUI

struct SeedsView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var appeared = false

    private var completedCount: Int { vm.seeds.filter(\.done).count }

    var body: some View {
        ZStack {
            // Background — dark teal-green to contrast with light cloud mascot
            RadialGradient(
                colors: [Color(hex: "163828"), Color(hex: "0f2a20"), Color(hex: "091a12")],
                center: UnitPoint(x: 0.5, y: 1.0),
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Seeds")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: "7ecdb8").opacity(0.85))

                    Text(subtitleText)
                        .font(.custom("Georgia-Italic", size: 20))
                        .foregroundColor(Color(hex: "e6f4fc").opacity(0.9))
                }
                .padding(.top, 96)
                .padding(.horizontal, 28)

                // Seed cards
                VStack(spacing: 12) {
                    ForEach(vm.seeds) { seed in
                        SeedCard(seed: seed) { vm.toggleSeed(seed) }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.75)
                                    .delay(Double(vm.seeds.firstIndex(where: { $0.id == seed.id }) ?? 0) * 0.06),
                                value: appeared
                            )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)

                Spacer()

                // Footer
                Text(footerText)
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)

                // Return hint
                Button(action: { vm.navigateTo(.home) }) {
                    VStack(spacing: 2) {
                        Text("▾").font(.system(size: 12))
                        Text("aquarium")
                            .font(.system(size: 10))
                            .kerning(2)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 50)
            }
        }
        .onChange(of: vm.currentPanel) { _, panel in
            if panel == .seeds {
                appeared = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.05)) {
                    appeared = true
                }
            } else {
                appeared = false
            }
        }
    }

    private var subtitleText: String {
        if completedCount == 0 { return "small things matter" }
        if completedCount == vm.seeds.count { return "you did enough today" }
        return "\(completedCount) of \(vm.seeds.count) — that's something"
    }

    private var footerText: String {
        completedCount == 0
            ? "All successes are valid today."
            : "Future you is grateful."
    }
}

// MARK: - Seed Card
struct SeedCard: View {
    let seed: Seed
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Seaweed icon
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [Color(hex: "7ecdb8"), Color(hex: "5db8a0")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 5, height: 13)

                    Ellipse()
                        .fill(Color(hex: "7ecdb8"))
                        .frame(width: 10, height: 7)
                        .rotationEffect(.degrees(-22))
                        .offset(x: -4, y: -8)

                    Ellipse()
                        .fill(Color(hex: "a8e4d4"))
                        .frame(width: 10, height: 7)
                        .rotationEffect(.degrees(22))
                        .offset(x: 1, y: -10)
                }
                .frame(width: 20, height: 28)

                Text(seed.label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "e6f4fc"))

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .stroke(Color(hex: "7ecdb8").opacity(seed.done ? 0 : 0.6), lineWidth: 1.5)
                        .frame(width: 26, height: 26)

                    if seed.done {
                        Circle()
                            .fill(Color(hex: "7ecdb8").opacity(0.85))
                            .frame(width: 26, height: 26)
                        Text("✓")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "7ecdb8").opacity(seed.done ? 0.07 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color(hex: "7ecdb8").opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 12, y: 5)
            )
        }
        .buttonStyle(.plain)
        .opacity(seed.done ? 0.55 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: seed.done)
    }
}

#Preview {
    SeedsView(vm: HavenViewModel())
}
