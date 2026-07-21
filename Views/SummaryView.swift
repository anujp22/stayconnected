import CoreData
import SwiftUI

struct SummaryView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    // MARK: - State
    @State private var recentEvents: [ConnectionEvent] = []
    @State private var peopleByIdentifier: [String: Person] = [:]
    @State private var currentStreak = 0
    @State private var longestStreak = 0
    @State private var selectedPerson: Person?
    @State private var dailyCounts: [Date: Int] = [:]
    @State private var monthlyConnectedCount = 0
    // MARK: - View
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summary")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.Palette.textPrimary)

                        Text("Your progress and activity")
                            .font(.title3)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    // MARK: Month + Streak Hero
                    SummaryHero(
                        connected: monthlyConnectedCount,
                        currentStreak: currentStreak,
                        longestStreak: longestStreak,
                        currentStreakLabel: currentStreakLabel,
                        longestStreakLabel: longestStreakLabel
                    )

                    // MARK: Activity
                    SummarySectionCard(title: "Activity") {
                        ActivityHeatmap(counts: dailyCounts)
                    }

                    // MARK: Recent Activity
                    SummarySectionCard(title: "Recent Activity") {
                        if recentEvents.isEmpty {
                            Text("No recent activity yet. Mark a contact as called to start building history.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Palette.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(recentEvents, id: \.objectID) { event in
                                    if let identifier = event.contactIdentifier,
                                       let person = peopleByIdentifier[identifier] {
                                        Button {
                                            selectedPerson = person
                                        } label: {
                                            HStack(alignment: .top) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(activityNameLabel(for: event))
                                                        .font(.subheadline)
                                                        .foregroundStyle(Theme.Palette.textPrimary)

                                                    Text(activityDateLabel(for: event.date))
                                                        .font(.caption)
                                                        .foregroundStyle(Theme.Palette.textSecondary)
                                                }

                                                Spacer()

                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Theme.Palette.success)

                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.Palette.textSecondary.opacity(0.7))
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
                                                    .foregroundStyle(Theme.Palette.textSecondary)
                                            }

                                            Spacer()

                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Theme.Palette.success)
                                        }
                                        .padding(.vertical, 10)
                                    }

                                    if event.objectID != recentEvents.last?.objectID {
                                        Divider()
                                            .overlay(Theme.Palette.divider)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, Theme.Layout.tabBarClearance)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedPerson) { person in
                ContactHistoryView(person: person)
            }
            .task {
                refreshSummary()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
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
            recentEvents = []
            currentStreak = 0
            longestStreak = 0
            dailyCounts = [:]
            monthlyConnectedCount = 0
            return
        }

        peopleByIdentifier = Dictionary(
            uniqueKeysWithValues: pool.compactMap { person in
                guard let identifier = person.contactIdentifier, !identifier.isEmpty else {
                    return nil
                }
                return (identifier, person)
            }
        )

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
            let streaks = NotificationsService.streaks(from: allEvents)
            currentStreak = streaks.current
            longestStreak = streaks.longest

            // Bucket every event into its start-of-day for the heatmap, and
            // count this month's connections for the running total.
            var buckets: [Date: Int] = [:]
            var monthCount = 0
            for event in allEvents {
                guard let date = event.date else { continue }
                let day = calendar.startOfDay(for: date)
                buckets[day, default: 0] += 1
                if date >= startOfMonth { monthCount += 1 }
            }
            dailyCounts = buckets
            monthlyConnectedCount = monthCount
        } catch {
            currentStreak = 0
            longestStreak = 0
            dailyCounts = [:]
            monthlyConnectedCount = 0
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
}

// MARK: - Summary Hero

/// The top-of-Summary hero: this month's connection count paired with the
/// streak figures. A running total to celebrate — no target, ratio, or quota.
private struct SummaryHero: View {
    let connected: Int
    let currentStreak: Int
    let longestStreak: Int
    let currentStreakLabel: String
    let longestStreakLabel: String

    var body: some View {
        HStack(spacing: Theme.Space.lg) {
            MonthCountMedallion(connected: connected)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This month")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Text(connected == 1 ? "1 connection" : "\(connected) connections")
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }

                streakRow(
                    icon: "flame.fill",
                    iconColor: Theme.Palette.accentWarm,
                    title: "Current streak",
                    value: currentStreakLabel
                )

                streakRow(
                    icon: "trophy.fill",
                    iconColor: Theme.Palette.brand,
                    title: "Longest streak",
                    value: longestStreakLabel
                )
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private func streakRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(iconColor)
                .frame(width: 18)

            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Palette.textSecondary)

            Spacer(minLength: 6)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Palette.textPrimary)
        }
    }
}

/// A soft medallion showing this month's connection count — the calm,
/// quota-free replacement for the old progress ring.
private struct MonthCountMedallion: View {
    let connected: Int

    var body: some View {
        ZStack {
            Circle().fill(Theme.Palette.brand.opacity(0.10))
            Circle().stroke(Theme.Palette.brand.opacity(0.20), lineWidth: 1.5)

            Text("\(connected)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.brandGradient)
        }
        .frame(width: 96, height: 96)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            connected == 1 ? "1 connection this month" : "\(connected) connections this month"
        )
    }
}

// MARK: - Reusable Cards

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
                .foregroundStyle(Theme.Palette.textPrimary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface(radius: 18, strokeOpacity: 0.8)
    }
}

// MARK: - Preview

#Preview {
    SummaryView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
