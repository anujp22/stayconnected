import CoreData
import SwiftUI

// MARK: - App Tabs

enum AppTab: Hashable {
    // MARK: - Cases
    case home
    case pool
    case summary
    case settings
}

struct AppShellView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var ctx

    // MARK: - State
    @State private var selectedTab: AppTab = .home
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // MARK: - View
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            PoolView()
                .tabItem {
                    Label("Pool", systemImage: "person.2.fill")
                }
                .tag(AppTab.pool)

            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.summary)
            
            SettingsView(context: ctx)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(Color("BrandPrimary"))
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to StayConnected")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color("TextPrimary"))

                        Text("A gentle nudge to reach out to the people who matter — no guilt, no busywork.")
                            .font(.title3)
                            .foregroundStyle(Color("TextSecondary"))
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
                            .foregroundStyle(Color("TextPrimary"))

                        Text("1. Add a few people you’d like to keep up with.")
                            .foregroundStyle(Color("TextSecondary"))
                        Text("2. Open Home each day for who to reach out to.")
                            .foregroundStyle(Color("TextSecondary"))
                        Text("3. Turn on a gentle daily reminder when you’re ready.")
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color("Card"))
                    )
                }
                .padding(24)
            }
            .background(Color("Background").ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button("Add Contacts") {
                        onStartSetup()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .accessibilityHint("Takes you to your contact pool to start setup.")

                    Button("Explore First") {
                        onSkip()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
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
                .foregroundStyle(Color("BrandPrimary"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                Text(body)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color("Card"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color("Divider").opacity(0.85), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
