import SwiftUI

/// A small streak indicator for the Home header — a warm flame plus the current
/// day count.
///
/// Calm by design: when the streak is zero it renders nothing at all, so a
/// broken or brand-new streak never turns into a guilt badge. It only shows up
/// to celebrate momentum that already exists.
struct StreakFlame: View {
    let streak: Int

    var body: some View {
        if streak > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.Palette.accentWarm)

                Text("\(streak)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Theme.Palette.accentWarm.opacity(0.16))
            )
            .overlay(
                Capsule().stroke(Theme.Palette.accentWarm.opacity(0.35), lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(streak) day streak")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StreakFlame(streak: 0) // renders nothing
        StreakFlame(streak: 1)
        StreakFlame(streak: 14)
    }
    .padding()
    .background(Theme.Palette.background)
}
