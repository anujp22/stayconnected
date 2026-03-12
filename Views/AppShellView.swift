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

                        Text("Build a small habit of reaching out to people who matter before life gets noisy.")
                            .font(.title3)
                            .foregroundStyle(Color("TextSecondary"))
                    }

                    onboardingCard(
                        title: "Daily picks, not a giant to-do list",
                        systemImage: "sparkles",
                        body: "We surface a short list each day so reconnecting feels light and sustainable."
                    )

                    onboardingCard(
                        title: "Your contacts stay under your control",
                        systemImage: "hand.raised.fill",
                        body: "StayConnected only asks for Contacts access when you choose to add people to your pool."
                    )

                    onboardingCard(
                        title: "Reminders work best after setup",
                        systemImage: "bell.badge.fill",
                        body: "Once your pool is ready, you can turn on a daily reminder in Settings with messaging that adapts to your progress."
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recommended first steps")
                            .font(.headline)
                            .foregroundStyle(Color("TextPrimary"))

                        Text("1. Add at least 10 contacts to your pool.")
                            .foregroundStyle(Color("TextSecondary"))
                        Text("2. Generate today’s picks.")
                            .foregroundStyle(Color("TextSecondary"))
                        Text("3. Turn on reminders after the first day.")
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
