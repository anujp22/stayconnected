import Contacts
import ContactsUI
import CoreData
import SwiftUI
import UIKit

struct PoolView: View {
    // MARK: - Environment

    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.openURL) private var openURL

    // MARK: - State

    @StateObject private var viewModel: PoolViewModel

    @State private var showConnectSheet = false
    @State private var selectedPerson: Person?
    @State private var showContactPicker = false
    @State private var showContactsPermissionAlert = false

    @State private var resolvedPhone: String?
    @State private var connectErrorMessage: String?
    @State private var showConnectError = false
    @State private var addContactErrorMessage: String?
    @State private var showAddContactError = false

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
            List {
                Section {
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
                                .accessibilityLabel("Search contacts")
                                .accessibilityHint("Filter your pool by name.")

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
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color("Background"))
                }

                Section {
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
                        .contentShape(Rectangle())
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color("Background"))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                removeFromPool(person)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                            .tint(.red)

                            Button {
                                togglePinned(person)
                            } label: {
                                Label(
                                    person.isPinned ? "Unpin" : "Pin",
                                    systemImage: person.isPinned ? "pin.slash" : "pin"
                                )
                            }
                            .tint(Color("BrandPrimary"))
                        }
                        .contextMenu {
                            Button {
                                togglePinned(person)
                            } label: {
                                Label(
                                    person.isPinned ? "Unpin" : "Pin",
                                    systemImage: person.isPinned ? "pin.slash" : "pin"
                                )
                            }

                            Button(role: .destructive) {
                                removeFromPool(person)
                            } label: {
                                Label("Remove from Pool", systemImage: "trash")
                            }
                        }
                    }
                }

                Section {
                    Button {
                        handleAddContactTap()
                    } label: {
                        Label("Add Contact", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                    .accessibilityHint("Opens the contact picker so you can add people to your pool.")
                    .padding(.top, 6)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color("Background"))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color("Background").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: ctx)) { _ in
            DispatchQueue.main.async {
                viewModel.load()
            }
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
        .sheet(isPresented: $showContactPicker) {
            MultiContactPickerSheet { contacts in
                addContactsToPool(contacts)
            }
        }
        .alert("Can’t Connect", isPresented: $showConnectError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(connectErrorMessage ?? "Something went wrong.")
                .foregroundStyle(Color("TextSecondary"))
        }
        .alert("Can’t Add Contact", isPresented: $showAddContactError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(addContactErrorMessage ?? "Something went wrong while adding this contact.")
                .foregroundStyle(Color("TextSecondary"))
        }
        .alert("Contacts Access Needed", isPresented: $showContactsPermissionAlert) {
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please allow Contacts access in Settings to add people to your pool.")
                .foregroundStyle(Color("TextSecondary"))
        }
    }

    // MARK: - Private Helpers

    private func handleAddContactTap() {
        addContactErrorMessage = nil
        showAddContactError = false

        let store = CNContactStore()
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .authorized, .limited:
            showContactPicker = true

        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        showContactPicker = true
                    } else {
                        showContactsPermissionAlert = true
                    }
                }
            }

        case .denied, .restricted:
            showContactsPermissionAlert = true

        @unknown default:
            showContactsPermissionAlert = true
        }
    }

    private func addContactsToPool(_ contacts: [CNContact]) {
        guard !contacts.isEmpty else {
            showContactPicker = false
            return
        }

        do {
            for contact in contacts {
                let request: NSFetchRequest<Person> = Person.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "contactIdentifier == %@", contact.identifier)

                let existingPerson = try ctx.fetch(request).first
                let person = existingPerson ?? Person(context: ctx)

                if person.id == nil {
                    person.id = UUID()
                }

                let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                    ?? [contact.givenName, contact.familyName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")

                person.contactIdentifier = contact.identifier
                person.displayName = fullName.isEmpty ? "Unknown Contact" : fullName
                person.isInPool = true

                if existingPerson == nil {
                    person.isPinned = false
                }
            }

            if ctx.hasChanges {
                try ctx.save()
            }

            ctx.refreshAllObjects()
            showContactPicker = false
            addContactErrorMessage = nil
            showAddContactError = false

            DispatchQueue.main.async {
                viewModel.load()
            }

            successHaptic()
        } catch {
            print("❌ addContactsToPool failed: \(error)")
            addContactErrorMessage = error.localizedDescription

            if ctx.hasChanges {
                ctx.rollback()
            }

            showAddContactError = true
        }
    }

    private func addContactToPool(_ contact: CNContact) {
        addContactsToPool([contact])
    }

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

    // MARK: - Actions

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
            if ctx.hasChanges {
                try ctx.save()
            }

            ctx.refreshAllObjects()

            DispatchQueue.main.async {
                viewModel.load()
                selectedPerson = nil
                resolvedPhone = nil
            }

            successHaptic()
        } catch {
            if ctx.hasChanges {
                ctx.rollback()
            }

            connectErrorMessage = "Couldn’t remove contact from pool."
            showConnectError = true
        }
    }
}


private struct MultiContactPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: ([CNContact]) -> Void

    @State private var contacts: [CNContact] = []
    @State private var selectedIdentifiers: Set<String> = []
    @State private var searchText = ""

    private var filteredContacts: [CNContact] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return contacts }

        return contacts.filter { contact in
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                ?? [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")

            return fullName.localizedCaseInsensitiveContains(trimmed)
                || contact.phoneNumbers.contains { $0.value.stringValue.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredContacts, id: \.identifier) { contact in
                    Button {
                        toggleSelection(for: contact)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedIdentifiers.contains(contact.identifier) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selectedIdentifiers.contains(contact.identifier) ? Color("BrandPrimary") : Color("TextSecondary"))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayName(for: contact))
                                    .foregroundStyle(Color("TextPrimary"))

                                if let phone = contact.phoneNumbers.first?.value.stringValue, !phone.isEmpty {
                                    Text(phone)
                                        .font(.footnote)
                                        .foregroundStyle(Color("TextSecondary"))
                                }
                            }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color("Card"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("Background").ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search contacts")
            .navigationTitle("Select Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(selectedIdentifiers.isEmpty ? "Add" : "Add (\(selectedIdentifiers.count))") {
                        let selectedContacts = contacts.filter { selectedIdentifiers.contains($0.identifier) }
                        onAdd(selectedContacts)
                        dismiss()
                    }
                    .disabled(selectedIdentifiers.isEmpty)
                }
            }
            .task {
                loadContacts()
            }
        }
    }

    private func toggleSelection(for contact: CNContact) {
        if selectedIdentifiers.contains(contact.identifier) {
            selectedIdentifiers.remove(contact.identifier)
        } else {
            selectedIdentifiers.insert(contact.identifier)
        }
    }

    private func displayName(for contact: CNContact) -> String {
        let fullName = CNContactFormatter.string(from: contact, style: .fullName)
            ?? [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

        return fullName.isEmpty ? "Unknown Contact" : fullName
    }

    private func loadContacts() {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]

        var fetchedContacts: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                fetchedContacts.append(contact)
            }

            contacts = fetchedContacts
        } catch {
            contacts = []
        }
    }
}

