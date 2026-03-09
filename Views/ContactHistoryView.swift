//
//  ContactHistoryView.swift
//  StayConnected
//
//  Created by Anuj Patel on 3/7/26.
//

import SwiftUI
import CoreData

struct ContactHistoryView: View {
    @Environment(\.managedObjectContext) private var context

    let person: Person

    @State private var events: [ConnectionEvent] = []

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Name")
                        .foregroundStyle(Color("TextPrimary"))
                    Spacer()
                    Text(person.displayName ?? "Unknown")
                        .foregroundStyle(Color("TextSecondary"))
                }

                HStack {
                    Text("Last Connected")
                        .foregroundStyle(Color("TextPrimary"))
                    Spacer()
                    if let lastCalledAt = person.lastCalledAt {
                        Text(lastCalledAt.formatted(.dateTime.month().day().year()))
                            .foregroundStyle(Color("TextSecondary"))
                    } else {
                        Text("Never")
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }

                HStack {
                    Text("Total Connections")
                        .foregroundStyle(Color("TextPrimary"))
                    Spacer()
                    Text("\(events.count)")
                        .foregroundStyle(Color("TextSecondary"))
                }
            }
            .listRowBackground(Color("Card"))

            Section {
                Text("History")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                if events.isEmpty {
                    Text("No connection history yet.")
                        .foregroundStyle(Color("TextSecondary"))
                } else {
                    ForEach(events, id: \.objectID) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.date?.formatted(.dateTime.month().day().year().hour().minute()) ?? "Unknown date")
                                .font(.subheadline)
                                .foregroundStyle(Color("TextPrimary"))

                            Text("Marked as called")
                                .font(.caption)
                                .foregroundStyle(Color("TextSecondary"))
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .listRowBackground(Color("Card"))
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .navigationTitle(person.displayName ?? "History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshEvents()
        }
    }

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

#Preview {
    Text("ContactHistoryView preview requires a Person instance.")
}
