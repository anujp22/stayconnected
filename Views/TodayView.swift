//
//  TodayView.swift
//  StayConnected
//
//  Created by Anuj Patel on 8/28/25.
//

import CoreData
import SwiftUI

struct TodayView: View {
    // MARK: - State

    @StateObject private var viewModel: TodayViewModel
    @State private var showResetConfirm = false
    @State private var poolIsEmpty = false

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TodayViewModel(context: context))
    }

    // MARK: - View

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // ✅ Picks for Today (date)
                Text("Picks for \(Date(), format: .dateTime.month(.abbreviated).day().year())")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let warning = viewModel.warningText {
                    Text(warning)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // ✅ Empty pool CTA
                if poolIsEmpty {
                    Spacer()
                    Image(systemName: "person.3")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)

                    Text("Your pool is empty")
                        .font(.title3)
                        .bold()

                    Text("Go to Pool and turn on a few people first.")
                        .foregroundStyle(.secondary)

                    // If you’re using TabView, user can tap Pool tab; this button just reminds them.
                    Button("Go to Pool") { }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    Spacer()
                } else {
                    if viewModel.todayPicks.isEmpty {
                        Text("No picks yet. Tap Generate.")
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                    } else {
                        List(viewModel.todayPicks, id: \.objectID) { person in
                            HStack(spacing: 12) {
                                ContactAvatarView(contactIdentifier: person.contactIdentifier ?? "")

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.displayName ?? "Unknown")
                                        .font(.headline)

                                    if let last = person.lastCalledAt {
                                        Text("Last called \(last, format: .relative(presentation: .named))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                                Spacer()

                                Button {
                                    viewModel.call(person)
                                } label: {
                                    Image(systemName: "phone.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)

                                Button("Called") {
                                    try? viewModel.markCalled(person)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.insetGrouped)
                    }

                    HStack(spacing: 12) {
                        Button {
                            try? viewModel.monthRolloverIfNeeded()
                            try? viewModel.loadOrGenerateToday()
                        } label: {
                            Label("Generate", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
            }
            .navigationTitle("Today’s Calls")
            .alert(
                "Reset today’s picks?", isPresented: $showResetConfirm
            ) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    do {
                        try viewModel.resetTodayPicks()
                        try viewModel.loadOrGenerateToday()
                    } catch {
                        // Intentionally left blank.
                    }
                }
            } message: {
                Text("This will replace today’s picks with a new set.")
            }
            .task {
                // On open: rollover, check pool size, load or generate
                try? viewModel.monthRolloverIfNeeded()

                let count = (try? viewModel.poolCount()) ?? 0
                poolIsEmpty = (count == 0)

                if !poolIsEmpty {
                    try? viewModel.loadOrGenerateToday()
                }
            }
        }
    }
}

#Preview {
    TodayView(context: PersistenceController.shared.container.viewContext)
}
