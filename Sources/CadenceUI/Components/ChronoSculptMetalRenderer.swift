import AppKit
import CadenceCore
import Metal
import MetalKit
import SwiftUI

// MARK: - Internal Shader Uniforms

struct ChronoSculptUniforms {
    var time: Float
    var progress: Float
    var phaseIndex: Float  // 0=idle, 1=running, 2=paused, 3=completed
    var reduceMotion: Float
    var resolution: SIMD2<Float>
}

// MARK: - Metal Pipeline Singleton

@MainActor
final class ChronoSculptMetalPipeline {
    static let shared = ChronoSculptMetalPipeline()

    let device: (any MTLDevice)?
    let pipelineState: (any MTLRenderPipelineState)?
    let commandQueue: (any MTLCommandQueue)?

    private init() {
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            self.device = nil
            self.pipelineState = nil
            self.commandQueue = nil
            return
        }

        self.device = defaultDevice
        self.commandQueue = defaultDevice.makeCommandQueue()

        let shaderSource = Self.metalShaderSource

        do {
            let library = try defaultDevice.makeLibrary(source: shaderSource, options: nil)
            let pipelineDesc = MTLRenderPipelineDescriptor()
            pipelineDesc.vertexFunction = library.makeFunction(name: "sculptVertex")
            pipelineDesc.fragmentFunction = library.makeFunction(name: "sculptFragment")
            pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDesc.colorAttachments[0].isBlendingEnabled = false

            self.pipelineState = try defaultDevice.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            self.pipelineState = nil
        }
    }

    private static let metalShaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct Uniforms {
            float time;
            float progress;
            float phaseIndex;
            float reduceMotion;
            float2 resolution;
        };

        struct VertexOut {
            float4 position [[position]];
            float2 uv;
        };

        // Full screen triangle generating normalized coordinates [-1, 1]
        vertex VertexOut sculptVertex(uint vertexID [[vertex_id]]) {
            float2 pos[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };
            float2 uv[3]  = { float2(0.0, 1.0),   float2(2.0, 1.0),  float2(0.0, -1.0) };
            VertexOut out;
            out.position = float4(pos[vertexID], 0.0, 1.0);
            out.uv = uv[vertexID];
            return out;
        }

        // Polynomial smooth minimum for organic molten fluid fusion
        float smin(float a, float b, float k) {
            float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
            return mix(b, a, h) - k * h * (1.0 - h);
        }

        // 3D rotations
        float3 rotX(float3 p, float a) {
            float c = cos(a), s = sin(a);
            return float3(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
        }
        float3 rotY(float3 p, float a) {
            float c = cos(a), s = sin(a);
            return float3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
        }
        float3 rotZ(float3 p, float a) {
            float c = cos(a), s = sin(a);
            return float3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
        }

        // Master 3D Organic Generative Sculpture (Signed Distance Field)
        float mapSculpture(float3 p, constant Uniforms &u) {
            float t = (u.reduceMotion > 0.5) ? 0.0 : u.time;
            float speed = (u.phaseIndex == 1.0) ? 0.55 : ((u.phaseIndex == 2.0) ? 0.0 : 0.22);

            // Dynamic sculptural pose: elegant asymmetric posture suspended in dark space
            float3 q = rotZ(p, 0.16 + 0.02 * sin(t * speed * 0.5));
            q = rotY(q, -0.25 + 0.02 * cos(t * speed * 0.4));
            q = rotX(q, 0.14);

            // Multi-octave harmonic fluid deformation
            float h1 = 0.038 * sin(2.2 * q.x + 1.5 * q.y + t * speed);
            float h2 = 0.026 * cos(2.6 * q.y - 1.8 * q.z - t * speed * 0.7);
            float ripple = h1 + h2 + 0.018 * sin(t * speed * 1.2);

            // --- 1. SUBSTANTIAL CENTRAL BODY (Solid Obsidian Core) ---
            float3 pCore = q;
            pCore.y += 0.02;
            float taper = 1.0 - 0.20 * pCore.y;
            float3 scaledCore = pCore / float3(0.60, 0.76, 0.50);
            float rCore = length(scaledCore / taper);
            float3 dir = normalize(scaledCore);
            float surfMod = 0.06 * (dir.x * dir.y) - 0.04 * (dir.z * dir.z);
            float dCore = (rCore - (0.52 + surfMod + ripple * 0.45)) * taper * 0.50;

            // --- 2. FRONT FLOWING TRANSLUCENT MEMBRANE (Layer 1 - Forefront) ---
            float3 pMem1 = q - float3(-0.07, -0.01, 0.15);
            pMem1 = rotZ(pMem1, 0.40 + 0.04 * sin(t * speed * 0.8));
            pMem1 = rotX(pMem1, -0.26);
            float ang1 = atan2(pMem1.y, pMem1.x);
            float bound1 = 0.80 + 0.22 * sin(2.0 * ang1 - 0.4) + 0.09 * cos(3.0 * ang1);
            float r1 = length(pMem1.xy);
            float zSurf1 = 0.17 * sin(2.0 * pMem1.x) - 0.11 * (pMem1.y * pMem1.y);
            float th1 = 0.028 + 0.016 * clamp(1.0 - (r1 / bound1), 0.0, 1.0);
            float2 w1 = float2(r1 - bound1, abs(pMem1.z - zSurf1) - th1);
            float dMembrane1 = length(max(w1, float2(0.0))) + min(max(w1.x, w1.y), 0.0) - 0.022;

            // --- 3. REAR OVERLAPPING TRANSLUCENT CREST (Layer 3 - Rearward Wing) ---
            float3 pMem2 = q - float3(0.11, 0.15, -0.11);
            pMem2 = rotY(pMem2, 0.58 - 0.03 * cos(t * speed * 0.7));
            pMem2 = rotZ(pMem2, -0.45);
            float ang2 = atan2(pMem2.y, pMem2.x);
            float bound2 = 0.78 + 0.20 * cos(2.0 * ang2 + 0.5) - 0.07 * sin(3.0 * ang2);
            float r2 = length(pMem2.xy);
            float zSurf2 = 0.15 * cos(2.0 * pMem2.y) + 0.09 * pMem2.x;
            float th2 = 0.026 + 0.014 * clamp(1.0 - (r2 / bound2), 0.0, 1.0);
            float2 w2 = float2(r2 - bound2, abs(pMem2.z - zSurf2) - th2);
            float dMembrane2 = length(max(w2, float2(0.0))) + min(max(w2.x, w2.y), 0.0) - 0.022;

            // --- 4. LOWER-RIGHT MOLTEN FLANGE ---
            float3 pMem3 = q - float3(0.16, -0.28, 0.03);
            pMem3 = rotZ(pMem3, -0.20);
            float dLobe = length(pMem3 / float3(0.42, 0.22, 0.30)) - 0.19;

            // Seamless molten glass fusion with refined organic fillets:
            // Measured blend radii preserve distinct anatomical crests and crease separation
            float d = smin(dCore, dMembrane1, 0.11);
            d = smin(d, dMembrane2, 0.10);
            d = smin(d, dLobe, 0.09);

            return d;
        }

        // Analytical normal via central differences
        float3 calcNormal(float3 p, constant Uniforms &u) {
            float eps = 0.0012;
            float d = mapSculpture(p, u);
            float3 n = float3(
                mapSculpture(p + float3(eps, 0, 0), u) - d,
                mapSculpture(p + float3(0, eps, 0), u) - d,
                mapSculpture(p + float3(0, 0, eps), u) - d
            );
            return normalize(n);
        }

        // High-fidelity Ambient Occlusion for deep crease shadowing
        float calcAO(float3 p, float3 n, constant Uniforms &u) {
            float occ = 0.0;
            float sca = 1.0;
            for (int i = 1; i <= 5; i++) {
                float hr = 0.038 * float(i);
                float d = mapSculpture(p + n * hr, u);
                occ += (hr - d) * sca;
                sca *= 0.60;
            }
            return clamp(1.0 - 2.8 * occ, 0.0, 1.0);
        }

        fragment float4 sculptFragment(VertexOut in [[stage_in]],
                                      constant Uniforms &u [[buffer(0)]]) {
            // Centered normalized coordinates [-1, 1], aspect corrected
            float2 uv = (in.uv - 0.5) * 2.0;
            uv.y = -uv.y;

            // Camera setup: subtle perspective projection provides true volumetric curvature
            float3 ro = float3(0.0, 0.0, 2.75);
            float3 rd = normalize(float3(uv * 0.94, -1.85));

            // Studio lighting arrangement:
            // Key light: Crisp upper-left studio softbox key
            float3 keyLight = normalize(float3(-0.70, 0.80, 0.60));
            // Rim light: Razor crimson edge backlight from rear-right
            float3 rimLight = normalize(float3(0.85, -0.20, -0.50));
            // Overhead softbox fill
            float3 topSoftbox = normalize(float3(-0.15, 0.95, 0.25));

            // Blood Moon authoritative palette tokens
            float3 colorBg = float3(0.0784, 0.0392, 0.0627); // #140A10
            float3 colorDeepBurgundy = float3(0.1333, 0.0784, 0.1216); // #22141F
            float3 colorObsidian = float3(0.020, 0.008, 0.015); // Deep inky volcanic glass base
            
            // Phase accent tokens
            float3 colorAccent;
            float3 colorHighlight;
            float3 colorTranslucent;
            if (u.phaseIndex == 3.0) { // Completed (emerald)
                colorAccent = float3(0.314, 0.784, 0.471); // #50C878
                colorHighlight = float3(0.55, 0.92, 0.68);
                colorTranslucent = float3(0.10, 0.38, 0.18);
            } else if (u.phaseIndex == 2.0) { // Paused (muted rose)
                colorAccent = float3(0.784, 0.510, 0.565); // #C88290
                colorHighlight = float3(0.92, 0.70, 0.75);
                colorTranslucent = float3(0.28, 0.10, 0.15);
            } else { // Idle & Running (Blood crimson)
                colorAccent = float3(1.0, 0.3216, 0.4078); // #FF5268
                colorHighlight = float3(1.0, 0.5216, 0.5843); // #FF8595
                colorTranslucent = float3(0.52, 0.05, 0.14); // Pure rich molten ruby
            }

            float3 colorKeyLight = float3(0.98, 0.95, 0.96); // Warm studio softbox key

            // Soft grounded contact shadow on background plane
            float2 shadowCenter = uv - float2(0.05, -0.06);
            float shadowDist = length(shadowCenter);
            float contactShadow = exp(-shadowDist * shadowDist * 3.4) * 0.55;

            // Raymarching
            float t = 0.0;
            float maxDist = 4.2;
            float hitT = -1.0;

            for (int step = 0; step < 88; step++) {
                float3 p = ro + rd * t;
                float d = mapSculpture(p, u);
                if (d < 0.0008) {
                    hitT = t;
                    break;
                }
                t += d * 0.80;
                if (t > maxDist) break;
            }

            float3 finalColor;

            if (hitT > 0.0) {
                float3 p = ro + rd * hitT;
                float3 N = calcNormal(p, u);
                float3 V = -rd;

                // Ambient occlusion
                float ao = calcAO(p, N, u);
                float NdotV = max(0.0, dot(N, V));

                // Specular 1: Controlled glossy studio reflection (describes curvature)
                float3 H_key = normalize(keyLight + V);
                float NdotH_key = max(0.0, dot(N, H_key));
                float specGlossy = pow(NdotH_key, 56.0) * 0.38;

                // Specular 2: Pinpoint glassy glint (communicates polished finish)
                float specSharp = pow(NdotH_key, 220.0) * 1.30;

                // Specular 3: Crimson rim reflection (grazing from rear-right)
                float3 H_rim = normalize(rimLight + V);
                float NdotH_rim = max(0.0, dot(N, H_rim));
                float specRim = pow(NdotH_rim, 48.0) * 0.95;

                // Overhead softbox specular
                float3 H_top = normalize(topSoftbox + V);
                float specTop = pow(max(0.0, dot(N, H_top)), 32.0) * 0.18;

                // Fresnel reflectance: obsidian glass F0 ~ 0.045
                float fresnel = 0.045 + (1.0 - 0.045) * pow(1.0 - NdotV, 4.5);

                // Estimate internal glass thickness via interior ray probe along inward normal
                float probeDist = 0.10;
                float internalD = -mapSculpture(p - N * probeDist, u);
                float thickness = clamp(internalD * 7.0, 0.04, 1.0);

                // --- DIRECTIONAL TRANSMISSION OPTICS (BEER-LAMBERT) ---
                // Backlight transmission emerges where rear rim light hits the back and scatters forward toward the viewer
                float backRimScatter = pow(clamp(dot(V, -rimLight) + dot(N, -rimLight) * 0.35, 0.0, 1.0), 3.0);
                float backKeyScatter = pow(clamp(dot(V, -keyLight) + dot(N, -keyLight) * 0.25, 0.0, 1.0), 4.0);
                float transmissionThroughput = backRimScatter * 1.4 + backKeyScatter * 0.3 + 0.04;

                // Physical Beer-Lambert absorption:
                // Thick core absorbs light completely, remaining deep obsidian.
                // Thin membranes allow ruby crimson light to shine through with striking luminosity.
                float3 extinction = float3(5.5, 16.0, 12.0);
                float3 transmittance = exp(-extinction * thickness);
                float3 transmittedLight = transmittance * colorTranslucent * transmissionThroughput;

                // Base material: Deep obsidian core + backlit translucent membranes
                // Ambient term modulated by AO for rich cavity depth
                float3 baseMaterial = colorObsidian + transmittedLight;
                float3 ambientTerm = baseMaterial * (0.05 + 0.95 * ao);

                // Subtle key light wrap on polished obsidian
                float wrapKey = max(0.0, dot(N, keyLight) * 0.4 + 0.6);
                float3 diffuseTerm = colorObsidian * (wrapKey * 0.15 * ao);

                // --- RESTRAINED INTERNAL THERMAL CORE ---
                // Localized internal ember in deep core; does not wash out the front surface
                float coreY = -0.26 + u.progress * 0.40;
                float3 corePos = float3(-0.03, coreY, -0.08);
                float dToCore = length(p - corePos);
                float corePulse = (u.phaseIndex == 1.0) ? (0.65 + 0.15 * sin(u.time * 2.4)) : ((u.phaseIndex == 0.0) ? 0.28 : 0.38);
                float internalLight = exp(-dToCore * dToCore * 7.5) * corePulse * (1.0 - 0.75 * thickness);
                float3 coreGlow = colorTranslucent * internalLight * 0.85;

                // --- FLOWING CAUSTIC REFLECTION / PROGRESS SPINE (CLOCKWISE FROM 12 O'CLOCK) ---
                float clockAngle = atan2(p.x, p.y);
                if (clockAngle < 0.0) clockAngle += 2.0 * M_PI_F;
                float normAngle = clockAngle / (2.0 * M_PI_F); // [0, 1] clockwise starting at top

                // Leading tip pip glint
                float tipDist = abs(normAngle - u.progress);
                float tipGlow = exp(-tipDist * tipDist * 3200.0) * 1.8;

                // Active sweep arc along the outer crest
                float isProgressActive = (normAngle <= u.progress && u.progress > 0.005) ? 1.0 : 0.0;
                float crestGlint = smoothstep(0.024, 0.0, abs(NdotV - 0.22));
                float3 spineGlow = (colorAccent * 1.4 + colorHighlight * 0.8) * (crestGlint * isProgressActive * 1.3 + crestGlint * tipGlow);

                // Idle 12-o'clock resting pip
                if (u.progress <= 0.005) {
                    float topDist = min(normAngle, 1.0 - normAngle);
                    float idlePip = exp(-topDist * topDist * 2800.0) * crestGlint * 1.2;
                    spineGlow += colorHighlight * idlePip;
                }

                // --- ASSEMBLE ILLUMINATION ---
                float3 surfaceColor = ambientTerm + diffuseTerm + coreGlow;
                
                // Add studio specular highlights
                surfaceColor += colorKeyLight * (specGlossy + specSharp + specTop);
                surfaceColor += colorAccent * specRim;
                surfaceColor += spineGlow;

                // Fresnel reflection: glancing angles reflect the darkroom studio environment
                float3 envReflection = mix(colorDeepBurgundy * 0.30, colorKeyLight * 0.25, clamp(N.y * 0.5 + 0.5, 0.0, 1.0));
                envReflection += colorAccent * (pow(1.0 - NdotV, 3.2) * 0.55 * max(0.0, dot(N, rimLight)));
                surfaceColor += envReflection * fresnel;

                // Soft anti-aliased edge blend into darkroom canvas
                float edgeAlpha = smoothstep(0.0, 0.025, NdotV);
                float3 bgWithShadow = max(float3(0.0), colorBg - float3(contactShadow * 0.75));
                finalColor = mix(bgWithShadow, surfaceColor, edgeAlpha);

            } else {
                // Empty space: Velvet Blood Moon darkroom canvas with soft contact shadow
                float3 bgWithShadow = max(float3(0.0), colorBg - float3(contactShadow * 0.75));
                finalColor = bgWithShadow;
            }

            return float4(finalColor, 1.0);
        }
        """
}

// MARK: - Dedicated MTKView with Window Tracking

@MainActor
final class CadenceMTKView: MTKView {
    var onWindowChanged: (() -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindowChanged?()
    }
}

// MARK: - Metal View Representable

@MainActor
public struct ChronoSculptMetalView: NSViewRepresentable {
    public let progress: Double
    public let phase: TimerPhase
    public let timestamp: TimeInterval
    public let reduceMotion: Bool

    public init(
        progress: Double,
        phase: TimerPhase,
        timestamp: TimeInterval,
        reduceMotion: Bool
    ) {
        self.progress = progress
        self.phase = phase
        self.timestamp = timestamp
        self.reduceMotion = reduceMotion
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> MTKView {
        guard let device = ChronoSculptMetalPipeline.shared.device else {
            return MTKView()
        }

        let mtkView = CadenceMTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(
            red: 0.0784,
            green: 0.0392,
            blue: 0.0627,
            alpha: 1.0
        )
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.delegate = context.coordinator

        mtkView.onWindowChanged = { [weak coordinator = context.coordinator] in
            coordinator?.handleWindowChanged()
        }

        context.coordinator.setup(view: mtkView)
        context.coordinator.update(
            progress: Float(progress),
            phase: phase,
            timestamp: timestamp,
            reduceMotion: reduceMotion
        )

        return mtkView
    }

    public func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.update(
            progress: Float(progress),
            phase: phase,
            timestamp: timestamp,
            reduceMotion: reduceMotion
        )
    }

    @MainActor
    public final class Coordinator: NSObject, MTKViewDelegate {
        private var uniformBuffer: (any MTLBuffer)?
        private var currentProgress: Float = 0.0
        private var currentPhaseIndex: Float = 0.0
        private var reduceMotion: Bool = false
        private var externalTimestamp: TimeInterval = 0.0
        private var baseTime: Double = CACurrentMediaTime()
        private var pausedTime: Float = 0.0
        private var isAppActive: Bool = true
        private weak var mtkView: MTKView?

        private var lastRenderedPhase: Float = -1.0
        private var lastRenderedProgress: Float = -1.0
        private var lastRenderedReduceMotion: Bool = false
        private var hasRenderedInitialFrame: Bool = false

        private var isWindowVisible: Bool {
            guard let window = mtkView?.window else { return false }
            return window.isVisible && window.occlusionState.contains(.visible)
        }

        override init() {
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onAppDidBecomeActive),
                name: NSApplication.didBecomeActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onAppDidResignActive),
                name: NSApplication.didResignActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onWindowOcclusionChanged),
                name: NSWindow.didChangeOcclusionStateNotification,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc private func onAppDidBecomeActive() {
            handleAppActiveChanged(isActive: true)
        }

        @objc private func onAppDidResignActive() {
            handleAppActiveChanged(isActive: false)
        }

        @objc private func onWindowOcclusionChanged() {
            updatePauseState()
        }

        private func handleAppActiveChanged(isActive: Bool) {
            self.isAppActive = isActive
            updatePauseState()
        }

        func handleWindowChanged() {
            updatePauseState()
        }

        func setup(view: MTKView) {
            self.mtkView = view
            guard let device = view.device else { return }
            self.uniformBuffer = device.makeBuffer(
                length: MemoryLayout<ChronoSculptUniforms>.stride,
                options: [.storageModeShared]
            )
        }

        func update(
            progress: Float,
            phase: TimerPhase,
            timestamp: TimeInterval,
            reduceMotion: Bool
        ) {
            self.currentProgress = progress
            self.reduceMotion = reduceMotion
            self.externalTimestamp = timestamp

            let newPhaseIndex: Float
            switch phase {
                case .idle:
                    newPhaseIndex = 0.0
                case .running:
                    newPhaseIndex = 1.0
                case .paused:
                    newPhaseIndex = 2.0
                case .completed:
                    newPhaseIndex = 3.0
            }

            if self.currentPhaseIndex != 2.0 && newPhaseIndex == 2.0 {
                // Entering paused state: lock freeze timestamp
                self.pausedTime = Float(CACurrentMediaTime() - baseTime)
            }
            self.currentPhaseIndex = newPhaseIndex

            updatePauseState()
        }

        private func updatePauseState() {
            guard let mtkView else { return }

            let windowVisible = isWindowVisible
            let shouldAnimate =
                isAppActive && windowVisible && !reduceMotion && (currentPhaseIndex == 1.0)

            if shouldAnimate {
                if mtkView.isPaused {
                    mtkView.isPaused = false
                    mtkView.enableSetNeedsDisplay = false
                    mtkView.preferredFramesPerSecond = 60
                }
            } else {
                if !mtkView.isPaused {
                    mtkView.isPaused = true
                    mtkView.enableSetNeedsDisplay = false
                }

                // Render static frame when window is visible and visual state changed
                if windowVisible && mtkView.drawableSize.width > 0
                    && mtkView.drawableSize.height > 0
                {
                    let stateChanged =
                        !hasRenderedInitialFrame || (lastRenderedPhase != currentPhaseIndex)
                        || (abs(lastRenderedProgress - currentProgress) > 0.001)
                        || (lastRenderedReduceMotion != reduceMotion)

                    if stateChanged {
                        hasRenderedInitialFrame = true
                        lastRenderedPhase = currentPhaseIndex
                        lastRenderedProgress = currentProgress
                        lastRenderedReduceMotion = reduceMotion
                        mtkView.draw()
                    }
                }
            }
        }

        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            guard size.width > 0 && size.height > 0 else { return }
            let windowVisible = isWindowVisible
            let shouldAnimate =
                isAppActive && windowVisible && !reduceMotion && (currentPhaseIndex == 1.0)
            if !shouldAnimate && windowVisible {
                view.draw()
            }
        }

        public func draw(in view: MTKView) {
            guard let pipelineState = ChronoSculptMetalPipeline.shared.pipelineState,
                let commandQueue = ChronoSculptMetalPipeline.shared.commandQueue,
                let drawable = view.currentDrawable,
                let renderPassDescriptor = view.currentRenderPassDescriptor,
                let uniformBuffer
            else {
                return
            }

            let timeVal: Float
            if reduceMotion {
                timeVal = 0.0
            } else if currentPhaseIndex == 2.0 {
                timeVal = pausedTime
            } else if externalTimestamp > 0.0 {
                timeVal = Float(externalTimestamp.truncatingRemainder(dividingBy: 10000.0))
            } else {
                timeVal = Float(CACurrentMediaTime() - baseTime)
            }

            var uniforms = ChronoSculptUniforms(
                time: timeVal,
                progress: currentProgress,
                phaseIndex: currentPhaseIndex,
                reduceMotion: reduceMotion ? 1.0 : 0.0,
                resolution: SIMD2<Float>(
                    Float(view.drawableSize.width), Float(view.drawableSize.height))
            )

            uniformBuffer.contents().copyMemory(
                from: &uniforms,
                byteCount: MemoryLayout<ChronoSculptUniforms>.stride
            )

            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                let encoder = commandBuffer.makeRenderCommandEncoder(
                    descriptor: renderPassDescriptor)
            else {
                return
            }

            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 0)
            encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
