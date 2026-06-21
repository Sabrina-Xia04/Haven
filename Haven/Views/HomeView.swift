import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: HavenViewModel
    @EnvironmentObject var notifManager: NotificationManager

    @State private var hintOpacity: Double = 0.28
    @State private var showingNotifSettings = false
    @State private var showingVoice = false

    @StateObject private var voiceManager = VoiceConversationManager()

    var body: some View {
        ZStack {

            VStack(spacing: 0) {
                // Title
                VStack(spacing: 6) {
                    Text("HAVEN")
                        .font(.system(size: 13, weight: .semibold))
                        .kerning(6)
                        .foregroundColor(Color(hex: "8cbdd4").opacity(0.72))

                    Text(greetingText)
                        .font(.custom("Georgia-Italic", size: 20))
                        .foregroundColor(Color(hex: "cde8f6").opacity(0.85))
                }
                .padding(.top, 70)

                // Aquarium globe
                AquariumView(vm: vm)
                    .padding(.top, 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.speechText)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.memoryText)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.isReturning)

                if vm.isReturning {
                    VStack(spacing: 12) {
                        Text("It's okay. I'm just happy you're here.")
                            .font(.custom("Georgia-Italic", size: 21))
                            .foregroundColor(Color(hex: "e6f4fc"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)

                        Button(action: { vm.toggleReturning() }) {
                            Text("stay a while")
                                .font(.system(size: 13))
                                .kerning(0.5)
                                .foregroundColor(Color(hex: "786c84").opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color(hex: "cde8f6").opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 26)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Spacer()

                    // Hint text + voice button stack
                    VStack(spacing: 16) {
                        Text("tap me · hold me · drift anywhere")
                            .font(.custom("Georgia-Italic", size: 13))
                            .foregroundColor(Color(hex: "786c84").opacity(0.62))

                        // ── Voice button ──────────────────────────────────
                        VoiceButton(isActive: showingVoice) {
                            showingVoice = true
                            voiceManager.vm = vm
                            voiceManager.startConversation()
                        }
                    }
                    .padding(.bottom, 52)
                }
            }

            // Direction hints — hide when returning message is visible
            if !vm.isReturning {
                HintLabels(opacity: hintOpacity)
                    .allowsHitTesting(false)
            }

            // Top buttons
            VStack {
                HStack {
                    Button(action: { vm.toggleReturning() }) {
                        Circle()
                            .fill(Color(hex: "cde8f6").opacity(0.18))
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

                    Button(action: { showingNotifSettings = true }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "cde8f6").opacity(0.18))
                                .frame(width: 30, height: 30)
                            Image(systemName: notifManager.permissionGranted ? "bell.fill" : "bell")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "60566c").opacity(0.7))
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

            // ── Voice conversation overlay ─────────────────────────────
            if showingVoice {
                VoiceConversationOverlay(manager: voiceManager) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showingVoice = false
                    }
                }
                .zIndex(10)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
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
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showingVoice)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "good morning"
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
                VStack(spacing: 2) {
                    Text("Seeds").font(.system(size: 10, weight: .semibold)).kerning(2.5).textCase(.uppercase)
                    Text("▾").font(.system(size: 12))
                }
                .foregroundColor(Color(hex: "786c84").opacity(opacity))
                .position(x: geo.size.width / 2, y: 60)

                VStack(spacing: 2) {
                    Text("▴").font(.system(size: 12))
                    Text("Insights").font(.system(size: 10, weight: .semibold)).kerning(2.5).textCase(.uppercase)
                }
                .foregroundColor(Color(hex: "786c84").opacity(opacity))
                .position(x: geo.size.width / 2, y: geo.size.height - 170)

                // Left: Rhythm — rotate entire label so it reads bottom-to-top
                VStack(spacing: 3) {
                    Text("▸").font(.system(size: 12))
                    Text("Rhythm")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(2)
                        .textCase(.uppercase)
                }
                .foregroundColor(Color(hex: "786c84").opacity(opacity))
                .fixedSize()
                .rotationEffect(.degrees(-90))
                .position(x: 16, y: geo.size.height / 2)

                // Right: Memory — rotate entire label so it reads top-to-bottom
                VStack(spacing: 3) {
                    Text("Memory")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(2)
                        .textCase(.uppercase)
                    Text("◂").font(.system(size: 12))
                }
                .foregroundColor(Color(hex: "786c84").opacity(opacity))
                .fixedSize()
                .rotationEffect(.degrees(90))
                .position(x: geo.size.width - 16, y: geo.size.height / 2)
            }
        }
    }
}

#Preview {
    HomeView(vm: HavenViewModel())
        .environmentObject(NotificationManager.shared)
}
