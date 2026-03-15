# StayConnected Version 1.3 Guide

## Purpose

Version 1.3 built on Version 1.2 by cleaning up the daily-pick flow used by the home screen. The main problem addressed here was duplication: `HomeView` was still performing several of the same data operations already handled elsewhere in the app.

This version focused on consolidation, stale-state reduction, and lightweight home-screen performance improvements.

## Files Changed

- `ViewModels/TodayViewModel.swift`
- `Views/HomeView.swift`
- `StayConnectedTests/StayConnectedTests.swift`

## What Changed

### 1. Shared daily-pick flow for Home and Today

Before Version 1.3, `HomeView` still handled several core operations directly:

- reading today’s saved picks
- generating new daily picks
- resetting today’s picks
- marking a pick as called

Those actions overlapped with `TodayViewModel`, which already owned the same domain behavior for the Today screen.

Version 1.3 moved the shared behavior behind `TodayViewModel` so the home screen now calls into one common code path.

That reduces the chance of:

- different screens applying different generation rules
- reminder sync behavior getting out of step
- reset behavior changing in one screen but not another
- call logging behavior diverging over time

### 2. Expanded `TodayViewModel` API

To support that consolidation, `TodayViewModel` gained a few narrow helper methods:

- `loadTodayPicks()`
- `generateTodayPicks()`
- `person(for:)`

It also extracted the internal shared generation work into a private helper so existing and new callers can reuse the same persistence behavior.

This is a small but important design step. The view model became a reusable domain coordinator instead of only being a screen-local helper.

### 3. Home screen refresh improvements

`HomeView` now refreshes when the app returns to the foreground, not just on initial appearance or tab reselection.

That helps if:

- the user interacts with another tab and comes back
- the app was backgrounded after activity changed
- notifications or connection state changed outside the current home view lifecycle

### 4. Reduced redundant fetch work

`HomeView` no longer reloads each `Person` individually after already loading today’s saved picks from the shared flow.

It now:

- loads the `Person` objects once through `TodayViewModel`
- builds `HomePick` values from those objects
- still fetches phone numbers separately from Contacts because that data does not live in Core Data

Monthly progress was also tightened:

- it now uses `count(for:)` instead of fetching every monthly `ConnectionEvent`

This is a direct performance cleanup. The screen only needs the number of matching rows, so there is no reason to materialize all event objects.

### 5. Additional test coverage

Version 1.3 added a test for the shared generation path:

- generate today’s picks
- persist them
- reload them
- confirm the identifiers match

This test matters because the core risk in the refactor was not UI rendering. The risk was persistence consistency across screens.

## Concepts Used

### Single source of truth

Version 1.3 is primarily about this concept.

If two screens can generate, reset, or mutate the same daily-pick state, that behavior should not be reimplemented independently in each screen. It should be routed through one domain layer so the app behaves the same no matter where the user triggers the action.

### Incremental refactoring

The version does not introduce a brand-new architecture. It takes an existing view model and broadens it slightly to support a second caller. That is a safer refactor because it:

- minimizes file churn
- preserves existing mental models
- reduces regression risk

### Count queries over full fetches

When a screen only needs a total, `count(for:)` is more appropriate than fetching all matching objects. That lowers memory work and avoids needless object materialization.

## Code-Level Summary

### `ViewModels/TodayViewModel.swift`

- added `loadTodayPicks()`
- added public `generateTodayPicks()`
- added `person(for:)`
- extracted private shared generation helper
- preserved notification syncing and daily-pick persistence in one place

### `Views/HomeView.swift`

- switched generate/reset/mark-called flows to use `TodayViewModel`
- removed duplicate local data mutation logic
- built home pick models from already-loaded `Person` values
- refreshed when the scene becomes active
- changed monthly progress calculation to use `count(for:)`

### `StayConnectedTests/StayConnectedTests.swift`

- added a test that verifies generated picks are persisted and reloaded consistently

## Why This Version Matters

Version 1.3 is less about visible product features and more about keeping the app coherent as it grows.

The user-facing result is a home screen that behaves more reliably and updates more predictably. The engineering result is more important long-term:

- one generation path
- one reset path
- one call-logging path
- lower drift risk between screens

That makes later versions easier to extend, because new work can build on shared behavior instead of duplicating it again.
