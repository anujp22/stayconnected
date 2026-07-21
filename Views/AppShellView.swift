import Contacts
import CoreData
import SwiftUI

// MARK: - App Tabs

enum AppTab: Hashable, CaseIterable {
    // MARK: - Cases
    case home
    case pool
    case summary
    case settings

    // MARK: - Display Metadata

    var title: String {
        switch self {
        case .home: return "Home"
        case .pool: return "Pool"
        case .summary: return "Summary"
        case .settings: return "Settings"
        }
    }

    /// Outline glyph shown when the tab is not selected.
    var icon: String {
        switch self {
        case .home: return "house"
        case .pool: return "person.2"
        case .summary: return "chart.bar"
        case .settings: return "gearshape"
        }
    }

    /// Filled glyph shown when the tab is selected.
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .pool: return "person.2.fill"
        case .summary: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct AppShellView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State
    @State private var selectedTab: AppTab = .home
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // MARK: - View
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tag(AppTab.home)
                .toolbar(.hidden, for: .tabBar)

            PoolView(context: ctx)
                .tag(AppTab.pool)
                .toolbar(.hidden, for: .tabBar)

            SummaryView()
                .tag(AppTab.summary)
                .toolbar(.hidden, for: .tabBar)

            SettingsView(context: ctx)
                .tag(AppTab.settings)
                .toolbar(.hidden, for: .tabBar)
        }
        .overlay(alignment: .bottom) {
            FloatingTabBar(selectedTab: $selectedTab)
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            OnboardingView(
                onStartSetup: {
                    hasSeenOnboarding = true
                    selectedTab = .pool
                },
                onSkip: {
                    hasSeenOnboarding = true
                }
            )
        }
        // Re-sync reminders on every launch and foreground so their copy stays
        // correct even if the user never taps anything in the app (this is what
        // heals a previously scheduled stale "already connected" reminder, and
        // keeps birthday reminders current as the pool changes).
        .task { await syncReminders() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await syncReminders() }
        }
    }

    private func syncReminders() async {
        // Fill in birthdays from Contacts first so anyone added before birthday
        // support (or whose card had no birthday at import) gets one — then the
        // reminder sync below can schedule for them.
        await backfillBirthdaysFromContacts()
        try? await NotificationsService.syncReminderIfNeeded(in: ctx)
        try? await NotificationsService.syncBirthdayReminders(in: ctx)
    }

    /// Backfills `birthday` from the address book for pool members who don't have
    /// one yet. This heals people imported before birthday support existed —
    /// their birthdays never got read from Contacts. User-set birthdays are left
    /// untouched (only nil ones are filled). No-ops without Contacts access.
    private func backfillBirthdaysFromContacts() async {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        guard status == .authorized || status == .limited else { return }

        // Which pool people are still missing a birthday, and their contact ids.
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.predicate = NSPredicate(format: "isInPool == YES AND birthday == nil")
        guard let people = try? ctx.fetch(request), !people.isEmpty else { return }

        let identifiers = people.compactMap { id -> String? in
            guard let identifier = id.contactIdentifier, !identifier.isEmpty else { return nil }
            return identifier
        }
        guard !identifiers.isEmpty else { return }

        // Read birthdays off the main thread.
        let birthdays = await Task.detached(priority: .utility) { () -> [String: Date] in
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [CNContactBirthdayKey as CNKeyDescriptor]

            var result: [String: Date] = [:]
            for identifier in identifiers {
                guard
                    let contact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys),
                    let date = Person.birthdayDate(from: contact.birthday)
                else { continue }
                result[identifier] = date
            }
            return result
        }.value

        guard !birthdays.isEmpty else { return }

        // Apply on the main context.
        var changed = false
        for person in people {
            guard
                let identifier = person.contactIdentifier,
                let date = birthdays[identifier]
            else { continue }
            person.birthday = date
            changed = true
        }

        if changed, ctx.hasChanges {
            try? ctx.save()
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !hasSeenOnboarding },
            set: { shouldShow in
                hasSeenOnboarding = !shouldShow
            }
        )
    }
}

private struct OnboardingView: View {
    let onStartSetup: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image("OnboardingHero")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to StayConnected")
                            .font(.system(.largeTitle, design: .serif).weight(.bold))
                            .foregroundStyle(Theme.brandGradient)

                        Text("A gentle nudge to reach out to the people who matter — no guilt, no busywork.")
                            .font(.title3)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }

                    onboardingCard(
                        title: "A few people a day, not a to-do list",
                        systemImage: "sparkles",
                        body: "Each day we suggest a small handful of people to reconnect with, so it stays light and easy to keep up."
                    )

                    onboardingCard(
                        title: "Set your own rhythm",
                        systemImage: "calendar",
                        body: "Choose how often you’d like to stay in touch with each person — close, regular, or occasional — and we surface whoever’s most overdue."
                    )

                    onboardingCard(
                        title: "Reaching out is the only step",
                        systemImage: "hand.wave.fill",
                        body: "Tap to call or message and it’s logged automatically. Busy day? Snooze anyone with a gentle “not today.”"
                    )

                    onboardingCard(
                        title: "Private by design",
                        systemImage: "lock.fill",
                        body: "Everything stays on your device. No account, no sign-up, and Contacts access only when you choose to add someone."
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Getting started")
                            .font(.headline)
                            .foregroundStyle(Theme.Palette.textPrimary)

                        Text("1. Add a few people you’d like to keep up with.")
                            .foregroundStyle(Theme.Palette.textSecondary)
                        Text("2. Open Home each day for who to reach out to.")
                            .foregroundStyle(Theme.Palette.textSecondary)
                        Text("3. Turn on a gentle daily reminder when you’re ready.")
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Theme.Palette.card)
                    )
                }
                .padding(24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .onAppear {
                guard !appeared else { return }
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(.easeOut(duration: 0.5)) { appeared = true }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button("Add Contacts") {
                        onStartSetup()
                    }
                    .buttonStyle(PrimaryPillButtonStyle())
                    .accessibilityHint("Takes you to your contact pool to start setup.")

                    Button("Explore First") {
                        onSkip()
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                    .accessibilityHint("Closes onboarding and keeps the app on the home tab.")
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .interactiveDismissDisabled()
        }
    }

    private func onboardingCard(
        title: String,
        systemImage: String,
        body: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.Palette.brand)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.textPrimary)

                Text(body)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 24)
        .accessibilityElement(children: .combine)
    }
}
