import SwiftUI

/// A compact circular icon button — the unified vocabulary for the Home pick
/// row's Call / Done / Snooze actions, which currently mix
/// `.borderedProminent`, `.bordered`, and `.tint(...)` in ways that read as
/// three unrelated buttons.
///
/// Two visual weights:
/// - `.filled`: solid tinted background, white glyph (the primary action).
/// - `.tinted`: soft tint wash, tinted glyph (secondary actions).
///
/// Adopted by the Home rows in a later phase; defined here in Phase 0 so the
/// component exists alongside the rest of the design system.
struct CircularIconButtonStyle: ButtonStyle {
    enum Weight {
        case filled
        case tinted
    }

    var tint: Color
    var weight: Weight = .tinted
    var diameter: CGFloat = 40

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(weight == .filled ? Color.white : tint)
            .frame(width: diameter, height: diameter)
            .background(
                Circle().fill(weight == .filled ? tint : tint.opacity(0.14))
            )
            .overlay(
                Circle().stroke(
                    weight == .filled ? Color.clear : tint.opacity(0.22),
                    lineWidth: 1
                )
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: Theme.Space.md) {
        Button {
        } label: {
            Image(systemName: "phone.fill")
        }
        .buttonStyle(CircularIconButtonStyle(tint: Theme.Palette.success, weight: .filled))

        Button {
        } label: {
            Image(systemName: "checkmark")
        }
        .buttonStyle(CircularIconButtonStyle(tint: Theme.Palette.brand))

        Button {
        } label: {
            Image(systemName: "moon.zzz")
        }
        .buttonStyle(CircularIconButtonStyle(tint: Theme.Palette.textSecondary))
    }
    .padding()
    .background(Theme.Palette.background)
}
