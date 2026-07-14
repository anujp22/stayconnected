import Contacts
import SwiftUI
import UIKit

/// A circular contact avatar that loads the person's Contacts thumbnail off the
/// main thread, falling back to their initials on a soft brand tint.
///
/// Shared between Home's today rows and the Pool list so a person looks the
/// same everywhere. The Contacts fetch runs on a detached utility task, never
/// synchronously on the main thread.
struct ContactAvatarInlineView: View {
    // MARK: - Properties
    let contactIdentifier: String
    let displayName: String
    var size: CGFloat = 44

    @State private var image: UIImage?

    // MARK: - View
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(Theme.Palette.brand.opacity(0.14))
                    Text(initials(from: displayName))
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: contactIdentifier) {
            image = nil
            await loadThumbnailIfNeeded()
        }
    }

    // MARK: - Private Helpers
    private func loadThumbnailIfNeeded() async {
        guard image == nil, !contactIdentifier.isEmpty else { return }

        // Fetch and decode the thumbnail off the main thread.
        let identifier = contactIdentifier
        let loaded = await Task.detached(priority: .utility) { () -> UIImage? in
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [CNContactThumbnailImageDataKey as CNKeyDescriptor]
            let predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])

            guard
                let contact = try? store
                    .unifiedContacts(matching: predicate, keysToFetch: keys)
                    .first,
                let data = contact.thumbnailImageData
            else {
                return nil
            }

            return UIImage(data: data)
        }.value

        if let loaded {
            image = loaded
        }
    }

    private func initials(from name: String) -> String {
        let parts = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
        let result = String(parts)
        return result.isEmpty ? "?" : result.uppercased()
    }
}
