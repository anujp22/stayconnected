import Contacts
import ContactsUI
import CoreData
import os
import SwiftUI
import UIKit

struct PoolView: View {
    private static let logger = Logger(subsystem: "com.anujpatel.StayConnected", category: "Pool")

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

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: PoolViewModel(ctx: context))
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
                                    .foregroundStyle(Theme.Palette.textPrimary)

                                Text("\(viewModel.people.count) active connections")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Palette.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.top, 6)

                        // Search
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.Palette.textSecondary)

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
                                        .foregroundStyle(Theme.Palette.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .cardSurface(radius: 16)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Theme.Palette.background)
                }

                if viewModel.people.isEmpty {
                    Section {
                        PoolEmptyState { handleAddContactTap() }
                            .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 16, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Theme.Palette.background)
                    }
                } else if viewModel.filteredPeople.isEmpty {
                    Section {
                        Text("No matches for “\(viewModel.searchText)”")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Palette.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Theme.Palette.background)
                    }
                }

                Section {
                    ForEach(viewModel.filteredPeople, id: \.objectID) { person in
                        ContactRowCard(
                            name: person.displayName ?? "Unknown",
                            subtitle: lastConnectedSubtitle(for: person),
                            phone: (nil as String?),
                            isPinned: person.isPinned,
                            contactIdentifier: person.contactIdentifier ?? "",
                            cadenceLabel: person.contactCadence.label
                        ) {
                            selectedPerson = person
                            resolvePhoneAndPresent(for: person)
                        }
                        .contentShape(Rectangle())
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Theme.Palette.background)
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
                            .tint(Theme.Palette.brand)
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

                            Menu {
                                ForEach(ContactCadence.allCases) { cadence in
                                    Button {
                                        setCadence(cadence, for: person)
                                    } label: {
                                        if person.contactCadence == cadence {
                                            Label("\(cadence.label) — \(cadence.subtitle)", systemImage: "checkmark")
                                        } else {
                                            Text("\(cadence.label) — \(cadence.subtitle)")
                                        }
                                    }
                                }
                            } label: {
                                Label("How often: \(person.contactCadence.label)", systemImage: "calendar")
                            }

                            Button(role: .destructive) {
                                removeFromPool(person)
                            } label: {
                                Label("Remove from Pool", systemImage: "trash")
                            }
                        }
                    }
                }

                if !viewModel.people.isEmpty {
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
                        .listRowBackground(Theme.Palette.background)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, Theme.Layout.tabBarClearance, for: .scrollContent)
            .background(Theme.Palette.background.ignoresSafeArea())
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
                    connectAndLog(.tel, value: phone)
                }

                Button("Message") {
                    successHaptic()
                    connectAndLog(.sms, value: phone)
                }
            } else {
                Button("No number available", role: .destructive) { }
                    .disabled(true)
            }

            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showContactPicker) {
            MultiContactPickerSheet { selections in
                addContactsToPool(selections)
            }
        }
        .alert("Can’t Connect", isPresented: $showConnectError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(connectErrorMessage ?? "Something went wrong.")
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .alert("Can’t Add Contact", isPresented: $showAddContactError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(addContactErrorMessage ?? "Something went wrong while adding this contact.")
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .alert("Contacts Access Needed", isPresented: $showContactsPermissionAlert) {
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please allow Contacts access in Settings to add people to your pool.")
                .foregroundStyle(Theme.Palette.textSecondary)
        }
    }

    // MARK: - Private Helpers

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private func lastConnectedSubtitle(for person: Person) -> String {
        if let lastCalledAt = person.lastCalledAt {
            return "Last connected " + Self.relativeDateFormatter.localizedString(for: lastCalledAt, relativeTo: Date())
        }
        return "Tap to connect"
    }

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

    private func addContactsToPool(_ selections: [ContactImport]) {
        guard !selections.isEmpty else {
            showContactPicker = false
            return
        }

        do {
            for selection in selections {
                let identifier = selection.contact.id
                let request: NSFetchRequest<Person> = Person.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "contactIdentifier == %@", identifier)

                let existingPerson = try ctx.fetch(request).first
                let person = existingPerson ?? Person(context: ctx)

                if person.id == nil {
                    person.id = UUID()
                }

                person.contactIdentifier = identifier
                person.displayName = selection.contact.name
                person.isInPool = true

                // Only stamp cadence/pin on brand-new people, so re-adding
                // someone never resets a cadence they've already tuned in the pool.
                if existingPerson == nil {
                    person.isPinned = false
                    person.contactCadence = selection.cadence
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
            Self.logger.error("addContactsToPool failed: \(error.localizedDescription, privacy: .public)")
            addContactErrorMessage = error.localizedDescription

            if ctx.hasChanges {
                ctx.rollback()
            }

            showAddContactError = true
        }
    }

    private func resolvePhoneAndPresent(for person: Person) {
        resolvedPhone = nil

        guard let contactId = person.contactIdentifier, !contactId.isEmpty else {
            // No contact identifier stored -> can’t resolve phone
            showConnectSheet = true
            return
        }

        // Resolve the number off the main thread, then present. The connect
        // dialog already handles a nil/empty number ("No number available").
        Task {
            resolvedPhone = await Self.resolvePhoneNumber(for: contactId)
            showConnectSheet = true
        }
    }

    private static func resolvePhoneNumber(for identifier: String) async -> String? {
        await Task.detached(priority: .userInitiated) {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [CNContactPhoneNumbersKey as CNKeyDescriptor]
            guard let contact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys) else {
                return nil
            }
            return contact.phoneNumbers.first?.value.stringValue
        }.value
    }

    /// Opens the link and, on success, logs the check-in for the selected
    /// person so reaching out from the pool also counts automatically.
    /// (markCalled dedups to one connection per contact per day.)
    private func connectAndLog(_ scheme: PhoneLink.Scheme, value: String) {
        guard connectVia(scheme, value: value) else { return }
        guard let person = selectedPerson else { return }
        try? TodayViewModel(context: ctx).markCalled(person)
    }

    @discardableResult
    private func connectVia(_ scheme: PhoneLink.Scheme, value: String) -> Bool {
        guard let url = PhoneLink.url(scheme, number: value) else {
            connectErrorMessage = "Invalid phone number."
            showConnectError = true
            return false
        }

        openURL(url)
        return true
    }

    private func successHaptic() { Haptics.success() }

    // MARK: - Actions

    private func setCadence(_ cadence: ContactCadence, for person: Person) {
        person.contactCadence = cadence
        do {
            try ctx.save()
            viewModel.load()
            successHaptic()
        } catch {
            connectErrorMessage = "Couldn’t update how often to connect."
            showConnectError = true
        }
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


// MARK: - Empty State

/// Shown when the pool has no one in it yet — a warm invitation to add the
/// first few people rather than a blank list.
private struct PoolEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Theme.Space.md) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.Palette.brand)

            VStack(spacing: 6) {
                Text("Build your circle")
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.textPrimary)

                Text("Add a few people you’d like to keep up with, and we’ll suggest who to reach out to each day.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAdd) {
                Label("Add your first people", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .padding(.top, 4)
        }
        .padding(.vertical, Theme.Space.lg)
        .padding(.horizontal, Theme.Space.md)
        .frame(maxWidth: .infinity)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// A contact flattened for the picker: name, first phone, and a lowercased
/// search key are all computed *once* when the address book loads, so filtering
/// while the user types is a cheap string scan rather than re-running
/// `CNContactFormatter` across hundreds of contacts on every keystroke.
private struct PickableContact: Identifiable {
    let id: String
    let contact: CNContact
    let name: String
    let phone: String?
    let searchKey: String
}

/// One person on their way into the pool, paired with the cadence the user
/// assigns during the review step.
private struct ContactImport: Identifiable {
    let contact: PickableContact
    var cadence: ContactCadence
    var id: String { contact.id }
}

private struct MultiContactPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: ([ContactImport]) -> Void

    @State private var contacts: [PickableContact] = []
    @State private var selectedIdentifiers: Set<String> = []
    @State private var searchText = ""
    @State private var pendingReview: [ContactImport] = []
    @State private var isReviewing = false

    private var filteredContacts: [PickableContact] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return contacts }
        return contacts.filter { $0.searchKey.contains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(selectedIdentifiers.isEmpty ? "None selected" : "\(selectedIdentifiers.count) selected")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(selectedIdentifiers.isEmpty ? Theme.Palette.textSecondary : Theme.Palette.brand)

                        Spacer()

                        Button(allShownSelected ? "Deselect All" : "Select All") {
                            toggleSelectAll()
                        }
                        .font(.footnote.weight(.semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.Palette.brand)
                    }
                    .listRowBackground(Theme.Palette.background)
                }

                ForEach(filteredContacts) { item in
                    let isSelected = selectedIdentifiers.contains(item.id)
                    Button {
                        toggleSelection(for: item.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? Theme.Palette.brand : Theme.Palette.textSecondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .foregroundStyle(Theme.Palette.textPrimary)

                                if let phone = item.phone, !phone.isEmpty {
                                    Text(phone)
                                        .font(.footnote)
                                        .foregroundStyle(Theme.Palette.textSecondary)
                                }
                            }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(isSelected ? Theme.Palette.brand.opacity(0.12) : Theme.Palette.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.background.ignoresSafeArea())
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
                    Button(selectedIdentifiers.isEmpty ? "Next" : "Next (\(selectedIdentifiers.count))") {
                        pendingReview = contacts
                            .filter { selectedIdentifiers.contains($0.id) }
                            .map { ContactImport(contact: $0, cadence: .regular) }
                        isReviewing = true
                    }
                    .disabled(selectedIdentifiers.isEmpty)
                }
            }
            .navigationDestination(isPresented: $isReviewing) {
                ImportReviewView(initialSelections: pendingReview) { finalized in
                    onAdd(finalized)
                    dismiss()
                }
            }
            .task {
                await loadContacts()
            }
        }
    }

    private func toggleSelection(for id: String) {
        if selectedIdentifiers.contains(id) {
            selectedIdentifiers.remove(id)
        } else {
            selectedIdentifiers.insert(id)
        }
    }

    /// Whether every contact currently visible (respecting the search filter) is
    /// already selected — drives the Select All / Deselect All toggle.
    private var allShownSelected: Bool {
        let shown = filteredContacts.map(\.id)
        return !shown.isEmpty && shown.allSatisfy { selectedIdentifiers.contains($0) }
    }

    private func toggleSelectAll() {
        let shown = filteredContacts.map(\.id)
        if allShownSelected {
            shown.forEach { selectedIdentifiers.remove($0) }
        } else {
            selectedIdentifiers.formUnion(shown)
        }
    }

    /// Loads the full address book. The enumeration and per-contact formatting
    /// run on a detached background task — with a large address book (hundreds
    /// of contacts) doing this on the main actor freezes the sheet as it opens.
    private func loadContacts() async {
        contacts = await Self.fetchAllContacts()
    }

    private static func fetchAllContacts() async -> [PickableContact] {
        await Task.detached(priority: .userInitiated) {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ]

            var result: [PickableContact] = []
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .userDefault

            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                        ?? [contact.givenName, contact.familyName]
                            .filter { !$0.isEmpty }
                            .joined(separator: " ")
                    let name = fullName.isEmpty ? "Unknown Contact" : fullName
                    let phone = contact.phoneNumbers.first?.value.stringValue
                    let searchKey = (name + " " + (phone ?? "")).lowercased()

                    result.append(
                        PickableContact(
                            id: contact.identifier,
                            contact: contact,
                            name: name,
                            phone: phone,
                            searchKey: searchKey
                        )
                    )
                }
            } catch {
                return []
            }

            return result
        }.value
    }
}

