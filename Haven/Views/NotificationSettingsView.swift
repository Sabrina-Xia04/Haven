import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @ObservedObject var notifManager: NotificationManager
    @Environment(\.dismiss) private var dismiss

    // Toggle states
    @AppStorage("notif_checkin")    private var checkInOn:   Bool = false
    @AppStorage("notif_nudge")      private var nudgeOn:     Bool = false
    @AppStorage("notif_future")     private var futureOn:    Bool = false
    @AppStorage("notif_pattern")    private var patternOn:   Bool = false

    // Time pickers
    @AppStorage("notif_checkin_hour")   private var checkInHour:  Int = 9
    @AppStorage("notif_checkin_min")    private var checkInMin:   Int = 0
    @AppStorage("notif_nudge_hour")     private var nudgeHour:    Int = 10
    @AppStorage("notif_future_hour")    private var futureHour:   Int = 21

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background
            RadialGradient(
                colors: [Color(hex: "f7f0e6"), Color(hex: "efe6ec"), Color(hex: "e2ecec")],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "786c84"))
                                .padding(10)
                                .background(Color.white.opacity(0.55))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("GENTLE REMINDERS")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(3)
                            .foregroundColor(Color(hex: "786c84").opacity(0.65))

                        Text("Haven checks in,\nnever demands.")
                            .font(.custom("Georgia-Italic", size: 26))
                            .foregroundColor(Color(hex: "5f546c"))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                    // Permission banner
                    if !notifManager.permissionGranted {
                        PermissionBanner {
                            Task { await notifManager.requestPermission() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appeared)
                    }

                    // Cards
                    VStack(spacing: 14) {

                        NotifCard(
                            icon: "🌊",
                            title: "Daily check-in",
                            subtitle: "Haven asks how you're doing. You can reply right from the notification.",
                            isOn: $checkInOn,
                            isEnabled: notifManager.permissionGranted
                        ) {
                            HourPicker(label: "Time", hour: $checkInHour, minute: $checkInMin)
                        }
                        .onChange(of: checkInOn) { on in
                            if on { notifManager.scheduleDailyCheckIn(hour: checkInHour, minute: checkInMin) }
                            else  { notifManager.removeNotifications(withPrefix: "checkin") }
                        }
                        .onChange(of: checkInHour) { _ in
                            if checkInOn { notifManager.scheduleDailyCheckIn(hour: checkInHour, minute: checkInMin) }
                        }

                        NotifCard(
                            icon: "🌱",
                            title: "Seed nudge",
                            subtitle: "A gentle reminder that one small thing is always enough.",
                            isOn: $nudgeOn,
                            isEnabled: notifManager.permissionGranted
                        ) {
                            HourPicker(label: "Time", hour: $nudgeHour, minute: .constant(0))
                        }
                        .onChange(of: nudgeOn) { on in
                            if on { notifManager.scheduleNudge(hour: nudgeHour) }
                            else  { notifManager.removeNotifications(withPrefix: "nudge") }
                        }

                        NotifCard(
                            icon: "🌙",
                            title: "Future self",
                            subtitle: "An evening message from the version of you that got enough rest.",
                            isOn: $futureOn,
                            isEnabled: notifManager.permissionGranted
                        ) {
                            HourPicker(label: "Time", hour: $futureHour, minute: .constant(0))
                        }
                        .onChange(of: futureOn) { on in
                            if on { notifManager.scheduleFutureSelf(hour: futureHour) }
                            else  { notifManager.removeNotifications(withPrefix: "future") }
                        }

                        NotifCard(
                            icon: "✦",
                            title: "Pattern reminders",
                            subtitle: "Three messages a day timed to your natural energy windows: morning, afternoon, evening.",
                            isOn: $patternOn,
                            isEnabled: notifManager.permissionGranted,
                            footer: "9:00 AM · 2:00 PM · 8:30 PM"
                        )
                        .onChange(of: patternOn) { on in
                            if on { notifManager.schedulePatternReminders() }
                            else  { notifManager.removeNotifications(withPrefix: "pattern") }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Apple Watch note
                    WatchNote()
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.4).delay(0.3), value: appeared)

                    // Bottom comfort text
                    Text("You can turn these off at any time.\nHaven will never guilt you for silence.")
                        .font(.custom("Georgia-Italic", size: 14))
                        .foregroundColor(Color(hex: "786c84").opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 32)
                        .padding(.top, 28)
                        .padding(.bottom, 60)
                }
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .navigationBarHidden(true)
    }
}

// MARK: - Permission Banner
struct PermissionBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text("🔔")
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Allow notifications")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "5f546c"))
                    Text("So Haven can gently check in on you.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "786c84").opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "786c84").opacity(0.5))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "cebdec").opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "cebdec").opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Card
struct NotifCard<TimePicker: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let isEnabled: Bool
    var footer: String? = nil
    @ViewBuilder var timePicker: () -> TimePicker

    init(icon: String, title: String, subtitle: String,
         isOn: Binding<Bool>, isEnabled: Bool,
         footer: String? = nil,
         @ViewBuilder timePicker: @escaping () -> TimePicker = { EmptyView() }) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.isEnabled = isEnabled
        self.footer = footer
        self.timePicker = timePicker
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row
            HStack(alignment: .top, spacing: 14) {
                Text(icon)
                    .font(.system(size: 24))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "5f546c"))
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "786c84").opacity(0.8))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    if let footer {
                        Text(footer)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "a99ab8"))
                            .padding(.top, 2)
                    }
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(Color(hex: "bfe3d2"))
                    .disabled(!isEnabled)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, isOn ? 0 : 18)

            // Time picker (shown when on)
            if isOn && isEnabled {
                Divider()
                    .background(Color(hex: "cebdec").opacity(0.25))
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                timePicker()
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(isEnabled ? 0.65 : 0.35))
                .shadow(color: Color(hex: "8c78a0").opacity(0.25), radius: 12, y: 4)
        )
        .opacity(isEnabled ? 1 : 0.55)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isOn)
    }
}

// MARK: - Hour Picker
struct HourPicker: View {
    let label: String
    @Binding var hour: Int
    @Binding var minute: Int

    // Build a Date from hour+minute for the DatePicker
    private var pickerDate: Binding<Date> {
        Binding(
            get: {
                var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                c.hour   = hour
                c.minute = minute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { newDate in
                hour   = Calendar.current.component(.hour,   from: newDate)
                minute = Calendar.current.component(.minute, from: newDate)
            }
        )
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "786c84").opacity(0.8))
            Spacer()
            DatePicker("", selection: pickerDate, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorMultiply(Color(hex: "5f546c"))
        }
    }
}

// MARK: - Apple Watch Note
struct WatchNote: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "applewatch")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "786c84").opacity(0.7))

            VStack(alignment: .leading, spacing: 3) {
                Text("Apple Watch")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "5f546c"))
                Text("Notifications appear on your Watch automatically when your iPhone is nearby. You can reply with just a tap on your wrist.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "786c84").opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "786c84").opacity(0.15), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NotificationSettingsView(notifManager: NotificationManager.shared)
}
