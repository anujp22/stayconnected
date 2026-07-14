import SwiftUI

// MARK: - Card Surface

/// The standard content-card background: a filled rounded rectangle with the
/// hairline divider stroke. This exact pattern was hand-rolled ~9 times across
/// the app; this modifier is the single source of truth.
///
/// The default radius matches the previous card values so existing views can
/// adopt it with no visual change. Pass a radius to preserve a screen's
/// specific corner (e.g. the search field used 16).
private struct CardSurface: ViewModifier {
    var radius: CGFloat
    var strokeOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Theme.Palette.divider.opacity(strokeOpacity), lineWidth: 1)
            )
    }
}

/// The Home hero container — the brand gradient wash plus a soft shadow. The
/// gradient is intentionally gentle so it reads as warmth, not chrome.
private struct HeroSurface: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Palette.card,
                                Theme.Palette.brand.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Theme.Palette.divider.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

extension View {
    /// Applies the standard card background + hairline stroke.
    func cardSurface(
        radius: CGFloat = Theme.Radius.card,
        strokeOpacity: Double = 0.85
    ) -> some View {
        modifier(CardSurface(radius: radius, strokeOpacity: strokeOpacity))
    }

    /// Applies the Home hero's gradient background, stroke, and soft shadow.
    func heroSurface(radius: CGFloat = Theme.Radius.hero) -> some View {
        modifier(HeroSurface(radius: radius))
    }
}

// MARK: - Chip

/// A small pill tag — used for status ("Connected"/"New") and cadence labels.
/// One component so every tag in the app shares padding, weight, and shape.
struct Chip: View {
    let text: String
    var tint: Color = Theme.Palette.brand
    /// Background wash opacity behind the tint-colored text.
    var fillOpacity: Double = 0.14

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(tint.opacity(fillOpacity))
            )
            .foregroundStyle(tint)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Space.md) {
        Text("Card surface")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .cardSurface()

        Text("Hero surface")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .heroSurface()

        HStack {
            Chip(text: "New")
            Chip(text: "Connected", tint: Theme.Palette.success, fillOpacity: 0.16)
            Chip(text: "Regular")
        }
    }
    .padding()
    .background(Theme.Palette.background)
}
