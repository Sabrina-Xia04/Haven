import SwiftUI

struct InsightsView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "1a2540"), Color(hex: "141c2e"), Color(hex: "0c1220")],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 600
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back to aquarium
                Button(action: { vm.navigateTo(.home) }) {
                    VStack(spacing: 2) {
                        Text("aquarium")
                            .font(.system(size: 10)).kerning(2).textCase(.uppercase)
                        Text("▴").font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.8))
                }
                .padding(.top, 56)

                Text("Haven Insights")
                    .font(.system(size: 12, weight: .semibold))
                    .kerning(4).textCase(.uppercase)
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.75))
                    .padding(.top, 22)

                ScrollView(showsIndicators: false) {
                    InsightCard(vm: vm)
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .onDisappear {
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                vm.backToAnswer()
            }
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    @ObservedObject var vm: HavenViewModel

    private var insight: InsightItem { vm.currentInsight }
    private var selectedAnswer: InsightAnswer? {
        guard case .pendingConfirm(let aid) = vm.insightState else { return nil }
        return insight.answers.first(where: { $0.id == aid })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch vm.insightState {
            case .unanswered:
                unansweredBody
            case .pendingConfirm:
                if let answer = selectedAnswer {
                    pendingBody(answer: answer)
                }
            case .confirmed:
                confirmedBody
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "c4e2f5").opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(hex: "cde8f6").opacity(0.18), lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.4), radius: 22, y: 9)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: vm.insightState)
    }

    // MARK: - Step 1: Question + Reason + Answers
    @ViewBuilder private var unansweredBody: some View {
        Text("I noticed something — I might be wrong.")
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "8cbdd4").opacity(0.7))
            .padding(.bottom, 10)

        Text(insight.question)
            .font(.custom("Georgia-Italic", size: 20))
            .foregroundColor(Color(hex: "cde8f6"))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)

        // Why this appeared
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(Color(hex: "8cbdd4").opacity(0.35))
                    .frame(width: 2, height: 12)
                Text("WHY THIS APPEARED")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.8)
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.6))
            }
            Text(insight.reason)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8cbdd4").opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 18)
        .padding(.bottom, 20)
        .padding(.leading, 4)

        Divider()
            .background(Color(hex: "cde8f6").opacity(0.12))
            .padding(.bottom, 16)

        Text("Does this feel familiar?")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "8cbdd4").opacity(0.85))
            .padding(.bottom, 14)

        VStack(spacing: 9) {
            ForEach(insight.answers) { answer in
                Button(action: { vm.selectAnswer(answer) }) {
                    Text(answer.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "e6f4fc"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(hex: "cde8f6").opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "cde8f6").opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Step 2: Reply + Haven Plan + Confirm / Back
    @ViewBuilder private func pendingBody(answer: InsightAnswer) -> some View {
        // Condensed question at top
        Text(insight.question)
            .font(.custom("Georgia-Italic", size: 16))
            .foregroundColor(Color(hex: "cde8f6").opacity(0.6))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 16)

        // Empathetic reply
        Text(answer.reply)
            .font(.custom("Georgia-Italic", size: 20))
            .foregroundColor(Color(hex: "e6f4fc"))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)

        // Haven's plan
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(Color(hex: "7ecdb8").opacity(0.5))
                    .frame(width: 2, height: 12)
                Text("HAVEN WILL")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.8)
                    .foregroundColor(Color(hex: "7ecdb8").opacity(0.75))
            }
            Text(answer.havenPlan)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8cbdd4"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 20)
        .padding(.bottom, 24)
        .padding(.leading, 4)

        Divider()
            .background(Color(hex: "cde8f6").opacity(0.12))
            .padding(.bottom, 16)

        HStack(spacing: 10) {
            Button(action: { vm.backToAnswer() }) {
                HStack(spacing: 5) {
                    Text("←")
                    Text("Change answer")
                }
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8cbdd4").opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "cde8f6").opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "cde8f6").opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: { vm.confirmInsight() }) {
                HStack(spacing: 5) {
                    Text("Sounds good")
                    Text("✓")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "e6f4fc"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "7ecdb8").opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "7ecdb8").opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Step 3: Confirmed
    @ViewBuilder private var confirmedBody: some View {
        VStack(spacing: 18) {
            Text("✦")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "7ecdb8"))

            Text("Noted.")
                .font(.custom("Georgia-Italic", size: 22))
                .foregroundColor(Color(hex: "e6f4fc"))

            Text("I'll hold onto this and act on it quietly.\nYou don't need to do anything.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8cbdd4").opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button(action: { vm.advanceInsight() }) {
                HStack(spacing: 6) {
                    Text("Next insight")
                    Text("→")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "e6f4fc"))
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(Color(hex: "cde8f6").opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "cde8f6").opacity(0.28), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

#Preview {
    InsightsView(vm: HavenViewModel())
}
