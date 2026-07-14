import SwiftUI

/// The app-wide design tokens. Every screen should pull radii, spacing, and
/// colors from here rather than repeating magic numbers and `Color("…")`
/// string literals — so a visual change is a single-line edit, not a hunt.
///
/// Phase 0 of the UI revamp: this is the foundation. Tokens are introduced
/// with the *current* values so migrating existing views to them produces no
/// visible change; later phases tune the values in one place.
enum Theme {

    // MARK: - Corner Radii

    enum Radius {
        /// Small tags/pills like the "Connected"/"New" status chip.
        static let chip: CGFloat = 10
        /// Standard content cards (stat cards, section cards, rows).
        static let card: CGFloat = 20
        /// Primary/secondary pill buttons.
        static let pill: CGFloat = 18
        /// The larger hero container on Home.
        static let hero: CGFloat = 24
    }

    // MARK: - Spacing

    enum Space {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Palette

    /// Typed accessors for the asset-catalog colors. Prefer these over
    /// `Color("BrandPrimary")` — they give autocomplete and fail at compile
    /// time if an asset is renamed.
    enum Palette {
        static let brand = Color("BrandPrimary")
        static let deep = Color("PrimaryDeep")
        static let sand = Color("AccentSand")
        static let background = Color("Background")
        static let card = Color("Card")
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let divider = Color("Divider")
    }

    // MARK: - Signature Gradient

    /// The one brand gradient — brand cyan into deep teal, top-leading to
    /// bottom-trailing. Reserved for signature moments (Home hero, primary
    /// CTA); using it sparingly is what keeps it feeling special.
    static let brandGradient = LinearGradient(
        colors: [Palette.brand, Palette.deep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Display Typography

extension View {
    /// The editorial display treatment for large screen titles — a serif face
    /// that sets StayConnected apart from stock SwiftUI while body text stays
    /// SF for legibility.
    ///
    /// Not applied in Phase 0 (that would shift visuals); adopted per-screen in
    /// later phases.
    func displayTitle() -> some View {
        self
            .font(.system(.largeTitle, design: .serif).weight(.bold))
            .foregroundStyle(Theme.Palette.textPrimary)
    }
}
