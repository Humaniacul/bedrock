import SwiftUI
import UIKit

/// Runs the floating digit window for S13.4B (the real run) and S13.5A (the
/// check): Picture in Picture over Settings when it's available and switched on
/// remotely, otherwise app switching, and in preview mode (B9) the window plays
/// inside Bedrock with nothing to type into.
@MainActor
@Observable
final class BlindEntryRunner {
    enum Phase: Equatable {
        /// “Open Settings” is waiting.
        case ready
        /// Asked PiP to start; Settings opens once it's up.
        case starting
        /// In Settings.
        case away
        /// The window has shown every digit and the person is back.
        case finished
    }

    enum Style: Equatable { case pictureInPicture, appSwitching, inApp }

    private(set) var session: BlindEntrySession
    private(set) var style: Style
    private(set) var phase: Phase = .ready
    @ObservationIgnored private(set) var pictureInPicture: DigitPictureInPicture?
    @ObservationIgnored var onPaused: ((PauseReason) -> Void)?

    init(code: String, slow: Bool, passes: Int, preview: Bool) {
        let pip = !preview && RemoteConfig.blindEntryUsesPictureInPicture && DigitPictureInPicture.isSupported
        let style: Style = preview ? .inApp : (pip ? .pictureInPicture : .appSwitching)
        self.style = style
        session = BlindEntrySession(code: code, slow: slow, passes: passes,
                                    pausesBetweenDigits: style == .appSwitching)
        if pip { setUpPictureInPicture() }
    }

    /// The window as drawn in Bedrock and into the PiP frames.
    var face: DigitWindowFace { DigitWindowFace(state: session.state, progress: session.progress) }

    /// The digits show inside Bedrock (app switching, preview) rather than over Settings.
    var showsInBedrock: Bool { style != .pictureInPicture }

    // MARK: Actions

    /// “Open Settings” / “Show the digits”.
    func open() {
        switch style {
        case .inApp, .appSwitching:
            session.reset()
            session.start()
        case .pictureInPicture:
            guard let pip = pictureInPicture else { fallBack(); return }
            session.reset()
            phase = .starting
            pip.render { [weak self] in
                self?.face ?? DigitWindowFace(state: .tapToStart, progress: 0)
            }
            pip.start()
        }
    }

    /// App switching: after each digit.
    func switchToSettings() {
        openSettings()
    }

    /// The app is active again. Returns true when the run is complete.
    @discardableResult
    func returned() -> Bool {
        guard phase == .away else { return phase == .finished }
        switch style {
        case .pictureInPicture:
            pictureInPicture?.stop()
            if session.isDone {
                phase = .finished
                return true
            }
            // Back halfway: the same code, from digit 1.
            if session.hasStarted { onPaused?(.leftSettings) }
            session.reset()
            phase = .ready
            return false
        case .appSwitching:
            phase = .ready
            session.resume()
            return false
        case .inApp:
            return session.isDone
        }
    }

    /// App switching and preview finish inside Bedrock.
    func markFinished() {
        phase = .finished
    }

    func tearDown() {
        session.stop()
        pictureInPicture?.stop()
    }

    // MARK: Internals

    private func setUpPictureInPicture() {
        let pip = DigitPictureInPicture()
        pip.onPlay = { [weak self] in self?.session.start() }
        pip.onStart = { [weak self] in self?.openSettings() }
        pip.onFailure = { [weak self] in self?.fallBack() }
        pictureInPicture = pip
    }

    /// PiP couldn't start: switch apps instead, starting with the first digit here.
    private func fallBack() {
        pictureInPicture?.stop()
        pictureInPicture = nil
        session.stop()
        session = BlindEntrySession(code: String(session.code),
                                    slow: session.perDigit > BedrockTiming.digitDuration,
                                    passes: session.passes, pausesBetweenDigits: true)
        style = .appSwitching
        phase = .ready
    }

    private func openSettings() {
        phase = .away
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
