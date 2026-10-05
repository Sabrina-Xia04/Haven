import SwiftUI

struct MemoryOceanView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var appeared = false
    @State private var deletingID: UUID? = nil   // bubble being confirmed for delete

    var body: some View {
        ZStack {
            OceanLightRays().opacity(0.08)

            GeometryReader { geo in
                // Reserve top 200 pt for header — shift yFraction into safe zone
                let safeTop: CGFloat    = 200
                let safeBottom: CGFloat = 40
                let safeHeight = geo.size.height - safeTop - safeBottom

                ForEach(vm.memoryItems) { item in
                    let x = geo.size.width  * item.xFraction
                    let y = safeTop + safeHeight * item.yFraction

                    MemoryBubbleCard(
                        item: item,
                        appeared: appeared,
                        isConfirmingDelete: deletingID == item.id,
                        onLongPress: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                deletingID = (deletingID == item.id) ? nil : item.id
                            }
                        },
                        onDelete: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                deletingID = nil
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                vm.deleteMemory(item)
                            }
                        }
                    )
                    .position(x: x, y: y)
                }
            }

            // Tap outside to cancel pending delete
            if deletingID != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation { deletingID = nil }
                    }
                    .ignoresSafeArea()
            }

            // Header (on top of bubbles)
            VStack {
                HStack {
                    Button(action: { vm.navigateTo(.home) }) {
                        HStack(spacing: 6) {
                            Text("◂")
                            Text("aquarium")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "cde8f6").opacity(0.9))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color(hex: "cde8f6").opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "cde8f6").opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.leading, 24)
                    .padding(.top, 68)
                    Spacer()
                }

                VStack(spacing: 6) {
                    Text("Memory Ocean")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: "8cbdd4").opacity(0.85))

                    Text("things I remember about you")
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundColor(Color(hex: "e6f4fc").opacity(0.85))
                }
                .padding(.top, 8)

                if deletingID != nil {
                    Text("tap the bubble again to delete, or tap elsewhere to cancel")
                        .font(.system(size: 11))
                        .kerning(0.5)
                        .foregroundColor(Color(hex: "e8a0a0").opacity(0.7))
                        .padding(.top, 6)
                        .transition(.opacity)
                }

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: deletingID)
        .onChange(of: vm.currentPanel) { _, panel in
            if panel == .memory {
                appeared = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05)) {
                    appeared = true
                }
            } else {
                appeared = false
                deletingID = nil
            }
        }
    }
}

// MARK: - Memory Bubble Card
struct MemoryBubbleCard: View {
    let item: MemoryItem
    let appeared: Bool
    let isConfirmingDelete: Bool
    let onLongPress: () -> Void
    let onDelete: () -> Void

    @State private var floatOffset: CGFloat = 0

    // Diameter sized to always fit two lines of text
    private var d: CGFloat { item.size }
    // Inner text width: chord at 70% of radius from centre
    private var textWidth: CGFloat { d * 0.68 }

    var body: some View {
        ZStack {
            // Bubble
            Circle()
                .fill(
                    RadialGradient(
                        colors: isConfirmingDelete
                            ? [Color(hex: "e8a0a0").opacity(0.25), Color(hex: "3a1010").opacity(0.80)]
                            : [Color(hex: "c4e2f5").opacity(0.18), Color(hex: "0e2a40").opacity(0.75)],
                        center: UnitPoint(x: 0.35, y: 0.28),
                        startRadius: 0,
                        endRadius: d / 2
                    )
                )
                .frame(width: d, height: d)
                .overlay(
                    Circle().stroke(
                        isConfirmingDelete
                            ? Color(hex: "e8a0a0").opacity(0.55)
                            : Color(hex: "cde8f6").opacity(0.28),
                        lineWidth: isConfirmingDelete ? 1.5 : 1
                    )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 16, y: 6)

            if isConfirmingDelete {
                // Delete confirmation UI
                VStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "e8a0a0"))
                    Text("hold to delete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "e8a0a0").opacity(0.85))
                }
            } else {
                // Normal content
                VStack(spacing: 5) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "e6f4fc"))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)

                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .font(.custom("Georgia-Italic", size: 12))
                            .foregroundColor(Color(hex: "8cbdd4"))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                            .lineLimit(3)
                            .lineSpacing(1)
                    }
                }
                .frame(width: textWidth)
            }
        }
        .frame(width: d, height: d)
        .offset(y: floatOffset)
        .scaleEffect(isConfirmingDelete ? 1.06 : (appeared ? 1 : 0.4))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(item.animDelay), value: appeared)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isConfirmingDelete)
        .onAppear {
            let mag = CGFloat.random(in: 6...14)
            withAnimation(
                .easeInOut(duration: Double.random(in: 4.5...7.0))
                .repeatForever(autoreverses: true)
                .delay(item.animDelay)
            ) { floatOffset = mag }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onLongPress()
        }
        .onTapGesture {
            if isConfirmingDelete { onDelete() }
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
                            colors: [Color(hex: "cde8f6").opacity(0.5), Color.clear],
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
