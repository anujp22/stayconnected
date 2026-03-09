//
//  ContactAvatarView.swift
//  StayConnected
//
//  Created by Anuj Patel on 1/25/26.
//

import Contacts
import SwiftUI

struct ContactAvatarView: View {
    // MARK: - Properties

    let contactIdentifier: String

    @State private var image: UIImage?

    // MARK: - View

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ZStack {
                    Circle()
                        .fill(Color("Primary").opacity(0.14))

                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .foregroundStyle(Color("Primary"))
                }
            }
        }
        .scaledToFill()
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color("Divider").opacity(0.8), lineWidth: 1)
        )
        .task {
            await loadImage()
        }
    }

    // MARK: - Private Helpers

    private func loadImage() async {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]

        let predicate = CNContact.predicateForContacts(withIdentifiers: [contactIdentifier])

        if
            let contact = try? store
                .unifiedContacts(matching: predicate, keysToFetch: keys)
                .first,
            let data = contact.thumbnailImageData,
            let uiImage = UIImage(data: data)
        {
            image = uiImage
        }
    }
}
