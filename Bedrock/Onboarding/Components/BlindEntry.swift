import AVFoundation
import AVKit
import Synchronization
import SwiftUI
import UIKit

// Blind entry (SPEC.md S13.3B–S13.5A, COMPONENTS.md › FloatingDigitWindow).
// The person types a code they never see whole: one digit at a time in a small
// window over Settings, then all four again to confirm.
//
// Two ways to show the window (OPEN_QUESTIONS #2):
//   A · Picture in Picture: the window floats over Settings (default).
//   B · App switching: each digit shows in Bedrock for 3 seconds, then
//       “Switch to Settings”. Used when PiP isn't available, fails to start, or
//       is switched off remotely.

/// What the window is showing.
enum DigitWindowState: Equatable {
    case tapToStart
    /// `index` 0–3 within the four digits; `confirming` = the “Again” pass.
    case digit(Character, index: Int, confirming: Bool)
    /// App switching: this digit has been shown; type it in Settings, then come back.
    case between
    case pausedForRecording
    case done
}

/// One run through the code: 4 digits, then the same 4 again (`passes: 2`; the
/// S13.5A check is one pass). Each digit holds for `perDigit` seconds (3s, or 5s
/// in slow mode). Pauses while the screen is recorded or mirrored. With
/// `pausesBetweenDigits` (the app-switching fallback) it waits after each digit
/// until `resume()`. The code itself is never stored here beyond the run.
@MainActor
@Observable
final class BlindEntrySession {
    let code: [Character]
    let perDigit: Double
    let passes: Int
    let pausesBetweenDigits: Bool
    private(set) var state: DigitWindowState = .tapToStart
    /// 0 → 1 across the current digit (the ring sweep).
    private(set) var progress: Double = 0
    private(set) var step = 0
    @ObservationIgnored var onStep: ((WindowStep) -> Void)?

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var resumed = false
    @ObservationIgnored private var captureObserver: NSObjectProtocol?

    init(code: String, slow: Bool, passes: Int = 2, pausesBetweenDigits: Bool = false) {
        self.code = Array(code)
        self.passes = passes
        self.pausesBetweenDigits = pausesBetweenDigits
        perDigit = slow ? BedrockTiming.digitDurationSlow : BedrockTiming.digitDuration
        captureObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleCapture() }
        }
    }

    var isRunning: Bool { task != nil }
    var hasStarted: Bool { state != .tapToStart }
    var isDone: Bool { state == .done }

    func start() {
        guard task == nil, state != .done else { return }
        onStep?(.started)
        task = Task { [weak self] in await self?.run() }
    }

    /// App switching: the person came back from Settings; show the next digit.
    func resume() {
        resumed = true
    }

    /// Back to “Tap to start”, from digit 1 (leaving Settings halfway).
    func reset() {
        task?.cancel()
        task = nil
        step = 0
        progress = 0
        resumed = false
        state = .tapToStart
    }

    func stop() {
        task?.cancel()
        task = nil
        if let captureObserver { NotificationCenter.default.removeObserver(captureObserver) }
        captureObserver = nil
    }

    private func run() async {
        while step < code.count * passes {
            if Self.isCaptured {
                state = .pausedForRecording
                try? await Task.sleep(for: .milliseconds(300))
                if Task.isCancelled { return }
                continue
            }
            let index = step % code.count
            let confirming = step >= code.count
            state = .digit(code[index], index: index, confirming: confirming)
            onStep?(Self.windowStep(index: index, confirming: confirming))
            if UIAccessibility.isVoiceOverRunning {
                AccessibilityNotification.Announcement(Self.spoken(code[index], index: index, confirming: confirming)).post()
            }
            let started = Date.now
            while true {
                let elapsed = Date.now.timeIntervalSince(started)
                progress = min(elapsed / perDigit, 1)
                if elapsed >= perDigit { break }
                if Self.isCaptured { break }
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled { return }
            }
            if Self.isCaptured { continue } // show this digit again once recording stops
            step += 1
            if pausesBetweenDigits {
                state = .between
                resumed = false
                while !resumed {
                    try? await Task.sleep(for: .milliseconds(100))
                    if Task.isCancelled { return }
                }
            }
        }
        state = .done
        onStep?(.finished)
        task = nil
    }

    private func handleCapture() {
        if Self.isCaptured, case .digit = state { state = .pausedForRecording }
    }

    /// Screen recording or mirroring is on (SPEC.md S13.4B).
    static var isCaptured: Bool {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .contains { $0.traitCollection.sceneCaptureState == .active }
    }

    private static func windowStep(index: Int, confirming: Bool) -> WindowStep {
        switch (index, confirming) {
        case (0, false): .digit1
        case (1, false): .digit2
        case (2, false): .digit3
        case (3, false): .digit4
        case (0, true): .confirm1
        case (1, true): .confirm2
        case (2, true): .confirm3
        default: .confirm4
        }
    }

    /// “Type 7. 2 of 4.” — the window's parts read as sentences, not dots.
    static func spoken(_ digit: Character, index: Int, confirming: Bool, practice: Bool = false) -> String {
        let window = OnbCopy.parts(practice ? "onb.s13_3b.window" : "onb.s13_4b.window")
        let confirm = OnbCopy.parts(practice ? "onb.s13_3b.confirm_phase" : "onb.s13_4b.window_confirm")
        let lead = (confirming ? confirm : window).first ?? ""
        let position = (window.count > 2 ? window[2] : "").replacingOccurrences(of: "{n}", with: "\(index + 1)")
        return "\(lead) \(digit). \(position)."
    }
}

