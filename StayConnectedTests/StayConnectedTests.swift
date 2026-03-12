//
//  StayConnectedTests.swift
//  StayConnectedTests
//
//  Created by Anuj Patel on 8/27/25.
//

import Testing
@testable import StayConnected

struct StayConnectedTests {

    @MainActor
    @Test func reminderPreviewPromptsSetupWhenPoolIsEmpty() throws {
        let context = PersistenceController(inMemory: true).container.viewContext

        let preview = try NotificationsService.reminderPreview(in: context)

        #expect(preview.title == "Build your pool first")
    }

    @MainActor
    @Test func reminderPreviewAcknowledgesCompletedConnectionToday() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let person = Person(context: context)
        person.id = UUID()
        person.contactIdentifier = "contact-1"
        person.displayName = "Taylor"
        person.isInPool = true

        let event = ConnectionEvent(context: context)
        event.id = UUID()
        event.contactIdentifier = "contact-1"
        event.contactNameSnapshot = "Taylor"
        event.date = Date()

        try context.save()

        let preview = try NotificationsService.reminderPreview(in: context)

        #expect(preview.title == "You’re all set for today")
    }

}
