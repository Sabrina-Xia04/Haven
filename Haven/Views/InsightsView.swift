import SwiftUI

struct InsightsView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Soft purple background
            RadialGradient(
                colors: [Color(hex: "efeaf3"), Color(hex: "e7e4f0"), Color(hex: "e0e6f0")],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                Button(action: { vm.navigateTo(.home) }) {
                    VStack(spacing: 2) {
                        Text("aquarium")
                            .font(.system(size: 10))
                            .kerning(2)
                            .textCase(.uppercase)
                        Text("▴").font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "786c84").opacity(0.7))
                }
                .padding(.top, 56)

                // Header
                Text("Haven Insights")
                    .font(.system(size: 12, weight: .semibold))
                    .kerning(4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: "786c84").opacity(0.7))
                    .padding(.top, 22)

                // Insight card
                InsightCard(vm: vm)
                    .padding(.horizontal, 28)
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)

                Spacer()
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .onDisappear {
            appeared = false
            // Reset insight so it can be answered fresh next time
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                vm.insightAnswered = false
                vm.insightReply = ""
            }
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    @ObservedObject var vm: HavenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Caveat
            Text("I noticed something — I might be wrong.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "786c84").opacity(0.7))
                .padding(.bottom, 10)

            // Main insight
            Text(vm.insightQuestion)
                .font(.custom("Georgia-Italic", size: 21))
                .foregroundColor(Color(hex: "5a4f68"))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            // Question
            Text("Does this feel familiar?")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "786c84").opacity(0.78))
                .padding(.top, 18)

            // Answer buttons / reply
            if vm.insightAnswered {
                Text(vm.insightReply)
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundColor(Color(hex: "6a5d76"))
                    .lineSpacing(4)
                    .padding(.top, 18)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                HStack(spacing: 10) {
                    ForEach(vm.insightAnswers) { answer in
                        Button(action: { vm.answerInsight(answer) }) {
                            Text(answer.label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "5f546c"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "cebdec").opacity(0.32))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 16)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.66))
                .shadow(color: Color(hex: "8c78aa").opacity(0.5), radius: 22, y: 9)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.insightAnswered)
    }
}

#Preview {
    InsightsView(vm: HavenViewModel())
}
