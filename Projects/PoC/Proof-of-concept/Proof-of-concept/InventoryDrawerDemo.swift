import SwiftUI

// MARK: - Model ---------------------------------------------------------------
//
// One @Observable class owns all state + the drag/drawer rules.
// (No ObservableObject / @Published / @StateObject needed on iOS 17+.)
//
// KEY IDEA: the item you're dragging is drawn in a single overlay at the very top
// of the ZStack. That way it can float over the drawer, leave the drawer, and keep
// following your finger while the drawer slides away underneath it. The views that
// own the DragGesture stay in the hierarchy (just invisible) so the gesture never cancels.

@MainActor
@Observable
final class InventoryStage {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let emoji: String
        var home: CGPoint          // "origin" in the world – where it snaps back to
    }

    enum Origin { case world, inventory }
    enum DrawerState { case hidden, partial, expanded }
    enum Status: Equatable { case added(String), full }

    struct Carry {
        let id: Item.ID
        let emoji: String
        let origin: Origin
        let grab: CGSize           // finger → item-centre offset
        var point: CGPoint         // item centre, stage coordinates
        var baseScale: CGFloat
        var isSettling = false
    }

    // Layout shared by model + views so the "fly into slot" target is exact.
    enum Layout {
        static let pad: CGFloat = 16
        static let spacing: CGFloat = 8
        static let slotsTop: CGFloat = 84       // grabber 20 + header 56 + gap 8
        static let topGap: CGFloat = 8
        static let carryFont: CGFloat = 64
        static let summonInset: CGFloat = 190   // finger this close to the bottom → drawer pops up
    }

    let capacity = 5

    private(set) var world: [Item] = []
    private(set) var inventory: [Item] = []
    private(set) var drawer: DrawerState = .hidden
    private(set) var carry: Carry?
    private(set) var status: Status?
    private(set) var receivedCount = 0     // haptic / animation triggers
    private(set) var rejectCount = 0
    var drawerPull: CGFloat = 0            // live finger offset while pulling the drawer

    private(set) var size: CGSize = .zero
    private(set) var safeTop: CGFloat = 0
    private(set) var safeBottom: CGFloat = 0

    @ObservationIgnored private var openedByDrag = false
    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    // MARK: Geometry

    var slotSize: CGFloat { (size.width - 2 * Layout.pad - 4 * Layout.spacing) / 5 }
    var slotScale: CGFloat { slotSize * 0.62 / Layout.carryFont }
    var partialHeight: CGFloat { Layout.slotsTop + slotSize + 12 + 28 + 16 + safeBottom }
    var drawerHeight: CGFloat { size.height - (safeTop + Layout.topGap) }

    func top(_ state: DrawerState) -> CGFloat {
        switch state {
        case .hidden:   size.height + 16
        case .partial:  size.height - partialHeight
        case .expanded: safeTop + Layout.topGap
        }
    }
    var drawerTop: CGFloat { top(drawer) + drawerPull }

    var isOverDrawer: Bool {
        guard let c = carry else { return false }
        return drawer == .partial && c.point.y > top(.partial)
    }

    func slotCenter(_ index: Int) -> CGPoint {
        let s = slotSize
        return CGPoint(x: Layout.pad + s / 2 + CGFloat(index) * (s + Layout.spacing),
                       y: top(.partial) + Layout.slotsTop + s / 2)
    }

    private func clampToWorld(_ p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(p.x, 44), size.width - 44),
                y: min(max(p.y, safeTop + 60), top(.partial) - 48))
    }

    func configure(size: CGSize, safeArea: EdgeInsets) {
        self.size = size
        safeTop = safeArea.top
        safeBottom = safeArea.bottom
        if world.isEmpty && inventory.isEmpty { seed() }
    }

    private func seed() {
        let faces = ["🐱", "😺", "😸", "😻", "😼", "🙀", "🐈"]   // 7 cats so you can hit the 5-item cap
        world = faces.enumerated().map { i, face in
            Item(emoji: face,
                 home: CGPoint(x: size.width * (0.2 + 0.3 * CGFloat(i % 3)),
                               y: safeTop + 120 + 120 * CGFloat(i / 3)))
        }
    }

    // MARK: Drawer control

    func setDrawer(_ state: DrawerState) {
        withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
            drawer = state
            drawerPull = 0
        }
    }

    func toggleFromButton() {
        cancelAutoDismiss(); openedByDrag = false
        setDrawer(drawer == .hidden ? .partial : .hidden)
    }

    func toggleExpanded() {
        guard carry == nil else { return }               // (7) no full screen while moving items
        cancelAutoDismiss(); openedByDrag = false
        setDrawer(drawer == .expanded ? .partial : .expanded)
    }

    func dismissDrawer() {
        cancelAutoDismiss(); status = nil
        setDrawer(.hidden)
    }

    /// Finger pulling the drawer. Pulling UP only rubber-bands a few points (8): the
    /// only way to go full screen is the button.
    func pull(_ dy: CGFloat) {
        guard carry == nil, drawer != .hidden else { return }
        cancelAutoDismiss()
        drawerPull = dy >= 0 ? dy : -min(24, (-dy).squareRoot() * 2)
    }

    func endPull(translation: CGFloat, predicted: CGFloat) {
        switch drawer {
        case .hidden: break
        case .partial:
            setDrawer(translation > 90 || predicted > 220 ? .hidden : .partial)
        case .expanded:
            if translation > 300 || predicted > 600 { setDrawer(.hidden) }
            else { setDrawer(translation > 90 ? .partial : .expanded) }
        }
    }

    // MARK: Drag handling

    func dragChanged(_ id: Item.ID, from origin: Origin, location: CGPoint, start: CGPoint) {
        if carry == nil { beginCarry(id, origin, start) }
        guard var c = carry, c.id == id, !c.isSettling else { return }
        c.point = CGPoint(x: location.x + c.grab.width, y: location.y + c.grab.height)
        carry = c
        updateDrawer(travelled: hypot(location.x - start.x, location.y - start.y))
    }

    private func beginCarry(_ id: Item.ID, _ origin: Origin, _ start: CGPoint) {
        let source = origin == .world ? world : inventory
        guard let item = source.first(where: { $0.id == id }) else { return }
        cancelAutoDismiss()
        status = nil
        drawerPull = 0
        let grab = origin == .world
            ? CGSize(width: item.home.x - start.x, height: item.home.y - start.y)
            : .zero
        carry = Carry(id: id, emoji: item.emoji, origin: origin, grab: grab,
                      point: CGPoint(x: start.x + grab.width, y: start.y + grab.height),
                      baseScale: origin == .world ? 1 : slotScale)
    }

    /// (3) + (9): the drawer follows where the item is. Summon and dismiss thresholds
    /// are far apart (hysteresis) so it never flickers.
    private func updateDrawer(travelled: CGFloat) {
        guard let c = carry else { return }
        let y = c.point.y
        let dismissY = top(.partial) - 60
        switch drawer {
        case .hidden:
            if y > size.height - Layout.summonInset {
                openedByDrag = true
                setDrawer(.partial)
            }
        case .partial:
            if y < dismissY && (c.origin == .inventory || openedByDrag) { setDrawer(.hidden) }
        case .expanded:
            // Grabbing from the full-screen drawer: as soon as the item leaves its slot the
            // drawer drops away (straight to hidden if you're already high up the screen).
            if travelled > 16 { setDrawer(y < dismissY ? .hidden : .partial) }
        }
    }

    func dragEnded(_ id: Item.ID) {
        guard let c = carry, c.id == id, !c.isSettling else { return }
        let over = isOverDrawer

        switch c.origin {
        case .world:
            guard let item = world.first(where: { $0.id == id }) else { carry = nil; return }
            if over, inventory.count < capacity {
                // (5) fly into the next free slot, then the drawer confirms receipt
                settle(to: slotCenter(inventory.count), scale: slotScale) {
                    self.world.removeAll { $0.id == id }
                    self.inventory.append(item)
                    self.carry = nil
                    self.status = .added(item.emoji)
                    self.receivedCount += 1
                    self.scheduleAutoDismiss()
                }
            } else {
                if over { status = .full; rejectCount += 1 }
                // (1) snap back to origin
                settle(to: item.home, scale: 1) {
                    self.carry = nil
                    self.scheduleAutoDismiss()
                }
            }

        case .inventory:
            guard let index = inventory.firstIndex(where: { $0.id == id }) else { carry = nil; return }
            if over {
                settle(to: slotCenter(index), scale: slotScale) {
                    self.carry = nil
                    self.scheduleAutoDismiss()
                }
            } else {
                var item = inventory[index]
                item.home = clampToWorld(c.point)            // it now lives where you dropped it
                cancelAutoDismiss()
                setDrawer(.hidden)
                settle(to: item.home, scale: 1) {
                    self.inventory.removeAll { $0.id == id }
                    self.world.append(item)
                    self.carry = nil
                }
            }
        }
    }

    private func settle(to point: CGPoint, scale: CGFloat, finish: @escaping () -> Void) {
        withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
            carry?.isSettling = true
            carry?.point = point
            carry?.baseScale = scale
        } completion: {
            finish()
        }
    }

    // MARK: Non-drag alternatives (VoiceOver / Switch Control / "Move out" button)

    func store(_ id: Item.ID) {
        guard inventory.count < capacity, let i = world.firstIndex(where: { $0.id == id }) else { return }
        let item = world.remove(at: i)
        inventory.append(item)
        status = .added(item.emoji)
        receivedCount += 1
    }

    func release(_ id: Item.ID) {
        guard let i = inventory.firstIndex(where: { $0.id == id }) else { return }
        let item = inventory.remove(at: i)
        withAnimation(.snappy) { world.append(item) }
    }

    // MARK: Auto dismiss (5)

    private func scheduleAutoDismiss() {
        dismissTask?.cancel()
        guard drawer == .partial else { return }
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self, self.carry == nil else { return }
            self.status = nil
            if self.openedByDrag, self.drawer == .partial { self.setDrawer(.hidden) }
        }
    }

    private func cancelAutoDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }
}

