//
//  SettingsView.swift
//  StayConnected
//
//  Created by Anuj Patel on 8/28/25.
//

import CoreData
import SwiftUI
import UIKit

struct SettingsView: View {
    // MARK: - State

    @State private var showSavedToast = false
    @State private var showNotificationPermissionAlert = false
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

    private func successHaptic() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

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
                            .foregroundStyle(Color("TextPrimary"))

                        Text("Customize your experience")
                            .font(.title3)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    SettingsCard(title: "Call frequency") {
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

                    SettingsCard(title: "How picks work") {
                        Text("• Picks stay the same all day unless you reset them.")
                        Text("• We try to avoid repeats for at least \(viewModel.minGapDays) days.")
                        Text("• If your pool is too small, the gap rule may relax.")
                    }
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))

                    SettingsCard(title: "Pool size guidance") {
                        SettingsRow(
                            title: "Recommended pool size",
                            value: "\(viewModel.recommendedPoolSize)+"
                        )

                        SettingsRow(
                            title: "Rule of thumb",
                            value: "\(viewModel.minGapDays) days × \(viewModel.picksPerDay) picks/day"
                        )
                    }

                    SettingsCard(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Appearance", selection: $appearanceMode) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.segmented)

                            Text("Choose whether StayConnected follows your device appearance or always uses light or dark mode.")
                                .font(.footnote)
                                .foregroundStyle(Color("TextSecondary"))
                        }
                    }

                    SettingsCard(title: "Reminder") {
                        Toggle("Daily reminder", isOn: $viewModel.remindersEnabled)

                        DatePicker(
                            "Time",
                            selection: $viewModel.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .disabled(!viewModel.remindersEnabled)
                    }

                    Spacer(minLength: 90)
                }
                .padding()
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .task {
                try? viewModel.load()

                initialPicksPerDay = viewModel.picksPerDay
                initialMinGapDays = viewModel.minGapDays
                initialRemindersEnabled = viewModel.remindersEnabled
                initialReminderTime = viewModel.reminderTime
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button {
                        Task {
                            do {
                                try viewModel.save()
                                try viewModel.clearTodayIfNeeded()

                                if viewModel.remindersEnabled {
                                    let allowed = try await NotificationsService.requestPermissionIfNeeded()
                                    if allowed {
                                        try await NotificationsService.scheduleDailyReminder(
                                            at: viewModel.reminderTime
                                        )
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
                                    showSavedToast = true
                                    successHaptic()
                                    initialPicksPerDay = viewModel.picksPerDay
                                    initialMinGapDays = viewModel.minGapDays
                                    initialRemindersEnabled = viewModel.remindersEnabled
                                    initialReminderTime = viewModel.reminderTime
                                }
                            } catch {
                                // Optional: surface error later
                            }
                        }
                    } label: {
                        Text(hasChanges ? "Save Settings" : "Saved")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryPillButtonStyle())
                    .disabled(!hasChanges)
                    .opacity(hasChanges ? 1.0 : 0.6)

                    Text("Changes apply immediately.")
                        .font(.footnote)
                        .foregroundStyle(Color("TextSecondary"))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .alert("Saved", isPresented: $showSavedToast) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your settings have been saved.")
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
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))

            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color("Card"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("Divider").opacity(0.85), lineWidth: 1)
        )
    }
}

private struct SettingsRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(Color("TextPrimary"))
            Spacer()
            Text(value)
                .foregroundStyle(Color("TextSecondary"))
        }
        .font(.subheadline)
    }
}

#Preview {
    SettingsView(context: PersistenceController.shared.container.viewContext)
}
