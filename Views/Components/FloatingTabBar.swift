import SwiftUI

/// The app's custom bottom navigation — a floating, translucent capsule that
/// replaces the stock `TabView` chrome. This is the single biggest change that
/// makes StayConnected read as a designed product rather than a template.
///
/// Mounted via `safeAreaInset` on the `TabView` in `AppShellView`, so it floats
/// above content while still reserving its own space (nothing gets covered).
struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab

    /// Drives the sliding selection highlight across items.
    @Namespace private var highlight

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                item(for: tab)
            }
        }
        .padding(.horizontal, Theme.Space.xs)
        .padding(.vertical, Theme.Space.xs)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Theme.Palette.divider.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding(.horizontal, Theme.Space.lg)
        .padding(.bottom, Theme.Space.xs)
    }

    // MARK: - Item

    private func item(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            guard selectedTab != tab else { return }
            select(tab)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(height: 22)

                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Theme.Palette.brand : Theme.Palette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Space.sm)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Theme.Palette.brand.opacity(0.14))
                        .matchedGeometryEffect(id: "tabHighlight", in: highlight)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Selection

    private func select(_ tab: AppTab) {
        Haptics.light()

        if reduceMotion {
            selectedTab = tab
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        }
    }
}

// MARK: - Preview

private struct FloatingTabBarPreview: View {
    @State private var tab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Palette.background.ignoresSafeArea()
            FloatingTabBar(selectedTab: $tab)
        }
    }
}

#Preview {
    FloatingTabBarPreview()
}
