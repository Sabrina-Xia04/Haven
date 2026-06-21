import SwiftUI

struct SeedsView: View {
    @ObservedObject var vm: HavenViewModel
    @State private var appeared = false
    @State private var newSeedText = ""
    @State private var isAdding = false
    @State private var showingConnectors = false
    @FocusState private var addFieldFocused: Bool

    private var completedCount: Int { vm.seeds.filter(\.done).count }

    var body: some View {
        ZStack {

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
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if vm.seeds.isEmpty && !isAdding {
                            Text("No seeds yet.\nTap + to plant your first one.")
                                .font(.custom("Georgia-Italic", size: 15))
                                .foregroundColor(Color(hex: "7ecdb8").opacity(0.5))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 32)
                        }

                        ForEach(vm.seeds) { seed in
                            SeedCard(seed: seed, onTap: { vm.toggleSeed(seed) })
                                .contextMenu {
                                    Button(role: .destructive) {
                                        vm.deleteSeed(seed)
                                    } label: {
                                        Label("Delete seed", systemImage: "trash")
                                    }
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.75)
                                        .delay(Double(vm.seeds.firstIndex(where: { $0.id == seed.id }) ?? 0) * 0.06),
                                    value: appeared
                                )
                        }

                        // Inline add field
                        if isAdding {
                            HStack(spacing: 12) {
                                TextField("What do you want to plant?", text: $newSeedText)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "e6f4fc"))
                                    .focused($addFieldFocused)
                                    .submitLabel(.done)
                                    .onSubmit { commitNewSeed() }

                                Button(action: commitNewSeed) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color(hex: "7ecdb8"))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color(hex: "7ecdb8").opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .stroke(Color(hex: "7ecdb8").opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 22)
                    .padding(.bottom, 20)
                }

                Spacer()

                // Footer
                Text(footerText)
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)

                // Bottom bar: return hint + connect + add button
                HStack {
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

                    Spacer()

                    // Connect button
                    Button(action: { showingConnectors = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.horizontal")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Connect")
                                .font(.system(size: 12, weight: .semibold))
                                .kerning(0.5)
                        }
                        .foregroundColor(Color(hex: "7ecdb8"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(hex: "7ecdb8").opacity(0.12))
                                .overlay(Capsule().stroke(Color(hex: "7ecdb8").opacity(0.3), lineWidth: 1))
                        )
                    }
                    .opacity(isAdding ? 0 : 1)

                    Spacer().frame(width: 12)

                    // Add seed button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isAdding = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            addFieldFocused = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "7ecdb8").opacity(0.18))
                                .frame(width: 38, height: 38)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "7ecdb8"))
                        }
                    }
                    .opacity(isAdding ? 0 : 1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
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
                // dismiss add field when navigating away
                withAnimation { isAdding = false }
                newSeedText = ""
            }
        }
        .onTapGesture {
            if isAdding && newSeedText.isEmpty {
                withAnimation { isAdding = false }
                addFieldFocused = false
            }
        }
        .sheet(isPresented: $showingConnectors) {
            ConnectorsSheet()
        }
    }

    private func commitNewSeed() {
        let text = newSeedText.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty {
            vm.addSeed(label: text)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            newSeedText = ""
            isAdding = false
        }
        addFieldFocused = false
    }

    private var subtitleText: String {
        if completedCount == 0 { return "small things matter" }
        if completedCount == vm.seeds.count && !vm.seeds.isEmpty { return "you did enough today" }
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

// MARK: - Connectors Sheet
struct ConnectorsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let connectors: [ConnectorItem] = [
        ConnectorItem(icon: "calendar",       name: "Apple Calendar",   description: "Turn events and deadlines into seeds automatically.",   color: "e8a0a0", tag: "Calendar"),
        ConnectorItem(icon: "checklist",      name: "Reminders",        description: "Sync your Reminders list — check off in either place.", color: "a0c8e8", tag: "Tasks"),
        ConnectorItem(icon: "note.text",      name: "Notion",           description: "Pull tasks from a Notion database into your seeds.",    color: "c4b8e8", tag: "Docs"),
        ConnectorItem(icon: "triangle",       name: "Linear",           description: "Surface assigned issues as seeds each morning.",        color: "8cd4c4", tag: "Dev"),
        ConnectorItem(icon: "bubble.left",    name: "Slack",            description: "Seeds from messages you've starred or bookmarked.",    color: "e8c8a0", tag: "Comms"),
        ConnectorItem(icon: "chevron.left.forwardslash.chevron.right",
                                              name: "GitHub",           description: "Open PRs and assigned issues become seeds.",           color: "b8c8e8", tag: "Dev"),
        ConnectorItem(icon: "envelope",       name: "Gmail",            description: "Starred emails become seeds. Reply directly from Haven.", color: "e8b0a0", tag: "Comms"),
        ConnectorItem(icon: "chart.bar",      name: "Asana",            description: "Stay on top of assigned Asana tasks without switching apps.", color: "a0e8c0", tag: "Tasks"),
    ]

    var body: some View {
        ZStack {
            Color(hex: "050e18").ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color(hex: "cde8f6").opacity(0.2))
                    .frame(width: 38, height: 4)
                    .padding(.top, 14)

                // Header
                VStack(spacing: 6) {
                    Text("Connectors")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: "7ecdb8").opacity(0.85))

                    Text("bring your world into seeds")
                        .font(.custom("Georgia-Italic", size: 18))
                        .foregroundColor(Color(hex: "e6f4fc").opacity(0.85))
                }
                .padding(.top, 22)
                .padding(.bottom, 8)

                Text("Haven can read from your tools and plant seeds automatically.\nTap any connector to set it up.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8cbdd4").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                // Connector cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(connectors) { item in
                            ConnectorCard(item: item)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

struct ConnectorItem: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let description: String
    let color: String
    let tag: String
}

struct ConnectorCard: View {
    let item: ConnectorItem
    @State private var tapped = false

    var body: some View {
        Button(action: { tapped.toggle() }) {
            HStack(spacing: 16) {
                // Icon bubble
                ZStack {
                    Circle()
                        .fill(Color(hex: item.color).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: item.color))
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "e6f4fc"))

                        Text(item.tag)
                            .font(.system(size: 9, weight: .semibold))
                            .kerning(1)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: item.color).opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color(hex: item.color).opacity(0.15))
                            )
                    }

                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8cbdd4").opacity(0.75))
                        .lineSpacing(2)
                }

                Spacer()

                // Status indicator
                Image(systemName: tapped ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(
                        tapped ? Color(hex: "7ecdb8") : Color(hex: "cde8f6").opacity(0.3)
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tapped)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "cde8f6").opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                tapped
                                    ? Color(hex: "7ecdb8").opacity(0.4)
                                    : Color(hex: "cde8f6").opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SeedsView(vm: HavenViewModel())
}
