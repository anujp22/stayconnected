# StayConnected Version 1.2 Guide

## Purpose

Version 1.2 focused on improving the quality of daily picks, making streak tracking more reliable, improving reminder timing, and reducing unnecessary work in the summary screen. The work stayed intentionally narrow: the goal was to improve behavior without broad architectural churn.

## Files Changed

- `Services/NotificationsService.swift`
- `Services/SelectionService.swift`
- `Views/SummaryView.swift`
- `StayConnectedTests/StayConnectedTests.swift`

## What Changed

### 1. Smarter contact prioritization

The pick algorithm in `SelectionService` was refined so it better reflects actual relationship maintenance goals.

The selection rules now favor:

- pinned contacts before non-pinned contacts
- never-contacted contacts before already-contacted contacts
- people who have gone longer without a real connection
- people who have been picked less often this month
- people who have not been surfaced recently

The fallback behavior also changed. In the earlier flow, if there were not enough fully eligible contacts, fallback candidates could effectively replace the eligible set. In Version 1.2, eligible contacts stay at the front of the result, and fallback contacts are only used to fill the remaining slots.

There is still a small amount of randomness, but it only applies to the lower-priority tail. The highest-ranked contacts remain stable.

### 2. Shared streak logic

Before Version 1.2, streak logic lived in more than one place. That creates drift risk: the summary screen and reminder system can disagree about what the current streak actually is.

Version 1.2 moved streak calculation into `NotificationsService.streaks(...)` and made both reminders and the summary screen use the same implementation.

This improved:

- consistency of current streak values
- consistency of longest streak values
- correctness around the “today or yesterday” rule that determines whether a current streak is still alive

### 3. Reminder timing improvements

The daily repeating reminder remained in place, but the notification service gained a second concept: a same-day catch-up reminder.

If all of the following are true:

- reminders are enabled
- the user has already missed today’s configured reminder time
- the user still has pending picks
- the user has not completed a connection today
- it is not too late in the evening

the app can schedule a one-time catch-up reminder for later that same day.

This was added to improve practical reminder usefulness without turning the app into an aggressive notification system.

### 4. Summary screen polish and performance

`SummaryView` previously did extra Core Data lookups while rendering recent activity rows. That is unnecessary because the screen already has enough data to build a local lookup table.

Version 1.2 changed the summary flow so it:

- builds a dictionary of `Person` records keyed by contact identifier
- reuses that in the recent activity list
- refreshes when the app becomes active

This reduces per-row fetch work and makes the summary more likely to stay current after actions taken elsewhere in the app.

### 5. Test coverage improvements

Version 1.2 added tests for:

- current and longest streak calculation
- catch-up reminder time selection
- pinned and neglected contact prioritization
- preserving eligible contacts ahead of fallback contacts

This matters because the version introduced more decision logic than UI logic. The risky parts were algorithmic, so the tests were added where they provide the most value.

## Concepts Used

### Deterministic ranking with controlled randomness

The contact picker now uses deterministic ranking for the strongest candidates and only keeps light randomness in the lower-priority remainder. This is a common product compromise:

- deterministic enough to make quality predictable
- random enough to avoid the app feeling repetitive

### Shared domain logic

A repeated rule, like streak calculation, should live in one place. If the same business concept is defined in multiple views or services, it will eventually diverge.

Version 1.2 corrected that by making the notification service the owner of streak evaluation.

### Fetch less, reuse more

The summary changes are a straightforward performance principle. If a screen already fetched the data needed to derive a lookup structure, do that once and reuse it instead of asking Core Data again for every row.

## Code-Level Summary

### `Services/SelectionService.swift`

- expanded `Candidate` metadata
- added `isPinned` and `timesPickedThisMonth` to ranking
- separated eligible candidates from fallback candidates
- preserved eligible picks ahead of fallback picks
- kept only limited randomness in the tail

### `Services/NotificationsService.swift`

- added `catchUpReminderIdentifier`
- added `catchUpReminderDate(...)`
- added one-time catch-up scheduling
- unified streak calculation in `streaks(...)`
- updated reminder syncing to schedule both repeating and same-day reminder behavior when needed

### `Views/SummaryView.swift`

- removed duplicate streak implementation
- reused `NotificationsService.streaks(...)`
- cached people by identifier for recent activity
- refreshed on app activation

### `StayConnectedTests/StayConnectedTests.swift`

- added streak tests
- added reminder timing tests
- added prioritization tests

## Why This Version Matters

Version 1.2 improved trust in the app’s core loop.

The user-facing outcomes are:

- better daily picks
- more believable streaks
- reminders that react more intelligently
- a summary screen that is less likely to lag or disagree with the rest of the app

From an engineering perspective, the important part is not just the features. It is that the logic became more centralized and easier to test.
