//
//  StayConnectedTests.swift
//  StayConnectedTests
//
//  Created by Anuj Patel on 8/27/25.
//

import CoreData
import Testing
@testable import StayConnected

struct StayConnectedTests {

    @MainActor
    @Test func todayViewModelGenerateTodayPicksPersistsAndReloadsSameIdentifiers() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let viewModel = TodayViewModel(context: context)
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 9))!

        let settings = try AppSettings.fetchOrCreate(in: context)
        settings.picksPerDay = 2
        settings.minGapDays = 7

        for index in 0..<3 {
            let person = Person(context: context)
            person.id = UUID()
            person.displayName = "Person \(index)"
            person.contactIdentifier = "person-\(index)"
            person.isInPool = true
            person.lastPickedAt = calendar.date(byAdding: .day, value: -(10 + index), to: now)
            person.lastCalledAt = calendar.date(byAdding: .day, value: -(20 + index), to: now)
        }

        try context.save()

        let generated = try viewModel.generateTodayPicks()
        let reloaded = try viewModel.loadTodayPicks()

        #expect(generated.count == 2)
        #expect(reloaded.map(\.contactIdentifier) == generated.map(\.contactIdentifier))
    }

    @MainActor
    @Test func monthRolloverResetsTimesPickedWhenMonthChanges() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let viewModel = TodayViewModel(context: context)

        // Force a stale "last month" so a rollover is guaranteed to run.
        UserDefaults.standard.set("1900-1", forKey: "lastMonthKey")

        let person = Person(context: context)
        person.id = UUID()
        person.displayName = "Rolls Over"
        person.contactIdentifier = "rolls-over"
        person.isInPool = true
        person.timesPickedThisMonth = 5
        try context.save()

        try viewModel.monthRolloverIfNeeded()

        #expect(person.timesPickedThisMonth == 0)
    }

    @MainActor
    @Test func setNoteStoresTrimmedTextAndClearsWhenEmpty() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let viewModel = TodayViewModel(context: context)

        let person = Person(context: context)
        person.id = UUID()
        person.displayName = "Noted"
        person.contactIdentifier = "noted"
        person.isInPool = true
        try context.save()

        try viewModel.setNote("  ask about her new job  ", forContactIdentifier: "noted")
        #expect(person.note == "ask about her new job")

        try viewModel.setNote("   ", forContactIdentifier: "noted")
        #expect(person.note == nil)
    }

    @MainActor
    @Test func selectionServiceRanksByOverdueRelativeToCadence() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9))!
        let service = SelectionService()

        // Close friend called 20 days ago: overdue (cadence 14).
        let close = Person(context: context)
        close.id = UUID()
        close.displayName = "Close"
        close.contactIdentifier = "close"
        close.isInPool = true
        close.contactCadence = .close
        close.lastCalledAt = calendar.date(byAdding: .day, value: -20, to: now)
        close.lastPickedAt = calendar.date(byAdding: .day, value: -20, to: now)

        // Occasional contact called 40 days ago: still on schedule (cadence 90).
        let occasional = Person(context: context)
        occasional.id = UUID()
        occasional.displayName = "Occasional"
        occasional.contactIdentifier = "occasional"
        occasional.isInPool = true
        occasional.contactCadence = .occasional
        occasional.lastCalledAt = calendar.date(byAdding: .day, value: -40, to: now)
        occasional.lastPickedAt = calendar.date(byAdding: .day, value: -40, to: now)

        let picks = service.pickToday(
            from: [occasional, close],
            picksPerDay: 1,
            minGapDays: 7,
            today: now
        )

        // Despite being called more recently in absolute terms, the close friend
        // is more overdue for *their* cadence and should be surfaced first.
        #expect(picks.map(\.contactIdentifier) == ["close"])
    }

    @MainActor
    @Test func selectionServiceSkipsSnoozedContacts() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9))!
        let service = SelectionService()

        let available = Person(context: context)
        available.id = UUID()
        available.displayName = "Available"
        available.contactIdentifier = "available"
        available.isInPool = true

        let snoozed = Person(context: context)
        snoozed.id = UUID()
        snoozed.displayName = "Snoozed"
        snoozed.contactIdentifier = "snoozed"
        snoozed.isInPool = true
        snoozed.snoozedUntil = calendar.date(byAdding: .day, value: 3, to: now)

        let picks = service.pickToday(
            from: [available, snoozed],
            picksPerDay: 2,
            minGapDays: 7,
            today: now
        )

        #expect(picks.map(\.contactIdentifier) == ["available"])
    }

    @MainActor
    @Test func snoozePickDefersPersonAndSwapsInReplacement() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let viewModel = TodayViewModel(context: context)

        let settings = try AppSettings.fetchOrCreate(in: context)
        settings.picksPerDay = 2
        settings.minGapDays = 7

        for index in 0..<3 {
            let person = Person(context: context)
            person.id = UUID()
            person.displayName = "Person \(index)"
            person.contactIdentifier = "person-\(index)"
            person.isInPool = true
        }
        try context.save()

        let generated = try viewModel.generateTodayPicks()
        #expect(generated.count == 2)

        let toSnooze = generated[0]
        let until = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let updated = try viewModel.snoozePick(toSnooze, until: until)

        // Still two picks, the snoozed person is gone, and a fresh one is in.
        #expect(updated.count == 2)
        #expect(!updated.contains { $0.objectID == toSnooze.objectID })
        #expect(toSnooze.isSnoozed(asOf: Date()))
    }

    @MainActor
    @Test func markCalledLogsOneEventPerContactPerDayButStillUpdatesState() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let viewModel = TodayViewModel(context: context)

        let person = Person(context: context)
        person.id = UUID()
        person.displayName = "Dedup"
        person.contactIdentifier = "dedup"
        person.isInPool = true
        try context.save()

        try viewModel.markCalled(person)
        try viewModel.markCalled(person)

        let request: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        request.predicate = NSPredicate(format: "contactIdentifier == %@", "dedup")
        let events = try context.fetch(request)

        // Only one connection is logged per contact per day...
        #expect(events.count == 1)
        // ...but the per-call state still updates each time.
        #expect(person.timesPickedThisMonth == 2)
        #expect(person.lastCalledAt != nil)
    }

    @MainActor
    @Test func resetTodayPicksClearsLastPickedSoContactsBecomeEligibleAgain() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let viewModel = TodayViewModel(context: context)

        let settings = try AppSettings.fetchOrCreate(in: context)
        settings.picksPerDay = 2
        settings.minGapDays = 20

        for index in 0..<2 {
            let person = Person(context: context)
            person.id = UUID()
            person.displayName = "Person \(index)"
            person.contactIdentifier = "person-\(index)"
            person.isInPool = true
        }
        try context.save()

        let generated = try viewModel.generateTodayPicks()
        #expect(generated.allSatisfy { $0.lastPickedAt != nil })

        try viewModel.resetTodayPicks()

        #expect(generated.allSatisfy { $0.lastPickedAt == nil })
        #expect(try DailyPick.fetchFor(date: Date(), in: context) == nil)
    }

    @Test func phoneLinkPreservesLeadingPlusForInternationalNumbers() {
        #expect(PhoneLink.normalize("+1 (502) 000-1111") == "+15020001111")
        #expect(PhoneLink.normalize("+44 20 7946 0958") == "+442079460958")
    }

    @Test func phoneLinkStripsFormattingFromDomesticNumbers() {
        #expect(PhoneLink.normalize("(502) 000-1111") == "5020001111")
        #expect(PhoneLink.normalize(" 502.000.1111 ") == "5020001111")
    }

    @Test func phoneLinkReturnsNilWhenNoDigits() {
        #expect(PhoneLink.normalize("") == nil)
        #expect(PhoneLink.normalize("no number") == nil)
    }

    @Test func phoneLinkBuildsTelAndSmsURLs() {
        #expect(PhoneLink.url(.tel, number: "+1 502 000 1111")?.absoluteString == "tel:+15020001111")
        #expect(PhoneLink.url(.sms, number: "502-000-1111")?.absoluteString == "sms:5020001111")
        #expect(PhoneLink.url(.tel, number: "abc") == nil)
    }

    @Test func catchUpReminderDateSchedulesThirtyMinutesAfterAMissedReminder() {
        let calendar = Calendar.current
        let reminderTime = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 10, minute: 0))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 13, minute: 15))!

        let catchUp = NotificationsService.catchUpReminderDate(
            reminderTime: reminderTime,
            now: now,
            calendar: calendar
        )

        let expected = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 13, minute: 45))!
        #expect(catchUp == expected)
    }

    @Test func catchUpReminderDateSkipsLateNightFollowUps() {
        let calendar = Calendar.current
        let reminderTime = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 10, minute: 0))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 20, minute: 10))!

        let catchUp = NotificationsService.catchUpReminderDate(
            reminderTime: reminderTime,
            now: now,
            calendar: calendar
        )

        #expect(catchUp == nil)
    }

    @MainActor
    @Test func selectionServicePrioritizesPinnedAndNeverContactedContacts() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9))!
        let service = SelectionService()

        let pinned = Person(context: context)
        pinned.id = UUID()
        pinned.displayName = "Pinned"
        pinned.contactIdentifier = "pinned"
        pinned.isInPool = true
        pinned.isPinned = true

        let neglected = Person(context: context)
        neglected.id = UUID()
        neglected.displayName = "Neglected"
        neglected.contactIdentifier = "neglected"
        neglected.isInPool = true
        neglected.lastCalledAt = calendar.date(byAdding: .day, value: -40, to: now)
        neglected.lastPickedAt = calendar.date(byAdding: .day, value: -20, to: now)

        let recent = Person(context: context)
        recent.id = UUID()
        recent.displayName = "Recent"
        recent.contactIdentifier = "recent"
        recent.isInPool = true
        recent.lastCalledAt = calendar.date(byAdding: .day, value: -2, to: now)
        recent.lastPickedAt = calendar.date(byAdding: .day, value: -20, to: now)

        let picks = service.pickToday(
            from: [recent, neglected, pinned],
            picksPerDay: 2,
            minGapDays: 7,
            today: now
        )

        #expect(picks.map(\.contactIdentifier) == ["pinned", "neglected"])
    }

    @MainActor
    @Test func selectionServiceKeepsEligibleContactsAheadOfFallbackContacts() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9))!
        let service = SelectionService()

        let eligible = Person(context: context)
        eligible.id = UUID()
        eligible.displayName = "Eligible"
        eligible.contactIdentifier = "eligible"
        eligible.isInPool = true
        eligible.lastCalledAt = calendar.date(byAdding: .day, value: -10, to: now)
        eligible.lastPickedAt = calendar.date(byAdding: .day, value: -10, to: now)

        let closeFallback = Person(context: context)
        closeFallback.id = UUID()
        closeFallback.displayName = "Close Fallback"
        closeFallback.contactIdentifier = "close-fallback"
        closeFallback.isInPool = true
        closeFallback.lastCalledAt = calendar.date(byAdding: .day, value: -20, to: now)
        closeFallback.lastPickedAt = calendar.date(byAdding: .day, value: -4, to: now)

        let farFallback = Person(context: context)
        farFallback.id = UUID()
        farFallback.displayName = "Far Fallback"
        farFallback.contactIdentifier = "far-fallback"
        farFallback.isInPool = true
        farFallback.lastCalledAt = calendar.date(byAdding: .day, value: -3, to: now)
        farFallback.lastPickedAt = calendar.date(byAdding: .day, value: -1, to: now)

        let picks = service.pickToday(
            from: [closeFallback, farFallback, eligible],
            picksPerDay: 2,
            minGapDays: 7,
            today: now
        )

        #expect(picks.map(\.contactIdentifier) == ["eligible", "close-fallback"])
    }

    @MainActor
    @Test func streaksCountCurrentAndLongestAcrossConsecutiveDays() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9))!
        let days = [0, -1, -2, -4, -5]

        for offset in days {
            let event = ConnectionEvent(context: context)
            event.id = UUID()
            event.contactIdentifier = "contact-\(offset)"
            event.contactNameSnapshot = "Person \(offset)"
            event.date = calendar.date(byAdding: .day, value: offset, to: now)
        }

        let request: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        let events = try context.fetch(request)
        let streaks = NotificationsService.streaks(from: events, calendar: calendar, today: now)

        #expect(streaks.current == 3)
        #expect(streaks.longest == 3)
    }

    @MainActor
    @Test func streaksResetCurrentWhenTodayAndYesterdayAreMissing() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9))!
        let days = [-2, -3, -4]

        for offset in days {
            let event = ConnectionEvent(context: context)
            event.id = UUID()
            event.contactIdentifier = "contact-\(offset)"
            event.contactNameSnapshot = "Person \(offset)"
            event.date = calendar.date(byAdding: .day, value: offset, to: now)
        }

        let request: NSFetchRequest<ConnectionEvent> = ConnectionEvent.fetchRequest()
        let events = try context.fetch(request)
        let streaks = NotificationsService.streaks(from: events, calendar: calendar, today: now)

        #expect(streaks.current == 0)
        #expect(streaks.longest == 3)
    }

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