// MARK: - The window's face

/// The floating window: one large digit with a ring sweeping its duration.
/// Rendered as a SwiftUI view in Bedrock (practice, fallback) and drawn into
/// Picture in Picture frames over Settings.
struct DigitWindowFace: View {
    let state: DigitWindowState
    let progress: Double
    var practice = false
    var reduceMotion = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(BedrockColor.bgSurface)
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(BedrockColor.lineStrong, lineWidth: 1)
            content
                .padding(Space.s4)
        }
        .frame(width: BedrockSize.digitWindow.width, height: BedrockSize.digitWindow.height)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .tapToStart:
            VStack(spacing: Space.s2) {
                StoneMark()
                    .fill(BedrockColor.emberGlow)
                    .frame(width: BedrockSize.holdGlyph.width, height: BedrockSize.holdGlyph.height)
                Text(OnbCopy.string("onb.s13_4b.window_start"))
                    .font(BedrockFont.headline)
                    .foregroundStyle(BedrockColor.inkPrimary)
            }
        case .digit(let digit, let index, let confirming):
            HStack(spacing: Space.s5) {
                ZStack {
                    Circle().stroke(BedrockColor.lineStrong, lineWidth: 3)
                    if !reduceMotion {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(BedrockColor.ember, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    Text(String(digit))
                        .font(BedrockFont.digitHero)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .monospacedDigit()
                }
                .frame(width: BedrockSize.digitRing, height: BedrockSize.digitRing)
                VStack(alignment: .leading, spacing: Space.s1) {
                    Text(label(confirming: confirming))
                        .bedrockEyebrow(color: confirming ? BedrockColor.emberGlow : BedrockColor.inkTertiary)
                    Text(position(index))
                        .font(BedrockFont.subhead)
                        .foregroundStyle(BedrockColor.inkSecondary)
                }
            }
        case .between:
            StoneMark()
                .fill(BedrockColor.stoneLight)
                .frame(width: BedrockSize.holdGlyph.width, height: BedrockSize.holdGlyph.height)
        case .pausedForRecording:
            Text(OnbCopy.string("onb.s13_4b.window_recording"))
                .font(BedrockFont.subhead.weight(.medium))
                .foregroundStyle(BedrockColor.inkPrimary)
                .multilineTextAlignment(.center)
        case .done:
            Text(OnbCopy.string("onb.s13_4b.window_end"))
                .font(BedrockFont.subhead.weight(.medium))
                .foregroundStyle(BedrockColor.inkPrimary)
                .multilineTextAlignment(.center)
        }
    }

    /// “Type · {digit} · {n} of 4” (practice: “Digit {n} of 4”).
    private var windowKey: String { practice ? "onb.s13_3b.window" : "onb.s13_4b.window" }
    private var confirmKey: String { practice ? "onb.s13_3b.confirm_phase" : "onb.s13_4b.window_confirm" }

    /// The leading word: “Type” or “Again”.
    private func label(confirming: Bool) -> String {
        OnbCopy.parts(confirming ? confirmKey : windowKey).first ?? ""
    }

    private func position(_ index: Int) -> String {
        let parts = OnbCopy.parts(windowKey)
        return (parts.count > 2 ? parts[2] : "").replacingOccurrences(of: "{n}", with: "\(index + 1)")
    }
}

// MARK: - Picture in Picture (option A)

/// Floats `DigitWindowFace` over Settings with Picture in Picture, drawing each
/// frame into a sample-buffer display layer. Requires the “Audio, AirPlay, and
/// Picture in Picture” background mode.
@MainActor
final class DigitPictureInPicture: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate, AVPictureInPictureControllerDelegate {
    let displayLayer = AVSampleBufferDisplayLayer()
    private var controller: AVPictureInPictureController?
    private var frameTask: Task<Void, Never>?
    private(set) var isActive = false
    /// Reported to PiP so its window shows a play button until the run starts.
    private let paused = Mutex(true)
    /// The PiP window's play button: “Tap to start”.
    var onPlay: (() -> Void)?
    /// PiP couldn't start (switched off, unsupported): fall back to app switching.
    var onFailure: (() -> Void)?
    var onStop: (() -> Void)?
    /// PiP is up: now Settings can open underneath it.
    var onStart: (() -> Void)?

