import SwiftUI

struct ContactRowCard: View {
    // MARK: - Properties

    let name: String
    let subtitle: String
    let phone: String?
    let isPinned: Bool

    var onTap: () -> Void = {}

    // MARK: - View

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color("BrandPrimary").opacity(0.16))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color("BrandPrimary"))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(Color("TextPrimary"))

                        if isPinned {
                            Image(systemName: "star.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AccentSand").opacity(0.9))
                        }
                    }

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color("TextSecondary"))

                    if let phone, !phone.isEmpty {
                        Text(phone)
                            .font(.footnote)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary").opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color("Card"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color("Divider").opacity(0.85), lineWidth: 1)
            )
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
