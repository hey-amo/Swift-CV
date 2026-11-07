import SwiftUI
import Foundation

// Tap the chest → gems pop out, hang for a beat, then arc into the counter one by one.
// Each arrival bumps the balance (rolling digits), bounces the 💎 icon and ticks a haptic.

@MainActor
@Observable
final class GemWallet {
    struct Flight: Identifiable {
        let id = UUID()
        let origin: CGPoint
        let scatter: CGSize
        let delay: Double
    }

    private(set) var balance = 0
    private(set) var flights: [Flight] = []
    private(set) var awardCount = 0
    var target: CGPoint = .zero          // centre of the counter icon (set via onGeometryChange)

    func award(_ amount: Int, from origin: CGPoint, reduceMotion: Bool) {
        awardCount += 1
        guard !reduceMotion else {       // Reduce Motion: no flying, just count up
            withAnimation(.snappy) { balance += amount }
            return
        }
        for i in 0..<amount {
            let angle = Double.random(in: 0..<(2 * .pi))
            let radius = Double.random(in: 50...120)
            flights.append(Flight(origin: origin,
                                  scatter: CGSize(width: cos(angle) * radius, height: sin(angle) * radius),
                                  delay: Double(i) * 0.07))
        }
    }

    func landed(_ id: Flight.ID) {
        flights.removeAll { $0.id == id }
        withAnimation(.snappy) { balance += 1 }
    }
}

struct GemCollectDemo: View {
    @State private var wallet = GemWallet()
    @State private var chestPoint: CGPoint = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            VStack {
                HStack { Spacer(); GemCounter() }.padding()
                Spacer()
                chest
                Spacer()
            }
            ForEach(wallet.flights) { FlyingGem(flight: $0) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(.named("gemStage"))
        .background { Color(.systemGroupedBackground).ignoresSafeArea() }
        .environment(wallet)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: wallet.balance)
        .sensoryFeedback(.impact(weight: .heavy), trigger: wallet.awardCount)
    }

    private var chest: some View {
        Button {
            wallet.award(Int.random(in: 6...12), from: chestPoint, reduceMotion: reduceMotion)
        } label: {
            VStack(spacing: 8) {
                Text("🎁").font(.system(size: 96))
                Text("Tap to open").font(.footnote).foregroundStyle(.secondary)
            }
            .padding(24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyframeAnimator(initialValue: 1.0, trigger: wallet.awardCount) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(0.85, duration: 0.08)
                SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
            }
        }
        .onGeometryChange(for: CGPoint.self) { proxy in
            let f = proxy.frame(in: .named("gemStage"))
            return CGPoint(x: f.midX, y: f.midY)
        } action: { chestPoint = $0 }
        .accessibilityLabel("Open chest")
    }
}

private struct GemCounter: View {
    @Environment(GemWallet.self) private var wallet

    var body: some View {
        HStack(spacing: 8) {
            Text("💎")
                .font(.title2)
                .keyframeAnimator(initialValue: 1.0, trigger: wallet.balance) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack {
                        SpringKeyframe(1.35, duration: 0.1)
                        SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
                    }
                }
                .onGeometryChange(for: CGPoint.self) { proxy in
                    let f = proxy.frame(in: .named("gemStage"))
                    return CGPoint(x: f.midX, y: f.midY)
                } action: { wallet.target = $0 }

            Text(wallet.balance, format: .number)
                .font(.title3.bold().monospacedDigit())
                .contentTransition(.numericText(value: Double(wallet.balance)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gems")
        .accessibilityValue("\(wallet.balance)")
    }
}

private struct FlyingGem: View {
    @Environment(GemWallet.self) private var wallet
    let flight: GemWallet.Flight
    @State private var burst: CGFloat = 0       // 0→1 pop out of the chest
    @State private var progress: CGFloat = 0    // 0→1 arc into the counter

    var body: some View {
        Text("💎")
            .font(.system(size: 30))
            .modifier(GemFlight(burst: burst, progress: progress,
                                origin: flight.origin, scatter: flight.scatter, target: wallet.target))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                withAnimation(.spring(duration: 0.45, bounce: 0.45)) { burst = 1 }
                try? await Task.sleep(for: .seconds(0.4 + flight.delay))
                withAnimation(.easeIn(duration: 0.55)) { progress = 1 } completion: {
                    wallet.landed(flight.id)
                }
            }
    }
}

/// Animatable modifier: SwiftUI interpolates `burst` and `progress`, and we turn them into
/// a position along a quadratic Bézier curve, plus spin and scale.
private struct GemFlight: ViewModifier, Animatable {
    var burst: CGFloat
    var progress: CGFloat
    let origin: CGPoint
    let scatter: CGSize
    let target: CGPoint

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(burst, progress) }
        set { burst = newValue.first; progress = newValue.second }
    }

    /// One axis of a quadratic Bézier curve. Kept tiny and explicitly typed so the compiler is happy.
    private func bezier(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ t: CGFloat) -> CGFloat {
        let u: CGFloat = 1 - t
        let first: CGFloat = u * u * a
        let second: CGFloat = 2 * u * t * b
        let third: CGFloat = t * t * c
        return first + second + third
    }

    func body(content: Content) -> some View {
        let startX: CGFloat = origin.x + scatter.width * burst
        let startY: CGFloat = origin.y + scatter.height * burst
        let bend: CGFloat = scatter.width >= 0 ? 80 : -80
        let controlX: CGFloat = (startX + target.x) / 2 + bend
        let controlY: CGFloat = (startY + target.y) / 2

        let x: CGFloat = bezier(startX, controlX, target.x, progress)
        let y: CGFloat = bezier(startY, controlY, target.y, progress)

        let scale: CGFloat = burst * (1 - 0.5 * progress)
        let spin: Angle = .degrees(Double(progress) * 360)

        content
            .scaleEffect(scale)
            .rotationEffect(spin)
            .position(x: x, y: y)
    }
}

#Preview { GemCollectDemo() }