    static var isSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }

    override init() {
        super.init()
        displayLayer.videoGravity = .resizeAspect
        let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: displayLayer, playbackDelegate: self)
        controller = AVPictureInPictureController(contentSource: source)
        controller?.delegate = self
        controller?.requiresLinearPlayback = true
    }

    /// Keep drawing `face()` while PiP is up.
    func render(_ face: @escaping @MainActor () -> DigitWindowFace) {
        frameTask?.cancel()
        frameTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.enqueue(face())
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    func start() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let controller, controller.isPictureInPicturePossible else {
            onFailure?()
            return
        }
        controller.startPictureInPicture()
    }

    func stop() {
        frameTask?.cancel()
        paused.withLock { $0 = true }
        controller?.stopPictureInPicture()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func enqueue(_ face: DigitWindowFace) {
        let renderer = ImageRenderer(content: face)
        renderer.scale = BedrockSize.digitWindowScale
        guard let image = renderer.cgImage, let buffer = Self.sampleBuffer(from: image) else { return }
        if displayLayer.sampleBufferRenderer.status == .failed { displayLayer.sampleBufferRenderer.flush() }
        displayLayer.sampleBufferRenderer.enqueue(buffer)
    }

    private static func sampleBuffer(from image: CGImage) -> CMSampleBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary
        guard CVPixelBufferCreate(kCFAllocatorDefault, image.width, image.height,
                                  kCVPixelFormatType_32BGRA, attributes, &pixelBuffer) == kCVReturnSuccess,
              let pixelBuffer else { return nil }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer), width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        var format: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer,
                                                     formatDescriptionOut: &format)
        guard let format else { return nil }
        var timing = CMSampleTimingInfo(duration: .invalid,
                                        presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                        decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer,
                                                 formatDescription: format, sampleTiming: &timing,
                                                 sampleBufferOut: &sample)
        if let sample, let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true) {
            let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(dictionary,
                                 Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                 Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        return sample
    }

    // MARK: Delegates

    /// Playing once started: the run can't be paused from the PiP window, only left.
    func markPlaying() {
        paused.withLock { $0 = false }
        controller?.invalidatePlaybackState()
    }

    nonisolated func pictureInPictureController(_ controller: AVPictureInPictureController, setPlaying playing: Bool) {
        guard playing else { return }
        Task { @MainActor in
            self.markPlaying()
            self.onPlay?()
        }
    }

    nonisolated func pictureInPictureControllerTimeRangeForPlayback(_ controller: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    nonisolated func pictureInPictureControllerIsPlaybackPaused(_ controller: AVPictureInPictureController) -> Bool {
        paused.withLock { $0 }
    }

    nonisolated func pictureInPictureController(_ controller: AVPictureInPictureController,
                                                didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    nonisolated func pictureInPictureController(_ controller: AVPictureInPictureController,
                                                skipByInterval skipInterval: CMTime) async {}

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in
            self.isActive = true
            self.onStart?()
        }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in
            self.isActive = false
            self.onStop?()
        }
    }

    nonisolated func pictureInPictureController(_ controller: AVPictureInPictureController,
                                                failedToStartPictureInPictureWithError error: Error) {
        Task { @MainActor in self.onFailure?() }
    }
}

/// Hosts the PiP display layer in the view tree (PiP needs its source on screen).
struct PictureInPictureHost: UIViewRepresentable {
    let pip: DigitPictureInPicture

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.addSublayer(pip.displayLayer)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        pip.displayLayer.frame = view.bounds
    }
}

// MARK: - Practice keypad (S13.3B)

/// A local, practice-only passcode pad in Bedrock's style (not an iOS copy).
struct PracticeKeypad: View {
    let onDigit: (Character) -> Void

    private let rows: [[Character?]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [nil, "0", nil]]

    var body: some View {
        VStack(spacing: Space.s3) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: Space.s5) {
                    ForEach(rows[row].indices, id: \.self) { column in
                        if let digit = rows[row][column] {
                            Button {
                                BedrockHaptics.select()
                                onDigit(digit)
                            } label: {
                                Text(String(digit))
                                    .font(BedrockFont.keypad)
                                    .foregroundStyle(BedrockColor.inkPrimary)
                                    .frame(width: BedrockSize.keypadKey, height: BedrockSize.keypadKey)
                                    .background(Circle().fill(BedrockColor.bgRaised))
                                    .overlay(Circle().strokeBorder(BedrockColor.lineStrong))
                            }
                            .buttonStyle(PressOpacityStyle())
                            .accessibilityLabel(String(digit))
                        } else {
                            Color.clear.frame(width: BedrockSize.keypadKey, height: BedrockSize.keypadKey)
                        }
                    }
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
