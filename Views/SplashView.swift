import SwiftUI

// MARK: - Entry point

struct SplashView: View {
    let onFinished: () -> Void

    @State private var glowOn        = false
    @State private var orbOn         = false
    @State private var titleOn       = false
    @State private var titleY: CGFloat = 44
    @State private var subtitleOn    = false
    @State private var leaving       = false

    var body: some View {
        ZStack {
            // Deep navy background
            Color(red: 0.059, green: 0.086, blue: 0.137).ignoresSafeArea()

            // Ambient bloom behind the orb
            RadialGradient(
                colors: [Color.accent.opacity(0.16), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .opacity(glowOn ? 1 : 0)
            .animation(.easeOut(duration: 1.6), value: glowOn)

            // Animated neural-network orb (Canvas + TimelineView)
            NeuralOrb()
                .opacity(orbOn ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: orbOn)

            // Branding
            VStack(spacing: 10) {
                Spacer()

                Text("Daily Advisor")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .shimmerEffect()
                    .opacity(titleOn ? 1 : 0)
                    .offset(y: titleY)

                Text("Your AI Leadership Coach")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(red: 0.722, green: 0.773, blue: 0.839).opacity(0.75))
                    .opacity(subtitleOn ? 1 : 0)
                    .animation(.easeIn(duration: 0.55), value: subtitleOn)

                Spacer().frame(height: 100)
            }
        }
        .opacity(leaving ? 0 : 1)
        .animation(.easeInOut(duration: 0.65), value: leaving)
        .onAppear { play() }
    }

    private func play() {
        at(0.10) { glowOn = true }
        at(0.20) { orbOn  = true }
        at(0.90) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
                titleOn = true
                titleY  = 0
            }
        }
        at(1.55) { subtitleOn = true }
        at(3.30) { leaving = true }
        at(3.95) { onFinished() }
    }

    private func at(_ delay: Double, run: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: run)
    }
}

// MARK: - Neural orb

struct NeuralOrb: View {
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let c   = CGPoint(x: size.width / 2, y: size.height / 2)
                let t   = tl.date.timeIntervalSinceReferenceDate
                let gold = Color(red: 0.949, green: 0.663, blue: 0.231)

                drawRings(ctx: ctx, center: c, time: t, accent: gold)
                drawNetwork(ctx: ctx, center: c, time: t, accent: gold)
            }
        }
    }

    // Four staggered expanding rings
    private func drawRings(
        ctx: GraphicsContext, center: CGPoint, time: Double, accent: Color
    ) {
        for i in 0..<4 {
            let offset = Double(i) * 0.25
            let frac   = (time * 0.44 + offset).truncatingRemainder(dividingBy: 1.0)
            let r      = CGFloat(22 + frac * 180)
            let alpha  = (1 - frac) * 0.42
            var path   = Path()
            path.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
            ctx.stroke(path, with: .color(accent.opacity(alpha)), lineWidth: 1.3)
        }
    }

    // 8 orbiting nodes on two radii + connecting edges
    private func drawNetwork(
        ctx: GraphicsContext, center: CGPoint, time: Double, accent: Color
    ) {
        let n      = 8
        let speed  = 18.0 // degrees / second
        var pts    = [CGPoint]()

        for i in 0..<n {
            let deg = time * speed + Double(i) * (360.0 / Double(n))
            let rad = deg * .pi / 180
            let r: Double = i % 2 == 0 ? 85 : 62
            pts.append(CGPoint(
                x: center.x + CGFloat(r * cos(rad)),
                y: center.y + CGFloat(r * sin(rad))
            ))
        }

        // Edges
        for i in 0..<n {
            for skip in [1, 2] {
                var line = Path()
                line.move(to: pts[i])
                line.addLine(to: pts[(i + skip) % n])
                ctx.stroke(line, with: .color(accent.opacity(0.16)), lineWidth: 0.75)
            }
        }

        // Nodes
        for (i, p) in pts.enumerated() {
            let s: CGFloat = i % 2 == 0 ? 5.5 : 4.0
            var dot = Path()
            dot.addEllipse(in: CGRect(x: p.x - s / 2, y: p.y - s / 2, width: s, height: s))
            ctx.fill(dot, with: .color(accent))
        }

        // Centre anchor
        var cp = Path()
        cp.addEllipse(in: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
        ctx.fill(cp, with: .color(accent))
    }
}

// MARK: - Shimmer modifier

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.5

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.55), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.38)
                    .offset(x: phase * (geo.size.width * 1.38))
                    .blendMode(.overlay)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2.1)
                    .delay(1.0)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerModifier())
    }
}
