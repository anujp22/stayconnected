import CoreData
import SwiftUI

struct ContactHistoryView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var context

    // MARK: - Properties
    let person: Person

    // MARK: - State
    @State private var events: [ConnectionEvent] = []

    // MARK: - View
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                profileCard

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
        }
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
