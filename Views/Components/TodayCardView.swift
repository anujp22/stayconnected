import SwiftUI

struct TodayCardView: View {
    let pick: TodayPick
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {

                Text("Today’s Pick")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    // Avatar placeholder (we’ll swap to contact image later)
                    Circle()
                        .fill(Color.accentColor.opacity(0.18))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color.accentColor)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pick.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(pick.lastConnectedText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let phone = pick.phoneNumber, !phone.isEmpty {
                            Text(phone)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(PressableCardStyle()) // important: keeps it card-like, not a blue button
    }
}