// MARK: - Root view -----------------------------------------------------------

struct InventoryDrawerDemo: View {
    @State private var stage = InventoryStage()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Bottom → top draw order. Tapping empty background dismisses the drawer,
                // but sits *below* the cats so they stay grabbable while the drawer is open.
                Color(.systemGroupedBackground)
                    .onTapGesture { if stage.drawer != .hidden { stage.dismissDrawer() } }

                Text("Drag a cat to the briefcase 🧳")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, geo.safeAreaInsets.top + 12)
                    .allowsHitTesting(false)

                ForEach(stage.world) { WorldItem(item: $0) }

                BriefcaseButton()

                Color.black
                    .opacity(stage.drawer == .expanded ? 0.3 : 0)
                    .allowsHitTesting(stage.drawer == .expanded)
                    .onTapGesture { stage.toggleExpanded() }

                InventoryDrawer()
                    .frame(height: stage.drawerHeight)
                    .offset(y: stage.drawerTop)

                CarryOverlay()
            }
            .coordinateSpace(.named("stage"))
            .onChange(of: geo.size, initial: true) {
                stage.configure(size: geo.size, safeArea: geo.safeAreaInsets)
            }
        }
        .ignoresSafeArea()
        .environment(stage)
        .sensoryFeedback(.success, trigger: stage.receivedCount)
        .sensoryFeedback(.error, trigger: stage.rejectCount)
        .sensoryFeedback(.impact(weight: .light), trigger: stage.carry?.id)
        .sensoryFeedback(.selection, trigger: stage.drawer)
    }
}

