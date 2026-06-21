import SwiftUI

struct ContentView: View {
    @StateObject private var vm = HavenViewModel()
    @GestureState private var drag = CGSize.zero

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            // Each panel sits at its "world" position via .offset().
            // offset() moves visuals without affecting layout, so all panels
            // keep their W×H layout footprint — ZStack stays W×H — and
            // .clipped() on the GeometryReader hides anything outside.
            ZStack {
                makePanel(HomeView(vm: vm),         panelX: 0,  panelY: 0,  W: W, H: H)
                makePanel(SeedsView(vm: vm),         panelX: 0,  panelY: -H, W: W, H: H)
                makePanel(InsightsView(vm: vm),      panelX: 0,  panelY:  H, W: W, H: H)
                makePanel(RhythmView(vm: vm),        panelX: -W, panelY: 0,  W: W, H: H)
                makePanel(MemoryOceanView(vm: vm),   panelX:  W, panelY: 0,  W: W, H: H)
            }
            .clipped()
            .gesture(panGesture(W: W, H: H))
        }
        .ignoresSafeArea()
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
        // world origin: the negative of the active panel's position
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
        // Positive drag: panels follow finger direction.
        // Drag DOWN → Seeds (above, panelY = -H) slides down into view.
        // Drag RIGHT → Rhythm (left, panelX = -W) slides right into view.
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
                if dy >  threshold { vm.navigateTo(.seeds) }    // drag down → Seeds (above)
                else if dy < -threshold { vm.navigateTo(.insights) } // drag up → Insights (below)
            } else {
                if dx >  threshold { vm.navigateTo(.rhythm) }   // drag right → Rhythm (left panel)
                else if dx < -threshold { vm.navigateTo(.memory) }  // drag left → Memory (right panel)
            }
        } else {
            switch vm.currentPanel {
            case .seeds:    if dy < -threshold { vm.navigateTo(.home) } // drag up to dismiss
            case .insights: if dy >  threshold { vm.navigateTo(.home) } // drag down to dismiss
            case .rhythm:   if dx < -threshold { vm.navigateTo(.home) } // drag left to dismiss
            case .memory:   if dx >  threshold { vm.navigateTo(.home) } // drag right to dismiss
            default: break
            }
        }
    }
}

#Preview {
    ContentView()
}
