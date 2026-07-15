import SwiftUI

struct ContactRowCard: View {
    // MARK: - Properties

    let name: String
    let subtitle: String
    let phone: String?
    let isPinned: Bool
    var contactIdentifier: String = ""
    var cadenceLabel: String? = nil

    var onTap: () -> Void = {}

    // MARK: - View

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ContactAvatarInlineView(
                    contactIdentifier: contactIdentifier,
                    displayName: name
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(Theme.Palette.textPrimary)

                        if isPinned {
                            Image(systemName: "star.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.Palette.accentWarm)
                        }

                        if let cadenceLabel {
                            Chip(text: cadenceLabel, fillOpacity: 0.12)
                        }
                    }

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.textSecondary)

                    if let phone, !phone.isEmpty {
                        Text(phone)
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textSecondary.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .cardSurface(radius: 18)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(phoneAccessibilityLabel)
        .accessibilityHint("Opens actions for this contact.")
    }

    private var phoneAccessibilityLabel: String {
        if let phone, !phone.isEmpty {
            return "\(name). \(subtitle). \(phone)."
        }

        return "\(name). \(subtitle)."
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        ContactRowCard(
            name: "Sarah",
            subtitle: "Last: 2 days ago",
            phone: "+1 502-000-1111",
            isPinned: true
        )

        ContactRowCard(
            name: "Mike",
            subtitle: "Tap to connect",
            phone: nil,
            isPinned: false
        )
    }
    .padding()
}