// MARK: - Pieces --------------------------------------------------------------

private struct CatFace: View {
    let emoji: String
    var body: some View {
        Text(emoji)
            .font(.system(size: InventoryStage.Layout.carryFont))
            .frame(width: 84, height: 84)                    // ≥ 44pt hit target
            .contentShape(Circle())
    }
}

private struct WorldItem: View {
    @Environment(InventoryStage.self) private var stage
    let item: InventoryStage.Item

    var body: some View {
        CatFace(emoji: item.emoji)
            .opacity(stage.carry?.id == item.id ? 0 : 1)     // hidden, not removed → gesture survives
            .gesture(
                // Named space = finger position isn't affected by the view moving.
                DragGesture(minimumDistance: 0, coordinateSpace: .named("stage"))
                    .onChanged { stage.dragChanged(item.id, from: .world, location: $0.location, start: $0.startLocation) }
                    .onEnded { _ in stage.dragEnded(item.id) }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Cat")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Put in briefcase") { stage.store(item.id) }
            .position(item.home)
    }
}

private struct BriefcaseButton: View {
    @Environment(InventoryStage.self) private var stage

    var body: some View {
        let count = stage.inventory.count
        let hot = (stage.carry?.point.y ?? 0) > stage.size.height - InventoryStage.Layout.summonInset
                  && stage.carry != nil

        Button { stage.toggleFromButton() } label: {
            Text("🧳")
                .font(.system(size: 40))
                .frame(width: 72, height: 72)
                .background(.regularMaterial, in: Circle())
                .overlay(alignment: .topTrailing) {
                    Text("\(count)/\(stage.capacity)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(count == stage.capacity ? Color.orange : Color.accentColor, in: Capsule())
                        .contentTransition(.numericText())
                        .animation(.snappy, value: count)
                        .offset(x: 12, y: -6)
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(hot ? 1.2 : 1)
        .animation(.spring(duration: 0.3, bounce: 0.5), value: hot)
        .opacity(stage.drawer == .hidden ? 1 : 0)
        .allowsHitTesting(stage.drawer == .hidden)
        .accessibilityLabel("Inventory, \(count) of \(stage.capacity) items")
        .position(x: stage.size.width / 2, y: stage.size.height - stage.safeBottom - 52)
    }
}

private struct CarryOverlay: View {
    @Environment(InventoryStage.self) private var stage
    var body: some View {
        if let carry = stage.carry { Floating(carry: carry) }
    }

    private struct Floating: View {
        let carry: InventoryStage.Carry
        @State private var lifted = false

        var body: some View {
            let up = lifted && !carry.isSettling
            Text(carry.emoji)
                .font(.system(size: InventoryStage.Layout.carryFont))
                .scaleEffect(up ? 1.15 : carry.baseScale)
                .shadow(color: .black.opacity(0.25), radius: up ? 14 : 0, y: up ? 8 : 0)
                .position(carry.point)
                .allowsHitTesting(false)
                .onAppear { withAnimation(.spring(duration: 0.3, bounce: 0.4)) { lifted = true } }
        }
    }
}

// MARK: - Drawer --------------------------------------------------------------

private struct InventoryDrawer: View {
    @Environment(InventoryStage.self) private var stage

    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)

        VStack(spacing: 0) {
            Capsule().fill(.tertiary).frame(width: 36, height: 5).frame(height: 20)   // grabber
            header.frame(height: 56)
            slots.padding(.top, 8)
            statusLine.padding(.top, 12)
            if stage.drawer == .expanded {
                details.padding(.top, 8).transition(.opacity)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, InventoryStage.Layout.pad)
        .frame(maxWidth: .infinity)
        .background {
            shape.fill(.regularMaterial)
                .overlay { shape.strokeBorder(Color.accentColor, lineWidth: 3).opacity(stage.isOverDrawer ? 1 : 0) }
                .shadow(color: .black.opacity(0.15), radius: 20, y: -4)
                .animation(.easeOut(duration: 0.15), value: stage.isOverDrawer)
        }
        .contentShape(shape)
        .gesture(
            DragGesture()
                .onChanged { stage.pull($0.translation.height) }
                .onEnded { stage.endPull(translation: $0.translation.height,
                                         predicted: $0.predictedEndTranslation.height) }
        )
        .accessibilityHidden(stage.drawer == .hidden)
    }

    private var header: some View {
        let count = stage.inventory.count
        let expanded = stage.drawer == .expanded
        return ZStack {
            Text("My Inventory").font(.headline)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(count)/\(stage.capacity)")
                        .font(.subheadline.bold().monospacedDigit())
                        .contentTransition(.numericText())
                    HStack(spacing: 3) {
                        ForEach(0..<stage.capacity, id: \.self) { i in
                            Capsule()
                                .fill(i < count ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(width: 12, height: 4)
                        }
                    }
                }
                .animation(.snappy, value: count)
                Spacer()
                HStack(spacing: 0) {
                    Button { stage.toggleExpanded() } label: {
                        Image(systemName: expanded ? "arrow.down.right.and.arrow.up.left"
                                                   : "arrow.up.left.and.arrow.down.right")
                            .frame(width: 44, height: 44)
                    }
                    .disabled(stage.carry != nil)                         // (7)
                    .accessibilityLabel(expanded ? "Collapse inventory" : "Expand inventory")

                    Button { stage.dismissDrawer() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close inventory")
                }
                .font(.title3)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var slots: some View {
        HStack(spacing: InventoryStage.Layout.spacing) {
            ForEach(0..<stage.capacity, id: \.self) { index in
                SlotView(index: index)
                    .frame(width: stage.slotSize, height: stage.slotSize)
            }
        }
    }

    @ViewBuilder private var statusLine: some View {
        Group {
            switch stage.status {
            case .added(let emoji):
                Label("\(emoji) added to inventory", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: stage.receivedCount)
            case .full:
                Label("Briefcase is full", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: stage.rejectCount)
            case nil:
                Text(stage.inventory.isEmpty ? "Drop a 🐱 here" : "Drag an item out to use it")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .frame(height: 28)
        .animation(.snappy, value: stage.status)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONTENTS").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            if stage.inventory.isEmpty {
                Text("Nothing here yet.").foregroundStyle(.secondary)
            }
            ForEach(Array(stage.inventory.enumerated()), id: \.element.id) { index, item in
                HStack {
                    Text(item.emoji).font(.title2)
                    Text("Cat \(index + 1)")
                    Spacer()
                    Button("Move out") { stage.release(item.id) }
                        .buttonStyle(.bordered).controlSize(.small)
                }
                if index < stage.inventory.count - 1 { Divider() }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SlotView: View {
    @Environment(InventoryStage.self) private var stage
    let index: Int

    var body: some View {
        let item = stage.inventory.indices.contains(index) ? stage.inventory[index] : nil
        let isNext = index == stage.inventory.count
        let isNewest = index == stage.inventory.count - 1
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        ZStack {
            shape.fill(.quaternary)
            if item == nil {
                shape.strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(isNext && stage.isOverDrawer ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            if let item {
                Text(item.emoji)
                    .font(.system(size: stage.slotSize * 0.62))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(shape)
                    .opacity(stage.carry?.id == item.id ? 0 : 1)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("stage"))
                            .onChanged { stage.dragChanged(item.id, from: .inventory, location: $0.location, start: $0.startLocation) }
                            .onEnded { _ in stage.dragEnded(item.id) }
                    )
                    .accessibilityLabel("Cat in slot \(index + 1)")
                    .accessibilityAction(named: "Take out") { stage.release(item.id) }
            }
        }
        // little "received" pop on the newest slot
        // (isNewest is read here, on the main actor, so the Sendable closure only captures a Bool)
        .keyframeAnimator(initialValue: 1.0, trigger: stage.receivedCount) { content, scale in
            content.scaleEffect(isNewest ? scale : 1)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(1.2, duration: 0.15)
                SpringKeyframe(1.0, duration: 0.45, spring: .bouncy)
            }
        }
    }
}

#Preview { InventoryDrawerDemo() }
