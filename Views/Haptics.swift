import UIKit

/// The app's single source of haptic feedback, so the same gesture always feels
/// the same everywhere. Three intents, matching how the app uses them:
///
/// - `light`  — navigation and selection taps (tab switch, opening a sheet,
///   tapping an action button).
/// - `success` — a meaningful completion (logging a connection, saving settings).
/// - `selection` — moving through discrete options (steppers, pickers).
///
/// Centralizing this replaced three near-identical private helpers that had
/// drifted across HomeView, PoolView, and SettingsView.
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
