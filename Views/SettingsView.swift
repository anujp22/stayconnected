import CoreData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context

    // MARK: - State

    @State private var showSavedToast = false
    @State private var showNotificationPermissionAlert = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var initialPicksPerDay: Int = 1
    @State private var initialMinGapDays: Int = 7
    @State private var initialRemindersEnabled: Bool = false
    @State private var initialReminderTime: Date = .now
    @StateObject private var viewModel: SettingsViewModel
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    // MARK: - Derived Values

    private var hasChanges: Bool {
        (
            initialPicksPerDay != viewModel.picksPerDay
            || initialMinGapDays != viewModel.minGapDays
            || initialRemindersEnabled != viewModel.remindersEnabled
            || Calendar.current.compare(
                initialReminderTime,
                to: viewModel.reminderTime,
                toGranularity: .minute
            ) != .orderedSame
        )
    }

    // MARK: - Private Helpers

    private func successHaptic() { Haptics.success() }

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(context: context))
    }

    // MARK: - View

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.Palette.textPrimary)

                        Text("Customize your experience")
                            .font(.title3)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    SettingsCard(title: "Call frequency", systemImage: "slider.horizontal.3") {
                        Stepper(
                            "Picks per day: \(viewModel.picksPerDay)",
                            value: $viewModel.picksPerDay,
                            in: 1...3
                        )

                        Divider().opacity(0.2)

                        Stepper(
                            "Minimum gap (days): \(viewModel.minGapDays)",
                            value: $viewModel.minGapDays,
                            in: 7...60
                        )
                    }

                    SettingsCard(title: "How picks work", systemImage: "info.circle") {
                        Text("• Picks stay the same all day unless you reset them.")
                        Text("• We try to avoid repeats for at least \(viewModel.minGapDays) days.")
                        Text("• If your pool is too small, the gap rule may relax.")
                    }
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.textSecondary)

                    SettingsCard(title: "Pool size guidance", systemImage: "person.2") {
                        SettingsRow(
                            title: "Recommended pool size",
                            value: "\(viewModel.recommendedPoolSize)+"
                        )

                        SettingsRow(
                            title: "Rule of thumb",
                            value: "\(viewModel.minGapDays) days × \(viewModel.picksPerDay) picks/day"
                        )
                    }

                    SettingsCard(title: "Appearance", systemImage: "paintbrush") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Appearance", selection: $appearanceMode) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.segmented)

                            Text("Choose whether StayConnected follows your device appearance or always uses light or dark mode.")
                                .font(.footnote)
                                .foregroundStyle(Theme.Palette.textSecondary)
                        }
                    }

                    SettingsCard(title: "Reminder", systemImage: "bell") {
                        Toggle("Daily reminder", isOn: $viewModel.remindersEnabled)
                            .accessibilityHint("Enable a notification that reflects your current progress for the day.")

                        DatePicker(
                            "Time",
                            selection: $viewModel.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .disabled(!viewModel.remindersEnabled)
                        .accessibilityHint("Choose when StayConnected should remind you each day.")

                        Divider().opacity(0.2)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.Palette.textPrimary)

                            NotificationPreviewBubble(
                                title: viewModel.reminderPreviewTitle,
                                message: viewModel.reminderPreviewBody
                            )
                        }
                    }

                    Spacer(minLength: 90)
                }
                .padding()
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    try viewModel.load()

                    initialPicksPerDay = viewModel.picksPerDay
                    initialMinGapDays = viewModel.minGapDays
                    initialRemindersEnabled = viewModel.remindersEnabled
                    initialReminderTime = viewModel.reminderTime
                } catch {
                    errorMessage = "Couldn’t load your settings. Default values are shown."
                    showError = true
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button {
                        Task {
                            do {
                                try viewModel.save()
                                try viewModel.clearTodayIfNeeded()
                                try viewModel.refreshReminderPreview()

                                if viewModel.remindersEnabled {
                                    let allowed = try await NotificationsService.requestPermissionIfNeeded()
                                    if allowed {
                                        try await NotificationsService.syncReminderIfNeeded(in: context)
                                        try viewModel.refreshReminderPreview()
                                        showSavedToast = true
                                        successHaptic()
                                        initialPicksPerDay = viewModel.picksPerDay
                                        initialMinGapDays = viewModel.minGapDays
                                        initialRemindersEnabled = viewModel.remindersEnabled
                                        initialReminderTime = viewModel.reminderTime
                                    } else {
                                        viewModel.remindersEnabled = false
                                        try viewModel.save()
                                        await NotificationsService.cancelDailyReminder()
                                        try viewModel.refreshReminderPreview()
                                        showSavedToast = true
                                        showNotificationPermissionAlert = true
                                        successHaptic()
                                        initialPicksPerDay = viewModel.picksPerDay
                                        initialMinGapDays = viewModel.minGapDays
                                        initialRemindersEnabled = viewModel.remindersEnabled
                                        initialReminderTime = viewModel.reminderTime
                                    }
                                } else {
                                    await NotificationsService.cancelDailyReminder()
                                    try viewModel.refreshReminderPreview()
                                    showSavedToast = true
                                    successHaptic()
                                    initialPicksPerDay = viewModel.picksPerDay
                                    initialMinGapDays = viewModel.minGapDays
                                    initialRemindersEnabled = viewModel.remindersEnabled
                                    initialReminderTime = viewModel.reminderTime
                                }
                            } catch {
                                errorMessage = "Couldn’t save your settings. Please try again."
                                showError = true
                            }
                        }
                    } label: {
                        Text(hasChanges ? "Save Settings" : "Saved")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryPillButtonStyle())
                    .disabled(!hasChanges)
                    .opacity(hasChanges ? 1.0 : 0.6)
                    .accessibilityHint("Save your current frequency, reminder, and appearance preferences.")

                    Text("Changes apply immediately.")
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .alert("Saved", isPresented: $showSavedToast) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your settings have been saved.")
            }
            .alert("Something Went Wrong", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
            .alert("Notifications Disabled", isPresented: $showNotificationPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Daily reminders are turned off in iOS Settings. Enable notifications for StayConnected to receive reminders.")
            }
            .onChange(of: viewModel.remindersEnabled) { _, _ in
                try? viewModel.refreshReminderPreview()
            }
            .onChange(of: viewModel.reminderTime) { _, _ in
                try? viewModel.refreshReminderPreview()
            }
        }
    }

}

// MARK: - Subviews

private struct SettingsCard<Content: View>: View {
    // MARK: - Properties
    let title: String
    var systemImage: String? = nil
    @ViewBuilder var content: Content

    // MARK: - View
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Palette.brand)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.textPrimary)
            }

            content
        }
        .padding()
        .cardSurface(radius: 20)
    }
}

/// A mock iOS notification banner so users see roughly what the daily reminder
/// will look like on their lock screen — app icon, title, and body on a
/// material card.
private struct NotificationPreviewBubble: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Theme.brandGradient)
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("StayConnected")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Spacer()
                    Text("now")
                        .font(.caption2)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }

                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(1)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.Palette.divider.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notification preview. \(title). \(message)")
    }
}

private struct SettingsRow: View {
    // MARK: - Properties
    let title: String
    let value: String

    // MARK: - View
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
            Text(value)
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Preview
#Preview {
    SettingsView(context: PersistenceController.shared.container.viewContext)
}
