import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: HavenViewModel
    @EnvironmentObject var notifManager: NotificationManager

    // Hint pulse animation
    @State private var hintOpacity: Double = 0.28
    @State private var showingNotifSettings = false

    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                colors: [Color(hex: "f7f0e6"), Color(hex: "efe6ec"), Color(hex: "e2ecec")],
                center: UnitPoint(x: 0.5, y: -0.08),
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                VStack(spacing: 6) {
                    Text("HAVEN")
                        .font(.system(size: 13, weight: .semibold))
                        .kerning(6)
                        .foregroundColor(Color(hex: "786c84").opacity(0.72))

                    Text(greetingText)
                        .font(.custom("Georgia-Italic", size: 20))
                        .foregroundColor(Color(hex: "60566c").opacity(0.85))
                }
                .padding(.top, 70)

                // Aquarium globe
                AquariumView(vm: vm)
                    .padding(.top, 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.speechText)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.memoryText)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.isReturning)

                // Returning message
                if vm.isReturning {
                    VStack(spacing: 12) {
                        Text("It's okay. I'm just happy you're here.")
                            .font(.custom("Georgia-Italic", size: 21))
                            .foregroundColor(Color(hex: "5f546c"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)

                        Button(action: { vm.toggleReturning() }) {
                            Text("stay a while")
                                .font(.system(size: 13))
                                .kerning(0.5)
                                .foregroundColor(Color(hex: "786c84").opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 26)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Spacer()
                    Text("tap me · hold me · drift anywhere")
                        .font(.custom("Georgia-Italic", size: 13))
                        .foregroundColor(Color(hex: "786c84").opacity(0.62))
                        .padding(.bottom, 56)
                }
            }

            // Direction hints (pulsing)
            HintLabels(opacity: hintOpacity)
                .allowsHitTesting(false)

            // Top buttons row
            VStack {
                HStack {
                    // Returning toggle (top-left)
                    Button(action: { vm.toggleReturning() }) {
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("◖")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "60566c").opacity(0.7))
                            )
                    }
                    .padding(.leading, 22)
                    .padding(.top, 52)

                    Spacer()

                    // Notification settings bell (top-right)
                    Button(action: { showingNotifSettings = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 30, height: 30)
                            Image(systemName: notifManager.permissionGranted
                                  ? "bell.fill" : "bell")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "60566c").opacity(0.7))
                            // Red dot if permission not yet granted
                            if !notifManager.permissionGranted {
                                Circle()
                                    .fill(Color(hex: "e8a0a0"))
                                    .frame(width: 7, height: 7)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.trailing, 22)
                    .padding(.top, 52)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showingNotifSettings) {
            NotificationSettingsView(notifManager: notifManager)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                hintOpacity = 0.62
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "good morning"
        case 12..<17: return "good afternoon"
        case 17..<21: return "good evening"
        default:      return "still here with you"
        }
    }
}

// MARK: - Direction Hints
struct HintLabels: View {
    let opacity: Double

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Seeds - top
                VStack(spacing: 2) {
                    Text("Seeds").font(.system(size: 10, weight: .semibold)).kerning(2.5).textCase(.uppercase)
                    Text("▾").font(.system(size: 12))
                }
                .foregroundColor(Color(hex: "786c84").opacity(opacity))
                .position(x: geo.size.width / 2, y: 128)

                // Insights - bottom
                VStack(spacing: 2) {
                    Text("▴").font(.system(size: 12))
                    Text("Insights").font(.system(size: 10, weight: .semibold)).kerning(2.5).textCase(.uppercase)
                }
                .foregroundColor(Color(hex: "786c84").opacity(opacity))
                .position(x: geo.size.width / 2, y: geo.size.height - 96)

                // Rhythm - left
                HStack(spacing: 5) {
                    Text("▸").font(.system(size: 12))
                    Text("Rhythm")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(2.5)
                        .textCase(.uppercase)
                        .rotationEffect(.degrees(90))
                        .frame(width: 14)
                }
                .foregroundColor(Color(hex: "786c84").opacity(opacity))
                .position(x: 22, y: geo.size.height / 2)

                // Memory - right
                HStack(spacing: 5) {
                    Text("Memory")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(2.5)
                        .textCase(.uppercase)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 14)
                    Text("◂").font(.system(size: 12))
                }
                .foregroundColor(Color(hex: "786c84").opacity(opacity))
                .position(x: geo.size.width - 22, y: geo.size.height / 2)
            }
        }
    }
}

#Preview {
    HomeView(vm: HavenViewModel())
}
