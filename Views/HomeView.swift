import SwiftUI
import UIKit
import CoreData
import Contacts

private struct HomePick: Equatable {
    let identifier: String
    let displayName: String
    let phoneNumber: String?
    let lastConnectedText: String
    let hasConnectedBefore: Bool
}

private struct ContactAvatarInlineView: View {
    let contactIdentifier: String
    let displayName: String

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(Color("Primary").opacity(0.14))
                    Text(initials(from: displayName))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextPrimary"))
                }
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(Circle())
        .task {
            await loadThumbnailIfNeeded()
        }
    }

    private func loadThumbnailIfNeeded() async {
        guard image == nil, !contactIdentifier.isEmpty else { return }

        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [CNContactThumbnailImageDataKey as CNKeyDescriptor]
        let predicate = CNContact.predicateForContacts(withIdentifiers: [contactIdentifier])

        guard let contact = try? store.unifiedContacts(matching: predicate, keysToFetch: keys).first,
              let data = contact.thumbnailImageData,
              let uiImage = UIImage(data: data) else {
            return
        }

        image = uiImage
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

struct HomeView: View {
    // MARK: - Bindings
    @Binding var selectedTab: AppTab

    // MARK: - Environment
    @Environment(\.openURL) private var openURL
    @Environment(\.managedObjectContext) private var context

    // MARK: - State
    @State private var showConnectSheet = false
    @State private var connectErrorMessage: String?
    @State private var showConnectError = false
    @State private var todayPicks: [HomePick] = []
    @State private var selectedPick: HomePick?
    @State private var showResetConfirm = false
    @State private var showingPickDetails = false
    @State private var monthlyGeneratedCount = 0
    @State private var monthlyTargetCount = 0
    @State private var monthlyExpectedByToday = 0

    // MARK: - View
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                let hasTodayPick = !todayPicks.isEmpty
                let shouldShowProgressBanner = hasTodayPick || monthlyTargetCount > 0
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("StayConnected")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))

                    Text("Today")
                        .font(.title3)
                        .foregroundStyle(Color("TextSecondary"))
                        .confirmationDialog(
                            "Connect with \((selectedPick ?? todayPicks.first)?.displayName ?? "today’s pick")",
                            isPresented: $showConnectSheet,
                            titleVisibility: .visible
                        ) {
                            if let phone = (selectedPick ?? todayPicks.first)?.phoneNumber, !phone.isEmpty {
                                Button("Call") {
                                    connectVia("tel", value: phone)
                                }
                                Button("Message") {
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
                        }
                }
                .sheet(isPresented: $showingPickDetails) {
                    VStack(spacing: 16) {
                        Text((selectedPick ?? todayPicks.first)?.displayName ?? "No pick")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let phone = (selectedPick ?? todayPicks.first)?.phoneNumber {
                            Text(phone)
                                .foregroundStyle(Color("TextSecondary"))
                        }

                        Text((selectedPick ?? todayPicks.first)?.lastConnectedText ?? "Generate a pick or add more people to your pool")
                            .foregroundStyle(Color("TextSecondary"))

                        Spacer()
                    }
                    .padding()
                }

                if shouldShowProgressBanner {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Today’s Picks")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color("TextPrimary"))
                                    Text("Tap a person to view details or connect")
                                        .font(.subheadline)
                                        .foregroundStyle(Color("TextSecondary"))
                                }
                                Spacer()
                                Image(systemName: "sparkles")
                                    .font(.title3)
                                    .foregroundStyle(Color("Primary"))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(monthlyGeneratedCount) / \(monthlyTargetCount) picks this month")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color("TextPrimary"))
                                    Spacer()
                                    Text(progressMessage)
                                        .font(.caption)
                                        .foregroundStyle(Color("TextSecondary"))
                                }

                                ProgressView(value: monthlyProgress)
                                    .tint(progressTintColor)

                                Text("Expected by today: \(monthlyExpectedByToday) picks")
                                    .font(.caption)
                                    .foregroundStyle(Color("TextSecondary"))
                            }
                        }

                        if hasTodayPick {
                            VStack(spacing: 0) {
                                ForEach(Array(todayPicks.enumerated()), id: \.offset) { entry in
                                    let index = entry.offset
                                    let pick = entry.element

                                    HStack(spacing: 12) {
                                        ContactAvatarInlineView(
                                            contactIdentifier: pick.identifier,
                                            displayName: pick.displayName
                                        )

                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(spacing: 8) {
                                                Text(pick.displayName)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(Color("TextPrimary"))
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(1)

                                                Text(pick.hasConnectedBefore ? "Connected" : "New")
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        Capsule()
                                                            .fill(
                                                                pick.hasConnectedBefore
                                                                ? Color("Success").opacity(0.16)
                                                                : Color("Primary").opacity(0.14)
                                                            )
                                                    )
                                                    .foregroundStyle(
                                                        pick.hasConnectedBefore
                                                        ? Color("Success")
                                                        : Color("Primary")
                                                    )
                                            }

                                            Text(pick.lastConnectedText)
                                                .font(.caption)
                                                .foregroundStyle(Color("TextSecondary"))
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                        }

                                        Spacer(minLength: 8)

                                        HStack(spacing: 8) {
                                            Button {
                                                selectedPick = pick
                                                lightHaptic()
                                                showConnectSheet = true
                                            } label: {
                                                Image(systemName: "phone.fill")
                                                    .font(.subheadline)
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(Color("Success"))

                                            Button {
                                                lightHaptic()
                                                markPickAsCalled(pick)
                                            } label: {
                                                Image(systemName: "checkmark")
                                                    .font(.subheadline)
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(Color("Primary"))
                                        }
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPick = pick
                                        lightHaptic()
                                        showingPickDetails = true
                                    }

                                    if index < todayPicks.count - 1 {
                                        Divider()
                                            .overlay(Color("Divider"))
                                            .padding(.leading, 58)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color("Card"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color("Divider").opacity(0.8), lineWidth: 1)
                            )
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No pick for today")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color("TextPrimary"))
                                Text("Tap Generate to create today’s picks. Your monthly progress is still saved below.")
                                    .font(.footnote)
                                    .foregroundStyle(Color("TextSecondary"))
                            }
                            .padding(.vertical,14)
                            .padding(.horizontal,12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("Card"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("Divider").opacity(0.8), lineWidth: 1)
                            )
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color("Card"),
                                        Color("Primary").opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color("Divider").opacity(0.85), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
                } else {
                    TodayCardView(
                        pick: TodayPick(
                            displayName: "No pick for today",
                            phoneNumber: nil,
                            lastConnectedText: "Generate a pick or add more people to your pool"
                        )
                    ) { }
                }

                // Quick navigation
                Button {
                    lightHaptic()
                    selectedTab = .pool
                } label: {
                    Label("View Pool", systemImage: "person.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryPillButtonStyle())

                Spacer()

                // Action buttons
                HStack(spacing: 14) {
                    Button(action: {
                        lightHaptic()
                        generateTodayPick()
                    }) {
                        Label("Generate", systemImage: "sparkles")
                    }
                    .buttonStyle(PrimaryPillButtonStyle())

                    Button(action: {
                        lightHaptic()
                        showResetConfirm = true
                    }) {
                        Label("Reset Today", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                    .disabled(!hasTodayPick)
                }
                .confirmationDialog(
                    "Reset today’s pick?",
                    isPresented: $showResetConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Reset", role: .destructive) {
                        resetTodayPick()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will remove today’s saved pick and generate a fresh one the next time you tap Generate.")
                }
                .padding(.top, 6)

                // Footer text
                Text("Small consistent breaks build real connections.")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.top, 8)
            }
            .padding()
            .background(Color("Background").ignoresSafeArea())
            .onAppear {
                refreshTodayPicks()
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .home {
                    refreshTodayPicks()
                }
            }
        }
    }

    private var monthlyProgress: Double {
        guard monthlyTargetCount > 0 else { return 0 }
        return min(Double(monthlyGeneratedCount) / Double(monthlyTargetCount), 1.0)
    }

    private var progressMessage: String {
        guard monthlyTargetCount > 0 else { return "No target yet" }

        if monthlyGeneratedCount >= monthlyTargetCount {
            return "Target reached"
        }

        if monthlyGeneratedCount > monthlyExpectedByToday {
            return "Ahead of pace"
        } else if monthlyGeneratedCount == monthlyExpectedByToday {
            return "On pace"
        } else {
            return "Behind pace"
        }
    }

    private var progressTintColor: Color {
        switch progressMessage {
        case "Target reached":
            return Color("Success")
        case "Ahead of pace", "On pace":
            return Color("Primary")
        default:
            return Color("Warning")
        }
    }

    // MARK: - Private Helpers
    private func refreshTodayPicks() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        let dailyRequest: NSFetchRequest<DailyPick> = DailyPick.fetchRequest()
        dailyRequest.fetchLimit = 1
        dailyRequest.predicate = NSPredicate(format: "date == %@", startOfToday as NSDate)

        guard let dailyPick = try? context.fetch(dailyRequest).first,
              let identifiers = dailyPick.contactIdentifiers as? [String],
              !identifiers.isEmpty else {
            todayPicks = []
            selectedPick = nil
            refreshMonthlyProgress()
            return
        }

        todayPicks = identifiers.compactMap { identifier in
            guard let person = fetchPerson(with: identifier) else { return nil }
            return HomePick(
                identifier: identifier,
                displayName: person.displayName ?? "Unknown",
                phoneNumber: fetchPhoneNumber(for: identifier),
                lastConnectedText: lastConnectedText(for: person),
                hasConnectedBefore: person.lastCalledAt != nil
            )
        }

        selectedPick = todayPicks.first
        refreshMonthlyProgress()
    }

    private func generateTodayPick() {
        do {
            let settings = try AppSettings.fetchOrCreate(in: context)

            let personRequest: NSFetchRequest<Person> = Person.fetchRequest()
            personRequest.predicate = NSPredicate(format: "isInPool == YES")
            let pool = try context.fetch(personRequest)

            guard !pool.isEmpty else {
                todayPicks = []
                selectedPick = nil
                return
            }

            let selector = SelectionService()
            let picks = selector.pickToday(
                from: pool,
                picksPerDay: Int(settings.picksPerDay),
                minGapDays: Int(settings.minGapDays),
                today: Date()
            )

            guard !picks.isEmpty else {
                refreshTodayPicks()
                return
            }

            let now = Date()
            picks.forEach { $0.lastPickedAt = now }
            let identifiers = picks.compactMap { $0.contactIdentifier }
            _ = try DailyPick.upsertForToday(with: identifiers, in: context)
            try context.save()
            refreshTodayPicks()
        } catch {
            connectErrorMessage = "Couldn’t generate today’s pick."
            showConnectError = true
        }
    }

    private func resetTodayPick() {
        do {
            if let dailyPick = try DailyPick.fetchFor(date: Date(), in: context) {
                context.delete(dailyPick)
                try context.save()
            }
            refreshTodayPicks()
        } catch {
            connectErrorMessage = "Couldn’t reset today’s pick."
            showConnectError = true
        }
    }

    private func markPickAsCalled(_ pick: HomePick) {
        do {
            guard let person = fetchPerson(with: pick.identifier) else { return }

            let now = Date()
            person.lastCalledAt = now

            if !hasLoggedConnectionToday(for: pick.identifier) {
                let event = ConnectionEvent(context: context)
                event.id = UUID()
                event.date = now
                event.contactIdentifier = pick.identifier
                event.contactNameSnapshot = pick.displayName
            }

            try context.save()
            refreshTodayPicks()
        } catch {
            connectErrorMessage = "Couldn’t mark this contact as called."
            showConnectError = true
        }
    }

    private func hasLoggedConnectionToday(for identifier: String) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }

        let request: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "contactIdentifier == %@ AND date >= %@ AND date < %@",
            identifier,
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        return ((try? context.count(for: request)) ?? 0) > 0
    }

    private func refreshMonthlyProgress() {
        let calendar = Calendar.current
        let now = Date()

        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let range = calendar.range(of: .day, in: .month, for: now)
        let daysInMonth = range?.count ?? 30
        let dayOfMonth = calendar.component(.day, from: now)

        let settings: AppSettings?
        do {
            settings = try AppSettings.fetchOrCreate(in: context)
        } catch {
            monthlyGeneratedCount = 0
            monthlyTargetCount = 0
            monthlyExpectedByToday = 0
            return
        }

        let picksPerDay = max(Int(settings?.picksPerDay ?? 0), 0)
        monthlyTargetCount = picksPerDay * daysInMonth
        monthlyExpectedByToday = min(picksPerDay * dayOfMonth, monthlyTargetCount)

        let request: NSFetchRequest<DailyPick> = DailyPick.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", startOfMonth as NSDate)

        guard let monthlyPicks = try? context.fetch(request) else {
            monthlyGeneratedCount = 0
            return
        }

        monthlyGeneratedCount = monthlyPicks.reduce(0) { partial, dailyPick in
            let ids = dailyPick.contactIdentifiers as? [String]
            return partial + (ids?.count ?? 0)
        }
    }

    private func fetchPerson(with identifier: String) -> Person? {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "contactIdentifier == %@", identifier)
        return try? context.fetch(request).first
    }

    private func fetchPhoneNumber(for identifier: String) -> String? {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [CNContactPhoneNumbersKey as CNKeyDescriptor]
        let predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])

        guard let contact = try? store.unifiedContacts(matching: predicate, keysToFetch: keys).first else {
            return nil
        }

        return contact.phoneNumbers.first?.value.stringValue
    }

    private func lastConnectedText(for person: Person) -> String {
        if let lastCalledAt = person.lastCalledAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "Last connected: " + formatter.localizedString(for: lastCalledAt, relativeTo: Date())
        }
        return "Not connected yet"
    }

    private func connectVia(_ scheme: String, value: String) {
        let cleaned = value
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()

        guard !cleaned.isEmpty else {
            connectErrorMessage = "No phone number found for this contact."
            showConnectError = true
            return
        }

        guard let url = URL(string: "\(scheme)://\(cleaned)") else {
            connectErrorMessage = "Couldn’t create a valid link."
            showConnectError = true
            return
        }

        successHaptic()
        openURL(url)
    }

    private func lightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}


#Preview {
    HomeView(selectedTab: .constant(.home))
}
