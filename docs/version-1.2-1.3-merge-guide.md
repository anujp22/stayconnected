# StayConnected Version 1.2 and 1.3 Merge Guide

## Purpose

This document explains how Version 1.2 and Version 1.3 fit together, what features they introduce, and how to present or merge them as a coherent release sequence.

Version 1.2 improved the quality of the app’s core decision logic.

Version 1.3 improved how that logic is shared and consumed by the home screen.

The versions are related:

- Version 1.2 made the rules better
- Version 1.3 made the app use those rules more consistently

## High-Level Feature Summary

### New or improved behavior from Version 1.2

- smarter contact prioritization
- more reliable streak tracking
- more adaptive reminder scheduling
- lower summary-screen fetch overhead
- stronger test coverage around business rules

### New or improved behavior from Version 1.3

- shared daily-pick generation path across screens
- shared reset and mark-called behavior across screens
- fewer duplicate Core Data fetches on the home screen
- better home-screen refresh behavior when returning to the app
- stronger persistence coverage for the daily-pick flow

## Recommended Merge Order

### 1. Merge Version 1.2 first

Merge the Version 1.2 logic changes first because they define the behavior that Version 1.3 relies on.

Why:

- the updated `SelectionService` rules are foundational
- the shared streak logic in `NotificationsService` becomes the new source of truth
- summary performance and reminder timing changes are independent and stable

### 2. Merge Version 1.3 second

Merge Version 1.3 after 1.2 because it assumes the newer daily-pick and reminder behavior already exists and should be reused.

Why:

- it consolidates the home screen onto the existing domain logic
- it does not replace the 1.2 rules, it routes more of the app through them

## Merge Considerations

### 1. Version 1.3 is a structural follow-up to Version 1.2

If these are merged separately, the release notes should make that clear.

Version 1.2 is a feature-and-logic release.
Version 1.3 is a consistency-and-architecture release with some user-visible polish.

### 2. Watch for conflicts in the same files

The highest-conflict files are:

- `Services/NotificationsService.swift`
- `Services/SelectionService.swift`
- `ViewModels/TodayViewModel.swift`
- `Views/HomeView.swift`
- `Views/SummaryView.swift`
- `StayConnectedTests/StayConnectedTests.swift`

If there are branch conflicts, keep the newer shared-path behavior from Version 1.3 while preserving the behavioral rules introduced in Version 1.2.

### 3. Preserve tests during conflict resolution

The tests in these versions are not incidental. They are the safety net for the algorithm and refactor work.

If conflicts occur in `StayConnectedTests.swift`, do not drop the newer tests just to make the merge easier.

## Plain-Text Explanation of New Features

### Smarter picks

The app now makes better decisions about who should appear in today’s list. Pinned contacts, never-contacted people, and people who have gone a long time without a real connection are ranked more intelligently.

### Better streaks

The app now calculates streaks from one shared rule set instead of allowing different screens to interpret streaks differently.

### Better reminders

The reminder system still supports a regular daily reminder, but it can also schedule a same-day follow-up reminder when the user has already missed the original time and still has pending picks.

### Better summary behavior

The summary screen does less unnecessary work and refreshes more reliably after the app becomes active again.

### Better home-screen consistency

The home screen now relies on the same generation, reset, and call-logging logic used elsewhere in the app, which reduces drift and stale-state bugs.

## Engineering Explanation

### What changed conceptually in Version 1.2

Version 1.2 improved domain rules:

- better ranking inputs
- one streak implementation
- reminder logic that reacts to the user’s real state
- targeted tests around business decisions

### What changed conceptually in Version 1.3

Version 1.3 improved domain ownership:

- fewer duplicated flows in views
- more behavior routed through `TodayViewModel`
- fewer redundant fetches
- refresh behavior tied more closely to real app lifecycle events

## Suggested Release Framing

If these versions are described externally, a simple framing is:

### Version 1.2

“Improved the intelligence of daily picks, streak tracking, and reminder timing.”

### Version 1.3

“Improved consistency and reliability across the home screen by consolidating daily-pick behavior and reducing stale UI state.”

## Validation Checklist

After merge, verify these flows:

- generating picks from the home screen and today screen yields the same persisted result
- resetting picks from the home screen clears the saved `DailyPick`
- marking a connection updates streak-sensitive reminder logic
- summary streak values match reminder streak-sensitive behavior
- catch-up reminders are only scheduled when the normal reminder time has already passed and the user still has work left

## Final Takeaway

These two versions should be understood together.

Version 1.2 improved decision quality.
Version 1.3 improved consistency of execution.

That combination is the important outcome. The app is not just doing more. It is doing its core work with fewer conflicting code paths and with better test support.
