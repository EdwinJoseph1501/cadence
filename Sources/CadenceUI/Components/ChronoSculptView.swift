import CadenceCore
import SwiftUI

/// An original, generative visual centerpiece engineered with SwiftUI `Canvas` and procedural harmonic geometry.
///
/// Modulates fluid surface geometry and multi-pass volumetric shading in real time according to timer progress and phase.
public struct ChronoSculptView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let progress: Double
    public let phase: TimerPhase
    public let diameter: CGFloat
    public let timestamp: TimeInterval

    private static let shellHighlight = Color(
        token: ColorToken(hex: "#251221") ?? BloodMoonPalette.surfaceElevated
    )

    public init(
        progress: Double,
        phase: TimerPhase,
        diameter: CGFloat = 304,
        timestamp: TimeInterval = 0
    ) {
        self.progress = progress
        self.phase = phase
        self.diameter = diameter
        self.timestamp = timestamp
    }

    private var clampedProgress: Double {
        min(max(progress, 0.0), 1.0)
    }

    public var body: some View {
        Group {
            if ChronoSculptMetalPipeline.shared.pipelineState != nil {
                ChronoSculptMetalView(
                    progress: clampedProgress,
                    phase: phase,
                    timestamp: timestamp,
                    reduceMotion: reduceMotion
                )
            } else {
                canvasFallback
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }

    private var canvasFallback: some View {
        Canvas { context, size in
            let cx = size.width / 2.0
            let cy = size.height / 2.0
            let baseRadius = (diameter / 2.0) - 18.0

            guard baseRadius > 0 else { return }

            // 1. Generate multi-layer organic paths
            let sampleCount = 64
            var pointsA: [CGPoint] = []
            var pointsB: [CGPoint] = []
            pointsA.reserveCapacity(sampleCount)
            pointsB.reserveCapacity(sampleCount)

            let radiusB = baseRadius * 0.90

            for i in 0..<sampleCount {
                let theta = -Double.pi / 2.0 + (Double(i) * 2.0 * Double.pi / Double(sampleCount))

                // Path A: Deep Outer Shell evaluated at base angles theta
                let rA = radius(
                    for: theta,
                    baseRadius: baseRadius,
                    phaseOffset: 0.0,
                    time: timestamp
                )
                pointsA.append(CGPoint(x: cx + rA * cos(theta), y: cy + rA * sin(theta)))

                // Path B: Secondary Mid-Fold Membrane evaluated with phase offset theta + 0.4
                let rB = radius(
                    for: theta,
                    baseRadius: radiusB,
                    phaseOffset: 0.4,
                    time: timestamp
                )
                pointsB.append(CGPoint(x: cx + rB * cos(theta), y: cy + rB * sin(theta)))
            }

            let pathA = smoothClosedPath(from: pointsA)
            let pathB = smoothClosedPath(from: pointsB)

            // Pass 1: Ambient Occlusion & Deep Volumetric Aura
            drawAmbientAura(
                context: context,
                cx: cx,
                cy: cy,
                radius: baseRadius
            )

            // Pass 2: Outer Shell (Obsidian Glass)
            drawOuterShell(
                context: context,
                path: pathA,
                cx: cx,
                cy: cy,
                radius: baseRadius
            )

            // Pass 3: Mid-Fold Membrane (Translucent Liquid Layer)
            drawMidFoldMembrane(
                context: context,
                path: pathB,
                cx: cx,
                cy: cy,
                radius: radiusB
            )

            // Pass 4: Ascending Thermal Core Light (clipped to Path B)
            drawAscendingCoreLight(
                context: context,
                clipPath: pathB,
                cx: cx,
                cy: cy,
                radius: radiusB
            )

            // Pass 5: Flowing Caustic Spine (Progress Path on Path A)
            drawCausticSpine(
                context: context,
                pathA: pathA,
                startPoint: pointsA.first ?? CGPoint(x: cx, y: cy - baseRadius)
            )

            // Pass 6: Specular Meniscus Glint
            drawSpecularGlint(
                context: context,
                cx: cx,
                cy: cy,
                radius: baseRadius
            )
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }

    // MARK: - Procedural Geometry & Motion

    private func motionDelta(theta: Double, time: Double) -> Double {
        if reduceMotion {
            return 0.0
        }

        switch phase {
            case .running:
                let a1 = 0.04 * sin(3.0 * theta + 0.8 * time)
                let a2 = 0.025 * cos(4.0 * theta - 1.1 * time)
                let a3 = 0.02 * sin(theta + 0.5 * time)
                return a1 + a2 + a3
            case .idle:
                let a1 = 0.015 * sin(2.0 * theta + 0.3 * time)
                let a2 = 0.01 * cos(3.0 * theta - 0.3 * time)
                return a1 + a2
            case .paused:
                // Static frozen state (t = 0)
                let a1 = 0.04 * sin(3.0 * theta)
                let a2 = 0.025 * cos(4.0 * theta)
                let a3 = 0.02 * sin(theta)
                return a1 + a2 + a3
            case .completed:
                // Serene emerald resonance
                let a1 = 0.02 * sin(2.0 * theta + 0.4 * time)
                let a2 = 0.015 * cos(3.0 * theta - 0.4 * time)
                return a1 + a2
        }
    }

    private func radius(
        for theta: Double,
        baseRadius: Double,
        phaseOffset: Double,
        time: Double
    ) -> Double {
        let evalTheta = theta + phaseOffset
        let baseModulation =
            0.16 * sin(2.0 * evalTheta - 0.45)
            + 0.12 * cos(3.0 * evalTheta + 0.75)
            + 0.06 * sin(5.0 * evalTheta - 1.2)
        let delta = motionDelta(theta: evalTheta, time: time)
        return baseRadius * (1.0 + baseModulation + delta)
    }

    // MARK: - Spline Geometry

    private func smoothClosedPath(from points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 3 else { return path }

        path.move(to: points[0])
        let n = points.count
        for i in 0..<n {
            let prev = points[(i - 1 + n) % n]
            let curr = points[i]
            let next = points[(i + 1) % n]
            let next2 = points[(i + 2) % n]

            let c1 = CGPoint(
                x: curr.x + (next.x - prev.x) / 6.0,
                y: curr.y + (next.y - prev.y) / 6.0
            )
            let c2 = CGPoint(
                x: next.x - (next2.x - curr.x) / 6.0,
                y: next.y - (next2.y - curr.y) / 6.0
            )

            path.addCurve(to: next, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Multi-Pass Volumetric Rendering

    /// Pass 1: Ambient Occlusion & Deep Volumetric Aura
    private func drawAmbientAura(
        context: GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat
    ) {
        let auraColor: Color
        switch phase {
            case .running:
                auraColor = Color.cadenceAccent.opacity(0.25)
            case .paused:
                auraColor = Color.cadenceMutedRose.opacity(0.25)
            case .completed:
                auraColor = Color.cadenceSuccess.opacity(0.35)
            case .idle:
                auraColor = Color.cadenceDeepBurgundy.opacity(0.45)
        }

        let auraRadius = radius * 1.35
        let auraShader = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [
                auraColor,
                auraColor.opacity(0.35),
                Color.clear,
            ]),
            center: CGPoint(x: cx, y: cy),
            startRadius: 0,
            endRadius: auraRadius
        )

        let auraRect = CGRect(
            x: cx - auraRadius,
            y: cy - auraRadius,
            width: auraRadius * 2.0,
            height: auraRadius * 2.0
        )
        context.fill(Path(ellipseIn: auraRect), with: auraShader)
    }

    /// Pass 2: Outer Shell (Obsidian Glass)
    private func drawOuterShell(
        context: GraphicsContext,
        path: Path,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat
    ) {
        let shellShader = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [
                Self.shellHighlight,
                Color.cadenceSurfaceElevated,
                Color.cadenceBackground,
            ]),
            startPoint: CGPoint(x: cx - radius * 0.85, y: cy - radius * 0.85),
            endPoint: CGPoint(x: cx + radius * 0.85, y: cy + radius * 0.85)
        )
        context.fill(path, with: shellShader)

        // Subtle 1.0pt hairline border in Color.cadenceBorder.opacity(0.6)
        context.stroke(
            path,
            with: .color(Color.cadenceBorder.opacity(0.6)),
            style: StrokeStyle(lineWidth: 1.0)
        )
    }

    /// Pass 3: Mid-Fold Membrane (Translucent Liquid Layer)
    private func drawMidFoldMembrane(
        context: GraphicsContext,
        path: Path,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat
    ) {
        let membraneShader = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [
                Color.cadenceDeepBurgundy.opacity(0.70),
                Color.cadenceSurfaceElevated.opacity(0.85),
            ]),
            startPoint: CGPoint(x: cx + radius * 0.8, y: cy - radius * 0.8),
            endPoint: CGPoint(x: cx - radius * 0.8, y: cy + radius * 0.8)
        )
        context.fill(path, with: membraneShader)

        // Delicate 1.0pt stroke in Color.cadenceAccentHighlight.opacity(0.25)
        context.stroke(
            path,
            with: .color(Color.cadenceAccentHighlight.opacity(0.25)),
            style: StrokeStyle(lineWidth: 1.0)
        )
    }

    /// Pass 4: Ascending Thermal Core Light (clipped to Path B)
    private func drawAscendingCoreLight(
        context: GraphicsContext,
        clipPath: Path,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat
    ) {
        var clippedContext = context
        clippedContext.clip(to: clipPath)

        let coreColor: Color
        switch phase {
            case .running:
                coreColor = Color.cadenceAccent.opacity(0.46)
            case .paused:
                coreColor = Color.cadenceMutedRose.opacity(0.40)
            case .completed:
                coreColor = Color.cadenceSuccess.opacity(0.50)
            case .idle:
                coreColor = Color.cadenceDeepBurgundy.opacity(0.38)
        }

        // Center ascends as progress increases from bottom towards center
        let coreY = cy + CGFloat(1.0 - clampedProgress) * radius * 0.55 - radius * 0.1
        let coreCenter = CGPoint(x: cx, y: coreY)
        let coreRadius = radius * 0.95

        let coreShader = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [
                coreColor,
                coreColor.opacity(0.35),
                Color.clear,
            ]),
            center: coreCenter,
            startRadius: 2.0,
            endRadius: coreRadius
        )

        let coreRect = CGRect(
            x: cx - coreRadius,
            y: coreY - coreRadius,
            width: coreRadius * 2.0,
            height: coreRadius * 2.0
        )
        clippedContext.fill(Path(ellipseIn: coreRect), with: coreShader)
    }

    /// Pass 5: Flowing Caustic Spine (Progress Path on Path A)
    private func drawCausticSpine(
        context: GraphicsContext,
        pathA: Path,
        startPoint: CGPoint
    ) {
        if clampedProgress > 0.001 {
            let activePath = pathA.trimmedPath(from: 0.0, to: CGFloat(clampedProgress))

            let arcColor: Color
            let glowColor: Color
            switch phase {
                case .running:
                    arcColor = Color.cadenceAccent
                    glowColor = Color.cadenceAccentHighlight.opacity(0.35)
                case .paused:
                    arcColor = Color.cadenceMutedRose
                    glowColor = Color.cadenceMutedRose.opacity(0.30)
                case .completed:
                    arcColor = Color.cadenceSuccess
                    glowColor = Color.cadenceSuccess.opacity(0.35)
                case .idle:
                    arcColor = Color.cadenceBorder
                    glowColor = Color.clear
            }

            // 6pt soft bloom
            if glowColor != .clear {
                context.stroke(
                    activePath,
                    with: .color(glowColor),
                    style: StrokeStyle(lineWidth: 6.0, lineCap: .round)
                )
            }

            // 3.5pt crisp stroke
            context.stroke(
                activePath,
                with: .color(arcColor),
                style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
            )
        } else {
            // At 0%, a subtle rim indicator guides the eye
            let pipGlowRect = CGRect(
                x: startPoint.x - 4.5,
                y: startPoint.y - 4.5,
                width: 9.0,
                height: 9.0
            )
            let pipRect = CGRect(
                x: startPoint.x - 2.5,
                y: startPoint.y - 2.5,
                width: 5.0,
                height: 5.0
            )
            context.fill(
                Path(ellipseIn: pipGlowRect),
                with: .color(Color.cadenceAccentHighlight.opacity(0.20))
            )
            context.fill(
                Path(ellipseIn: pipRect),
                with: .color(Color.cadenceBorder.opacity(0.80))
            )
        }
    }

    /// Pass 6: Specular Meniscus Glint
    private func drawSpecularGlint(
        context: GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat
    ) {
        // Curve along upper crest of Path A simulating darkroom illumination
        let steps = 24
        let startAngle = -Double.pi * 0.75
        let endAngle = -Double.pi * 0.25
        var glintPoints: [CGPoint] = []
        glintPoints.reserveCapacity(steps)

        let glintBaseRadius = radius * 0.92

        for j in 0..<steps {
            let theta = startAngle + (Double(j) / Double(steps - 1)) * (endAngle - startAngle)
            let r = self.radius(
                for: theta,
                baseRadius: glintBaseRadius,
                phaseOffset: 0.0,
                time: timestamp
            )
            glintPoints.append(CGPoint(x: cx + r * cos(theta), y: cy + r * sin(theta)))
        }

        guard glintPoints.count >= 2 else { return }
        var glintPath = Path()
        glintPath.move(to: glintPoints[0])
        for pt in glintPoints.dropFirst() {
            glintPath.addLine(to: pt)
        }

        let glintShader = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: .clear, location: 0.0),
                .init(color: Color.cadenceTextPrimary.opacity(0.28), location: 0.5),
                .init(color: .clear, location: 1.0),
            ]),
            startPoint: CGPoint(x: cx - radius * 0.6, y: cy - radius),
            endPoint: CGPoint(x: cx + radius * 0.6, y: cy - radius)
        )

        context.stroke(
            glintPath,
            with: glintShader,
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
        )
    }
}
