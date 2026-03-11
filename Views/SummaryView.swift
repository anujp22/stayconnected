import CoreData
import SwiftUI

struct SummaryView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var context
    // MARK: - State
    @State private var poolCount = 0
    @State private var calledThisMonth = 0
    @State private var remainingThisMonth = 0
    @State private var calledPeople: [Person] = []
    @State private var neverContactedPeople: [Person] = []
    @State private var recentEvents: [ConnectionEvent] = []
    @State private var currentStreak = 0
    @State private var longestStreak = 0
    @State private var selectedPerson: Person?
    // MARK: - View
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summary")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("TextPrimary"))

                        Text("Your progress and activity")
                            .font(.title3)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    // MARK: Streaks
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Current Streak",
                            value: currentStreakLabel,
                            color: Color("Primary")
                        )

                        StatCard(
                            title: "Longest Streak",
                            value: longestStreakLabel,
                            color: Color("PrimaryDeep")
                        )
                    }

                    // MARK: Top Stats
                    VStack(spacing: 16) {
                        StatCard(
                            title: "People in Pool",
                            value: "\(poolCount)",
                            color: Color("Primary")
                        )

                        StatCard(
                            title: "Called This Month",
                            value: "\(calledThisMonth)",
                            color: Color("Success")
                        )

                        StatCard(
                            title: "Remaining This Month",
                            value: "\(remainingThisMonth)",
                            color: Color("Warning")
                        )
                    }
                    .padding(.top, 20)

                    // MARK: Called This Month
                    SummarySectionCard(title: "Called This Month") {
                        if calledPeople.isEmpty {
                            Text("No one marked as called yet this month.")
                                .font(.subheadline)
                                .foregroundStyle(Color("TextSecondary"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(calledPeople, id: \.objectID) { person in
                                    Button {
                                        selectedPerson = person
                                    } label: {
                                        HStack {
                                            Text(person.displayName ?? "Unknown")
                                                .font(.subheadline)
                                                .foregroundStyle(Color("TextPrimary"))
                                            Spacer()
                                            if let lastCalled = person.lastCalledAt {
                                                Text(lastCalled, format: .dateTime.month().day())
                                                    .font(.caption)
                                                    .foregroundStyle(Color("TextSecondary"))
                                            }
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(Color("TextSecondary").opacity(0.7))
                                        }
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if person.objectID != calledPeople.last?.objectID {
                                        Divider()
                                            .overlay(Color("Divider"))
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Never Contacted Yet
                    SummarySectionCard(title: "Never Contacted Yet") {
                        if neverContactedPeople.isEmpty {
                            Text("Everyone in your pool has been contacted at least once.")
                                .font(.subheadline)
                                .foregroundStyle(Color("TextSecondary"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(neverContactedPeople, id: \.objectID) { person in
                                    Button {
                                        selectedPerson = person
                                    } label: {
                                        HStack {
                                            Text(person.displayName ?? "Unknown")
                                                .font(.subheadline)
                                                .foregroundStyle(Color("TextPrimary"))
                                            Spacer()
                                            Text("Never")
                                                .font(.caption)
                                                .foregroundStyle(Color("TextSecondary"))
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(Color("TextSecondary").opacity(0.7))
                                        }
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if person.objectID != neverContactedPeople.last?.objectID {
                                        Divider()
                                            .overlay(Color("Divider"))
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Recent Activity
                    SummarySectionCard(title: "Recent Activity") {
                        if recentEvents.isEmpty {
                            Text("No recent activity yet. Mark a contact as called to start building history.")
                                .font(.subheadline)
                                .foregroundStyle(Color("TextSecondary"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(recentEvents, id: \.objectID) { event in
                                    if let identifier = event.contactIdentifier,
                                       let person = fetchPerson(with: identifier) {
                                        Button {
                                            selectedPerson = person
                                        } label: {
                                            HStack(alignment: .top) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(activityNameLabel(for: event))
                                                        .font(.subheadline)
                                                        .foregroundStyle(Color("TextPrimary"))

                                                    Text(activityDateLabel(for: event.date))
                                                        .font(.caption)
                                                        .foregroundStyle(Color("TextSecondary"))
                                                }

                                                Spacer()

                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color("Success"))

                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundStyle(Color("TextSecondary").opacity(0.7))
                                            }
                                            .padding(.vertical, 10)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(activityNameLabel(for: event))
                                                    .font(.subheadline)

                                                Text(activityDateLabel(for: event.date))
                                                    .font(.caption)
                                                    .foregroundStyle(Color("TextSecondary"))
                                            }

                                            Spacer()

                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color("Success"))
                                        }
                                        .padding(.vertical, 10)
                                    }

                                    if event.objectID != recentEvents.last?.objectID {
                                        Divider()
                                            .overlay(Color("Divider"))
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Section Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How this works")
                            .font(.headline)
                            .foregroundStyle(Color("TextPrimary"))

                        Text("This summary shows your streak progress, how many people are currently in your connection pool, who you have marked as called this month, who still has never been contacted, and your most recent connection activity.")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedPerson) { person in
                ContactHistoryView(person: person)
            }
            .onAppear {
                refreshSummary()
            }
        }
    }

    // MARK: - Private Helpers
    
    private func refreshSummary() {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.predicate = NSPredicate(format: "isInPool == YES")

        guard let pool = try? context.fetch(request) else {
            poolCount = 0
            calledThisMonth = 0
            remainingThisMonth = 0
            calledPeople = []
            neverContactedPeople = []
            recentEvents = []
            currentStreak = 0
            longestStreak = 0
            return
        }

        poolCount = pool.count

        calledPeople = pool
            .filter { person in
                guard let lastCalled = person.lastCalledAt else { return false }
                return lastCalled >= startOfMonth
            }
            .sorted { ($0.lastCalledAt ?? .distantPast) > ($1.lastCalledAt ?? .distantPast) }

        neverContactedPeople = pool
            .filter { $0.lastCalledAt == nil }
            .sorted { ($0.displayName ?? "") < ($1.displayName ?? "") }

        calledThisMonth = calledPeople.count
        remainingThisMonth = max(poolCount - calledThisMonth, 0)

        let recentEventsRequest: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        recentEventsRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        recentEventsRequest.fetchLimit = 15

        do {
            recentEvents = try context.fetch(recentEventsRequest)
        } catch {
            recentEvents = []
        }

        let allEventsRequest: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        allEventsRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let allEvents = try context.fetch(allEventsRequest)
            let streaks = calculateStreaks(from: allEvents)
            currentStreak = streaks.current
            longestStreak = streaks.longest
        } catch {
            currentStreak = 0
            longestStreak = 0
        }
    }

    private func fetchPerson(with identifier: String) -> Person? {
        guard !identifier.isEmpty else { return nil }

        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "contactIdentifier == %@", identifier)

        do {
            return try context.fetch(request).first
        } catch {
            return nil
        }
    }

    private func activityNameLabel(for event: ConnectionEvent) -> String {
        let name = event.contactNameSnapshot ?? ""
        return name.isEmpty ? "Unknown" : name
    }

    private func activityDateLabel(for date: Date?) -> String {
        guard let date else { return "Unknown date" }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.month().day().year())
        }
    }

    // MARK: - Derived Values
    private var currentStreakLabel: String {
        streakLabel(for: currentStreak)
    }

    private var longestStreakLabel: String {
        streakLabel(for: longestStreak)
    }

    private func streakLabel(for value: Int) -> String {
        value == 1 ? "1 day" : "\(value) days"
    }

    private func calculateStreaks(from events: [ConnectionEvent]) -> (current: Int, longest: Int) {
        let calendar = Calendar.current

        let uniqueDays: Set<Date> = Set(
            events.compactMap { event in
                guard let date = event.date else { return nil }
                return calendar.startOfDay(for: date)
            }
        )

        guard !uniqueDays.isEmpty else {
            return (0, 0)
        }

        let sortedDays = uniqueDays.sorted { $0 > $1 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let startsTodayOrYesterday = uniqueDays.contains(today) || uniqueDays.contains(yesterday)

        var current = 0
        if startsTodayOrYesterday {
            var cursor = uniqueDays.contains(today) ? today : yesterday

            while uniqueDays.contains(cursor) {
                current += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                    break
                }
                cursor = previousDay
            }
        }

        var longest = 0
        var running = 0
        var previousDay: Date?

        for day in sortedDays {
            if let previous = previousDay,
               let expectedPrevious = calendar.date(byAdding: .day, value: -1, to: previous),
               calendar.isDate(day, inSameDayAs: expectedPrevious) {
                running += 1
            } else {
                running = 1
            }

            longest = max(longest, running)
            previousDay = day
        }

        return (current, longest)
    }
}

// MARK: - Reusable Cards

struct StatCard: View {
    // MARK: - Properties
    let title: String
    let value: String
    let color: Color

    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 96)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color("Card"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color("Divider").opacity(0.8), lineWidth: 1)
        )
    }
}

struct SummarySectionCard<Content: View>: View {
    // MARK: - Properties
    let title: String
    private let content: Content

    // MARK: - Initialization
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color("Card"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color("Divider").opacity(0.8), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    SummaryView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
