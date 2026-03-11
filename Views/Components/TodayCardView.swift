import SwiftUI

struct TodayCardView: View {
    // MARK: - Properties

    let pick: TodayPick

    var onTap: () -> Void = {}

    // MARK: - View

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today’s Pick")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                HStack(spacing: 16) {
                    // Avatar placeholder (we’ll swap to contact image later)
                    Circle()
                        .fill(Color("Primary").opacity(0.16))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color("Primary"))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pick.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("TextPrimary"))

                        Text(pick.lastConnectedText)
                            .font(.subheadline)
                            .foregroundStyle(Color("TextSecondary"))

                        if let phone = pick.phoneNumber, !phone.isEmpty {
                            Text(phone)
                                .font(.footnote)
                                .foregroundStyle(Color("TextSecondary"))
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color("Primary").opacity(0.9))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color("Card"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color("Divider").opacity(0.85), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(PressableCardStyle()) // important: keeps it card-like, not a blue button
    }
}