// MARK: - Import Review

/// The guided triage step: after picking people, the user sets a rhythm for
/// each one (with a "set all" shortcut) before they land in the pool — so
/// importing a batch is a quick sorting pass, not a chore of long-pressing each
/// row afterwards.
private struct ImportReviewView: View {
    let initialSelections: [ContactImport]
    let onCommit: ([ContactImport]) -> Void

    @State private var selections: [ContactImport] = []

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("How often would you like to keep in touch with each person? Set them all at once, then fine-tune anyone.")
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.textSecondary)

                    HStack(spacing: 8) {
                        Text("Set all")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.Palette.textPrimary)

                        Spacer()

                        ForEach(ContactCadence.allCases) { cadence in
                            Button(cadence.label) { setAll(cadence) }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Theme.Palette.brand.opacity(0.12)))
                                .foregroundStyle(Theme.Palette.brand)
                                .buttonStyle(.plain)
                        }
                    }
                }
                .listRowBackground(Theme.Palette.background)
            }

            Section {
                ForEach($selections) { $selection in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selection.contact.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Palette.textPrimary)

                        Picker("Cadence", selection: $selection.cadence) {
                            ForEach(ContactCadence.allCases) { cadence in
                                Text(cadence.label).tag(cadence)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Theme.Palette.card)
                }
            } header: {
                Text("\(selections.count) \(selections.count == 1 ? "person" : "people")")
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Palette.background.ignoresSafeArea())
        .navigationTitle("Set a Rhythm")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onCommit(selections)
            } label: {
                Text(selections.count == 1 ? "Add to Pool" : "Add \(selections.count) to Pool")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .padding()
            .background(.ultraThinMaterial)
        }
        .onAppear {
            if selections.isEmpty {
                selections = initialSelections
            }
        }
    }

    private func setAll(_ cadence: ContactCadence) {
        for index in selections.indices {
            selections[index].cadence = cadence
        }
    }
}

