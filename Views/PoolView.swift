import Contacts
import SwiftUI

struct PoolView: View {
    // MARK: - Environment

    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.openURL) private var openURL

    // MARK: - State

    @StateObject private var viewModel: PoolViewModel

    @State private var showConnectSheet = false
    @State private var selectedPerson: Person?

    @State private var resolvedPhone: String?
    @State private var connectErrorMessage: String?
    @State private var showConnectError = false

    // MARK: - Initialization

    init() {
        // Placeholder: real context comes from environment onAppear
        _viewModel = StateObject(
            wrappedValue: PoolViewModel(ctx: PersistenceController.shared.container.viewContext)
        )
    }

    // MARK: - View

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Header summary
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Contact Pool")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(Color("TextPrimary"))

                            Text("\(viewModel.people.count) active connections")
                                .font(.subheadline)
                                .foregroundStyle(Color("TextSecondary"))
                        }

                        Spacer()
                    }
                    .padding(.top, 6)

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color("TextSecondary"))

                        TextField("Search contacts", text: $viewModel.searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)

                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color("TextSecondary"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color("Card"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color("Divider").opacity(0.85), lineWidth: 1)
                    )

                    // List
                    VStack(spacing: 12) {
                        ForEach(viewModel.filteredPeople, id: \.objectID) { person in
                            ContactRowCard(
                                name: person.displayName ?? "Unknown",
                                subtitle: "Tap to connect",
                                phone: (nil as String?),
                                isPinned: person.isPinned
                            ) {
                                selectedPerson = person
                                resolvePhoneAndPresent(for: person)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    togglePinned(person)
                                } label: {
                                    Label(
                                        person.isPinned ? "Unpin" : "Pin",
                                        systemImage: person.isPinned ? "pin.slash" : "pin"
                                    )
                                }
                                .tint(Color("Primary"))

                                Button(role: .destructive) {
                                    removeFromPool(person)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }

                    // Bottom action
                    Button {
                        // TODO: Hook up your contact picker / add flow
                        print("Add Contact tapped")
                    } label: {
                        Label("Add Contact", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                    .padding(.top, 6)

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.load()
        }
        .confirmationDialog(
            "Connect with \(selectedPerson?.displayName ?? "Contact")",
            isPresented: $showConnectSheet,
            titleVisibility: .visible
        ) {
            if let phone = resolvedPhone, !phone.isEmpty {
                Button("Call") {
                    successHaptic()
                    connectVia("tel", value: phone)
                }

                Button("Message") {
                    successHaptic()
                    connectVia("sms", value: phone)
                }
            } else {
                Button("No number available", role: .destructive) { }
                    .disabled(true)
            }

            Button("Cancel", role: .cancel) { }
        }
        .alert("Can’t Connect", isPresented: $showConnectError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(connectErrorMessage ?? "Something went wrong.")
                .foregroundStyle(Color("TextSecondary"))
        }
    }

    // MARK: - Private Helpers

    private func resolvePhoneAndPresent(for person: Person) {
        resolvedPhone = nil

        guard let contactId = person.contactIdentifier, !contactId.isEmpty else {
            // No contact identifier stored -> can’t resolve phone
            showConnectSheet = true
            return
        }

        do {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [CNContactPhoneNumbersKey as CNKeyDescriptor]
            let contact = try store.unifiedContact(withIdentifier: contactId, keysToFetch: keys)

            // Pick the first phone number (you can improve this later)
            let phone = contact.phoneNumbers.first?.value.stringValue
            resolvedPhone = phone
            showConnectSheet = true
        } catch {
            resolvedPhone = nil
            connectErrorMessage = "Couldn’t load this contact’s phone number."
            showConnectError = true
        }
    }

    private func connectVia(_ scheme: String, value: String) {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let url = URL(string: "\(scheme)://\(cleaned)") else {
            connectErrorMessage = "Invalid phone number."
            showConnectError = true
            return
        }
        openURL(url)
    }

    private func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func togglePinned(_ person: Person) {
        person.isPinned.toggle()
        do {
            try ctx.save()
            viewModel.load()
        } catch {
            connectErrorMessage = "Couldn’t update pin status."
            showConnectError = true
        }
    }

    private func removeFromPool(_ person: Person) {
        person.isInPool = false
        person.isPinned = false
        do {
            try ctx.save()
            viewModel.load()
        } catch {
            connectErrorMessage = "Couldn’t remove contact from pool."
            showConnectError = true
        }
    }
}
