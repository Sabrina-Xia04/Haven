import SwiftUI

struct ContentView: View {
    @StateObject private var vm = HavenViewModel()
    @GestureState private var drag = CGSize.zero

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            ZStack {
                // ── Crossfading backgrounds (stay fixed, never slide) ────
                panelBackgrounds
                    .ignoresSafeArea()

                // ── Sliding panel content (transparent backgrounds) ──────
                ZStack {
                    makePanel(HomeView(vm: vm),        panelX: 0,  panelY: 0,  W: W, H: H)
                    makePanel(SeedsView(vm: vm),        panelX: 0,  panelY: -H, W: W, H: H)
                    makePanel(InsightsView(vm: vm),     panelX: 0,  panelY:  H, W: W, H: H)
                    makePanel(RhythmView(vm: vm),       panelX: -W, panelY: 0,  W: W, H: H)
                    makePanel(MemoryOceanView(vm: vm),  panelX:  W, panelY: 0,  W: W, H: H)
                }
                .clipped()
                .gesture(panGesture(W: W, H: H))
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Crossfading background layer
    @ViewBuilder
    private var panelBackgrounds: some View {
        ZStack {
            // Home — blue-teal
            RadialGradient(
                colors: [Color(hex: "1e3d52"), Color(hex: "152e3e"), Color(hex: "0e1e2c")],
                center: UnitPoint(x: 0.5, y: -0.08),
                startRadius: 0, endRadius: 600
            )
            .opacity(vm.currentPanel == .home ? 1 : 0)

            // Seeds — deep green
            RadialGradient(
                colors: [Color(hex: "163828"), Color(hex: "0f2a20"), Color(hex: "091a12")],
                center: UnitPoint(x: 0.5, y: 1.0),
                startRadius: 0, endRadius: 600
            )
            .opacity(vm.currentPanel == .seeds ? 1 : 0)

            // Insights — midnight blue
            RadialGradient(
                colors: [Color(hex: "1a2540"), Color(hex: "141c2e"), Color(hex: "0c1220")],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 600
            )
            .opacity(vm.currentPanel == .insights ? 1 : 0)

            // Rhythm — blue-purple
            RadialGradient(
                colors: [Color(hex: "1e3050"), Color(hex: "182438"), Color(hex: "0e1828")],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 600
            )
            .opacity(vm.currentPanel == .rhythm ? 1 : 0)

            // Memory — deep black-blue
            LinearGradient(
                colors: [Color(hex: "0e1e2c"), Color(hex: "091522"), Color(hex: "060f18")],
                startPoint: .top, endPoint: .bottom
            )
            .opacity(vm.currentPanel == .memory ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.4), value: vm.currentPanel)
    }

    // MARK: - Panel builder
    @ViewBuilder
    private func makePanel<V: View>(_ view: V, panelX: CGFloat, panelY: CGFloat,
                                    W: CGFloat, H: CGFloat) -> some View {
        view
            .frame(width: W, height: H)
            .offset(totalOffset(panelX: panelX, panelY: panelY, W: W, H: H))
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: vm.currentPanel)
    }

    // World shift to bring the active panel to (0,0), plus rubber-band drag
    private func totalOffset(panelX: CGFloat, panelY: CGFloat,
                              W: CGFloat, H: CGFloat) -> CGSize {
        let wx: CGFloat
        let wy: CGFloat
        switch vm.currentPanel {
        case .home:     wx =  0;  wy =  0
        case .seeds:    wx =  0;  wy =  H
        case .insights: wx =  0;  wy = -H
        case .rhythm:   wx =  W;  wy =  0
        case .memory:   wx = -W;  wy =  0
        }
        let resist: CGFloat = vm.currentPanel == .home ? 0.45 : 0.2
        return CGSize(width:  panelX + wx + drag.width  * resist,
                      height: panelY + wy + drag.height * resist)
    }

    // MARK: - Gesture
    private func panGesture(W: CGFloat, H: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($drag) { value, state, _ in
                let dx = abs(value.translation.width)
                let dy = abs(value.translation.height)
                state = dx > dy
                    ? CGSize(width: value.translation.width, height: 0)
                    : CGSize(width: 0, height: value.translation.height)
            }
            .onEnded { handleSwipe(value: $0) }
    }

    private func handleSwipe(value: DragGesture.Value) {
        let dx = value.translation.width
        let dy = value.translation.height
        let threshold: CGFloat = 55

        if vm.currentPanel == .home {
            if abs(dy) > abs(dx) {
                if dy >  threshold { vm.navigateTo(.seeds) }
                else if dy < -threshold { vm.navigateTo(.insights) }
            } else {
                if dx >  threshold { vm.navigateTo(.rhythm) }
                else if dx < -threshold { vm.navigateTo(.memory) }
            }
        } else {
            switch vm.currentPanel {
            case .seeds:    if dy < -threshold { vm.navigateTo(.home) }
            case .insights: if dy >  threshold { vm.navigateTo(.home) }
            case .rhythm:   if dx < -threshold { vm.navigateTo(.home) }
            case .memory:   if dx >  threshold { vm.navigateTo(.home) }
            default: break
            }
        }
    }
}

#Preview {
    ContentView()
}
