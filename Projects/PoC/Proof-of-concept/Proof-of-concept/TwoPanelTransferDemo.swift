import SwiftUI

// Two fixed panels side by side. Pieces are NOT children of the panels; they live in one
// flat layer and each computes its resting position from (panel, slot index). Changing a
// piece's panel inside withAnimation makes it glide to the new slot, and releasing it
// anywhere else "snaps back" for free because its resting position never changed.

@MainActor
@Observable
final class TransferBoard {
    enum Panel: CaseIterable { case left, right }

    struct Piece: Identifiable {
        let id = UUID()
        let emoji: String
        var panel: Panel
    }
    struct Drag { let id: Piece.ID; var translation: CGSize }

    let capacity = 5
    private(set) var pieces: [Piece] = ["🐱", "😺", "😸", "😻", "😼", "🙀", "🐈"].map { Piece(emoji: $0, panel: .left) }
    private(set) var drag: Drag?
    private(set) var dropCount = 0
    private(set) var rejectCount = 0
    var size: CGSize = .zero

    // MARK: Layout

    private let margin: CGFloat = 16, gap: CGFloat = 16, headerHeight: CGFloat = 52, cellGap: CGFloat = 8

    var panelWidth: CGFloat { (size.width - 2 * margin - gap) / 2 }
    var slotSize: CGFloat { min(72, (panelWidth - 16 - cellGap) / 2) }

    func rect(of panel: Panel) -> CGRect {
        CGRect(x: panel == .left ? margin : margin + panelWidth + gap,
               y: margin, width: panelWidth, height: min(size.height - 2 * margin, 460))
    }

    func count(in panel: Panel) -> Int { pieces.filter { $0.panel == panel }.count }

    private func restCenter(of piece: Piece) -> CGPoint {
        let r = rect(of: piece.panel)
        let index = pieces.filter { $0.panel == piece.panel }.firstIndex { $0.id == piece.id } ?? 0
        let rowWidth = 2 * slotSize + cellGap
        return CGPoint(x: r.midX - rowWidth / 2 + slotSize / 2 + CGFloat(index % 2) * (slotSize + cellGap),
                       y: r.minY + headerHeight + slotSize / 2 + CGFloat(index / 2) * (slotSize + cellGap))
    }

    func center(of piece: Piece) -> CGPoint {
        var c = restCenter(of: piece)
        if let d = drag, d.id == piece.id { c.x += d.translation.width; c.y += d.translation.height }
        return c
    }

    /// Panel (other than the piece's own) currently under the dragged piece – for highlighting.
    var hoveredPanel: Panel? {
        guard let d = drag, let piece = pieces.first(where: { $0.id == d.id }) else { return nil }
        let p = center(of: piece)
        return Panel.allCases.first { $0 != piece.panel && rect(of: $0).contains(p) }
    }

    // MARK: Gestures

    func dragChanged(_ id: Piece.ID, translation: CGSize) {
        drag = Drag(id: id, translation: translation)
    }

    func dragEnded(_ id: Piece.ID) {
        guard let drag, drag.id == id,
              let i = pieces.firstIndex(where: { $0.id == id }) else { return }
        let piece = pieces[i]
        let point = center(of: piece)
        let target = Panel.allCases.first { rect(of: $0).contains(point) }

        withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
            self.drag = nil
            guard let target, target != piece.panel else { return }          // between panels → snap back
            if target == .right && count(in: .right) >= capacity { rejectCount += 1; return }
            var moved = pieces.remove(at: i)
            moved.panel = target
            pieces.append(moved)
            dropCount += 1
        }
    }

    /// Non-drag alternative for VoiceOver.
    func move(_ id: Piece.ID) {
        guard let i = pieces.firstIndex(where: { $0.id == id }) else { return }
        let target: Panel = pieces[i].panel == .left ? .right : .left
        if target == .right && count(in: .right) >= capacity { rejectCount += 1; return }
        withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
            var moved = pieces.remove(at: i)
            moved.panel = target
            pieces.append(moved)
            dropCount += 1
        }
    }
}

struct TwoPanelTransferDemo: View {
    @State private var board = TransferBoard()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(TransferBoard.Panel.allCases, id: \.self) { PanelBackground(panel: $0) }
                ForEach(board.pieces) { piece in
                    PieceView(piece: piece)
                        .zIndex(board.drag?.id == piece.id ? 1 : 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .coordinateSpace(.named("board"))
            .onChange(of: geo.size, initial: true) { board.size = geo.size }
        }
        .background { Color(.systemGroupedBackground).ignoresSafeArea() }
        .environment(board)
        .sensoryFeedback(.success, trigger: board.dropCount)
        .sensoryFeedback(.error, trigger: board.rejectCount)
    }
}

private struct PanelBackground: View {
    @Environment(TransferBoard.self) private var board
    let panel: TransferBoard.Panel

    var body: some View {
        let r = board.rect(of: panel)
        let n = board.count(in: panel)
        let hovered = board.hoveredPanel == panel
        let full = panel == .right && n >= board.capacity
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        shape.fill(.regularMaterial)
            .overlay {
                shape.strokeBorder(full ? Color.orange : Color.accentColor, lineWidth: 3)
                    .opacity(hovered ? 1 : 0)
            }
            .overlay(alignment: .top) {
                Text(panel == .left ? "World (\(n))" : "Inventory (\(n)/\(board.capacity))")
                    .font(.headline.monospacedDigit())
                    .contentTransition(.numericText())
                    .animation(.snappy, value: n)
                    .padding(.top, 16)
            }
            .overlay {
                if panel == .right && n == 0 {
                    Text("Drop here").foregroundStyle(.tertiary)
                }
            }
            .animation(.easeOut(duration: 0.15), value: hovered)
            .frame(width: r.width, height: r.height)
            .position(x: r.midX, y: r.midY)
    }
}

private struct PieceView: View {
    @Environment(TransferBoard.self) private var board
    let piece: TransferBoard.Piece

    var body: some View {
        let dragging = board.drag?.id == piece.id
        Text(piece.emoji)
            .font(.system(size: board.slotSize * 0.7))
            .frame(width: board.slotSize, height: board.slotSize)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(dragging ? 1.15 : 1)
            .shadow(color: .black.opacity(0.25), radius: dragging ? 12 : 0, y: dragging ? 8 : 0)
            .animation(.spring(duration: 0.25, bounce: 0.4), value: dragging)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))
                    .onChanged { board.dragChanged(piece.id, translation: $0.translation) }
                    .onEnded { _ in board.dragEnded(piece.id) }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Cat")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: piece.panel == .left ? "Move to inventory" : "Move to world") {
                board.move(piece.id)
            }
            .position(board.center(of: piece))
    }
}

#Preview { TwoPanelTransferDemo() }
