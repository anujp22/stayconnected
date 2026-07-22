import Contacts
import CoreData
import SwiftUI

struct ContactHistoryView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var context
    @Environment(\.openURL) private var openURL

    // MARK: - Properties

    // Observed so the card reacts live to mark/undo/note/birthday edits.
    @ObservedObject var person: Person

    /// True when this person is one of today's picks — only then does the
    /// "Not today" (snooze) action make sense.
    var isTodayPick: Bool = false

    // MARK: - State
    @State private var events: [ConnectionEvent] = []
    @State private var showBirthdayEditor = false
    @State private var birthdayDraft = Date()

    @State private var resolvedPhone: String?
    @State private var showConnectSheet = false
    @State private var showSnoozeOptions = false
    @State private var connectErrorMessage: String?
    @State private var showConnectError = false
    @State private var noteDraft = ""

    // MARK: - Derived

    private var connectedToday: Bool {
        guard let last = person.lastCalledAt else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private var noteChanged: Bool {
        noteDraft.trimmingCharacters(in: .whitespacesAndNewlines) != (person.note ?? "")
    }

    // MARK: - View
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                profileCard

                actionsCard

                noteCard

                birthdayCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("History")
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if events.isEmpty {
                        Text("No connection history yet. Reach out and it’ll show up here.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Palette.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .cardSurface()
                    } else {
                        timeline
                    }
                }
            }
            .padding()
        }
        .background(Theme.Palette.background.ignoresSafeArea())
        .navigationTitle(person.displayName ?? "History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshEvents()
            noteDraft = person.note ?? ""
            Task { resolvedPhone = await Self.resolvePhoneNumber(for: person.contactIdentifier ?? "") }
        }
        .sheet(isPresented: $showBirthdayEditor) {
            birthdayEditor
        }
        .confirmationDialog(
            "Connect with \(person.displayName ?? "this contact")",
            isPresented: $showConnectSheet,
            titleVisibility: .visible
        ) {
            if let phone = resolvedPhone, !phone.isEmpty {
                Button("Call") { connect(.tel, value: phone) }
                Button("Message") { connect(.sms, value: phone) }
            } else {
                Button("No number available", role: .destructive) { }.disabled(true)
            }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Not today for \(person.displayName ?? "this person")?",
            isPresented: $showSnoozeOptions,
            titleVisibility: .visible
        ) {
            Button("Just for today") { snooze(days: 1) }
            Button("Snooze for a week") { snooze(days: 7) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("We’ll gently set them aside and suggest someone else instead.")
        }
        .alert("Can’t Connect", isPresented: $showConnectError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(connectErrorMessage ?? "Something went wrong.")
        }
    }

    // MARK: - Actions Card

    private var actionsCard: some View {
        VStack(spacing: 12) {
            if connectedToday {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Palette.success)
                    Text("Connected today")
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Spacer()
                    Button("Undo") { undoConnected() }
                        .font(.subheadline.weight(.semibold))
                        .tint(Theme.Palette.textSecondary)
                }
            }

            HStack(spacing: 10) {
                Button {
                    connectOrPrompt(.tel)
                } label: {
                    Label("Call", systemImage: "phone.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryPillButtonStyle())

                Button {
                    connectOrPrompt(.sms)
                } label: {
                    Label("Message", systemImage: "message.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryPillButtonStyle())
            }

            if !connectedToday {
                HStack {
                    Button {
                        markDone()
                    } label: {
                        Label("Mark done", systemImage: "checkmark")
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(Theme.Palette.brand)

                    if isTodayPick {
                        Spacer()
                        Button {
                            Haptics.light()
                            showSnoozeOptions = true
                        } label: {
                            Label("Not today", systemImage: "moon.zzz")
                                .font(.subheadline.weight(.medium))
                        }
                        .tint(Theme.Palette.textSecondary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardSurface()
    }

    // MARK: - Note Card

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Note", systemImage: "quote.opening")
                .font(.headline)
                .foregroundStyle(Theme.Palette.textPrimary)

            TextField("e.g. ask about her new job", text: $noteDraft, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("A quick memory jog for next time you reach out.")
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)

                Spacer()

                if noteChanged {
                    Button("Save") { saveNote() }
                        .font(.subheadline.weight(.semibold))
                        .tint(Theme.Palette.brand)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    // MARK: - Birthday

    private var birthdayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Birthday", systemImage: "birthday.cake.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.textPrimary)

                Spacer()

                Button(person.birthday == nil ? "Add" : "Edit") {
                    birthdayDraft = person.birthday ?? defaultBirthdayDraft
                    showBirthdayEditor = true
                }
                .font(.subheadline.weight(.semibold))
                .tint(Theme.Palette.brand)
            }

            if let birthday = person.birthday {
                HStack(spacing: 8) {
                    Text(birthday.formatted(.dateTime.month(.wide).day()))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.textPrimary)

                    if let label = person.birthdayShortLabel() {
                        Text("· \(label)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Palette.accentWarm)
                    }
                }
            } else {
                Text("Add a birthday to get a gentle reminder on the day.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    private var birthdayEditor: some View {
        NavigationStack {
            VStack(spacing: Theme.Space.lg) {
                DatePicker(
                    "Birthday",
                    selection: $birthdayDraft,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Theme.Palette.brand)

                if person.birthday != nil {
                    Button(role: .destructive) {
                        saveBirthday(nil)
                    } label: {
                        Label("Remove birthday", systemImage: "trash")
                    }
                }

                Spacer()
            }
            .padding()
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle("Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showBirthdayEditor = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveBirthday(birthdayDraft) }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    /// A sensible default when adding a birthday for the first time — 30 years
    /// ago, so the picker opens somewhere reasonable rather than today.
    private var defaultBirthdayDraft: Date {
        Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    }

    private func saveBirthday(_ date: Date?) {
        person.birthday = date
        try? context.save()
        showBirthdayEditor = false
        Task { try? await NotificationsService.syncBirthdayReminders(in: context) }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 12) {
            ContactAvatarInlineView(
                contactIdentifier: person.contactIdentifier ?? "",
                displayName: person.displayName ?? "Unknown",
                size: 64
            )

            VStack(spacing: 4) {
                Text(person.displayName ?? "Unknown")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)

                Chip(text: person.contactCadence.label, fillOpacity: 0.12)
            }

            HStack(spacing: 0) {
                statColumn(value: "\(events.count)", label: "Connections")

                Divider().frame(height: 32).overlay(Theme.Palette.divider)

                statColumn(value: lastConnectedValue, label: "Last connected")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Space.lg)
        .cardSurface()
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.Palette.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timeline

    private var timeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.element.objectID) { entry in
                let event = entry.element
                let isLast = entry.offset == events.count - 1

                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Theme.Palette.success)
                            .frame(width: 10, height: 10)
                            .padding(.top, 4)

                        if !isLast {
                            Rectangle()
                                .fill(Theme.Palette.divider)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.date?.formatted(.dateTime.month().day().year()) ?? "Unknown date")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Palette.textPrimary)

                        Text(event.date?.formatted(.dateTime.hour().minute()) ?? "")
                            .font(.caption)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                    .padding(.bottom, isLast ? 0 : Theme.Space.md)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: - Derived Values

    private var lastConnectedValue: String {
        guard let lastCalledAt = person.lastCalledAt else { return "Never" }
        return lastCalledAt.formatted(.dateTime.month().day())
    }

    // MARK: - Actions

    /// Connects immediately when we've resolved a number, otherwise opens the
    /// dialog (which surfaces "No number available").
    private func connectOrPrompt(_ scheme: PhoneLink.Scheme) {
        if let phone = resolvedPhone, !phone.isEmpty {
            connect(scheme, value: phone)
        } else {
            Haptics.light()
            showConnectSheet = true
        }
    }

    /// Opens the call/message link and, when it launches, logs the connection.
    private func connect(_ scheme: PhoneLink.Scheme, value: String) {
        guard let url = PhoneLink.url(scheme, number: value) else {
            connectErrorMessage = "No valid phone number for this contact."
            showConnectError = true
            return
        }
        Haptics.success()
        openURL(url)
        logConnection()
    }

    private func markDone() {
        Haptics.success()
        logConnection()
    }

    private func logConnection() {
        do {
            try TodayViewModel(context: context).markCalled(person)
            refreshEvents()
        } catch {
            connectErrorMessage = "Couldn’t record this connection."
            showConnectError = true
        }
    }

    private func undoConnected() {
        do {
            Haptics.light()
            try TodayViewModel(context: context).unmarkConnectedToday(person)
            refreshEvents()
        } catch {
            connectErrorMessage = "Couldn’t undo this connection."
            showConnectError = true
        }
    }

    private func snooze(days: Int) {
        do {
            let calendar = Calendar.current
            let base = calendar.startOfDay(for: Date())
            let until = calendar.date(byAdding: .day, value: days, to: base) ?? Date()
            try TodayViewModel(context: context).snoozePick(person, until: until)
            Haptics.success()
        } catch {
            connectErrorMessage = "Couldn’t snooze this pick."
            showConnectError = true
        }
    }

    private func saveNote() {
        try? TodayViewModel(context: context)
            .setNote(noteDraft, forContactIdentifier: person.contactIdentifier ?? "")
        Haptics.light()
    }

    private static func resolvePhoneNumber(for identifier: String) async -> String? {
        guard !identifier.isEmpty else { return nil }
        return await Task.detached(priority: .userInitiated) {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [CNContactPhoneNumbersKey as CNKeyDescriptor]
            guard let contact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys) else {
                return nil
            }
            return contact.phoneNumbers.first?.value.stringValue
        }.value
    }

    // MARK: - Private Helpers
    private func refreshEvents() {
        let identifier = person.contactIdentifier ?? ""
        guard !identifier.isEmpty else {
            events = []
            return
        }

        let request: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        request.predicate = NSPredicate(format: "contactIdentifier == %@", identifier)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            events = try context.fetch(request)
        } catch {
            events = []
        }
    }
}

// MARK: - Preview
#Preview {
    Text("ContactHistoryView preview requires a Person instance.")
}
