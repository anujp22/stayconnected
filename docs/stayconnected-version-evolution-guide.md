# StayConnected Version Evolution Guide

## Purpose

This document explains how the StayConnected app evolved across the versions we have discussed:

- the initial version
- Version 1.1
- Version 1.2
- Version 1.3

It also explains how each version connects back to the current `main` branch and how the later versions should be understood as layers on top of the earlier work.

## Important Repository Note

The repository has a `v1.0` tag, but it does not have a separate `v1.1` tag.

Because of that, this document uses the following interpretation:

- `Initial Version` = the app around the `v1.0` baseline
- `Version 1.1` = the current `main` branch state after `v1.0`
- `Version 1.2` = the uncommitted feature work added on top of `main`
- `Version 1.3` = the uncommitted follow-up refactor and home-screen consistency work added on top of Version 1.2

This is the most accurate way to explain the code that actually exists in this repository.

## The Big Picture

The app evolved in four stages:

### 1. Initial Version

The app established the core product idea:

- keep a pool of important people
- generate a few daily picks
- log connection activity
- track progress over time

This was the foundational product.

### 2. Version 1.1

The app became more polished and more complete as a real user product:

- onboarding was added
- the pool workflow became richer
- reminder preview and setup became more visible
- settings became more user-friendly
- the home and shell experience improved

This was the “product maturity” step.

### 3. Version 1.2

The app became smarter and more internally consistent:

- better contact prioritization
- shared streak rules
- improved reminder timing
- summary performance cleanup
- stronger tests for business logic

This was the “behavior quality” step.

### 4. Version 1.3

The app became more consistent in how screens use the same business rules:

- the home screen stopped duplicating daily-pick logic
- more behavior flowed through `TodayViewModel`
- redundant fetches were reduced
- home refresh behavior became more reliable

This was the “shared domain flow” step.

## Version-by-Version Breakdown

## Initial Version

### What the app already had

At the initial stage, the app already had the central product loop:

- contact pool management
- daily pick generation
- call or connection logging
- summary statistics
- settings for pick count and minimum gap

Architecturally, the app already used a clean SwiftUI split:

- `Views`
- `ViewModels`
- `Models`
- `Services`

That is important because later versions did not need to invent the architecture. They were able to improve behavior inside an existing structure.

### What this version meant conceptually

The initial version answered the product question:

“Can this app help someone maintain meaningful relationships through small daily actions?”

The answer was yes. The app already had the base mechanics needed for that habit loop.

### Its relationship to current `main`

The initial version is the foundation of everything on `main`.

Nothing later replaces the original idea. Later versions mostly:

- improve the workflow
- improve the heuristics
- improve polish
- reduce duplication

## Version 1.1

## How Version 1.1 is defined here

Because there is no explicit `v1.1` tag, this guide treats the current `main` branch after `v1.0` as the Version 1.1 stage.

Git history supports that interpretation:

- `v1.0` marks the earlier baseline
- later commits on `main` introduce onboarding, reminder-related UX, code cleanup, and bug fixes

### Major improvements in Version 1.1

Based on the code in `main`, Version 1.1 added or improved the following areas.

### 1. Onboarding and first-run guidance

`AppShellView` now includes a full-screen onboarding flow.

This changed the app from “tools are present” to “the app actively helps the user get started.”

The onboarding explains:

- what daily picks are
- why reminders matter
- why the pool setup comes first

This is a product usability improvement, not just UI decoration.

### 2. Better pool management

The pool screen became much more capable and interactive.

The user can now more naturally:

- search contacts
- pin or unpin people
- remove people from the pool
- add contacts from the picker
- connect directly from the pool screen

This matters because the pool is the input to the entire daily-pick algorithm. Better pool management improves the quality of all later behavior.

### 3. Better settings and reminder setup

Settings evolved from simple preferences into a more guided configuration surface.

The screen now helps the user understand:

- how picks work
- what a reasonable pool size is
- how reminders behave
- what the reminder message preview looks like

This makes the app less opaque. The user can understand the rules instead of just changing numbers blindly.

### 4. Better app shell and tab-level experience

The shell and top-level navigation became more product-like:

- onboarding in the app shell
- clearer tab structure
- better screen transitions for early setup

### 5. Home and general UI polish

The mainline version also improved the presentation of home and related screens so the app feels more like a finished consumer app and less like a first functional prototype.

### What Version 1.1 meant conceptually

Version 1.1 was the step where the app became easier to adopt and easier to understand.

The initial version proved the product idea.
Version 1.1 improved the user journey around that idea.

### How Version 1.1 connects to `main`

Version 1.1 is effectively the current `main` baseline in this repository.

That means:

- if someone checks out `main`, they are already getting the Version 1.1 state
- Versions 1.2 and 1.3 should be understood as additions on top of this baseline

## Version 1.2

### What Version 1.2 added

Version 1.2 focused on business logic quality and internal consistency.

The key improvements were:

- smarter contact prioritization
- unified streak calculation
- improved reminder timing
- summary performance cleanup
- stronger automated tests

### 1. Smarter contact prioritization

The ranking logic in `SelectionService` became more intentional.

The app now prioritizes:

- pinned contacts
- never-contacted contacts
- contacts who have gone longest since a real connection
- contacts that have been picked less often this month

It also preserves eligible contacts first and only uses fallback contacts to fill remaining slots.

This changed the picker from “good enough rotation” into something closer to a relationship-priority engine.

### 2. Shared streak logic

Version 1.2 centralized streak calculation in `NotificationsService`.

That removed a major class of inconsistency:

- the summary screen and reminder system now agree on streak rules

This is important because streaks are user-facing trust features. If different parts of the app disagree, the app feels unreliable.

### 3. Notification timing improvements

Version 1.2 kept the regular reminder but added the concept of a same-day catch-up reminder.

This allows the app to react better when:

- the original reminder time has already passed
- the user still has pending picks
- no connection has been logged yet

This made reminders more context-aware without making them noisy.

### 4. Summary performance and refresh cleanup

`SummaryView` was improved so it:

- avoids repeated per-row Core Data fetches
- builds local lookup structures once
- refreshes when the app becomes active

This is partly performance work and partly stale-state protection.

### 5. Test expansion

Version 1.2 added tests for the important logic paths:

- streak behavior
- reminder timing
- pick ordering
- fallback ordering

### What Version 1.2 meant conceptually

Version 1.2 improved the decision quality of the app.

If Version 1.1 made the app easier to use, Version 1.2 made the app’s decisions more believable and more consistent.

### How Version 1.2 connects to Version 1.1 and `main`

Version 1.2 is not a replacement for `main`.
It is a refinement layer on top of the current `main` baseline.

That means:

- onboarding, pool UX, and settings guidance from Version 1.1 remain important
- Version 1.2 makes the underlying logic behind those screens stronger

Put simply:

- Version 1.1 improved the product shell
- Version 1.2 improved the engine inside that shell

## Version 1.3

### What Version 1.3 added

Version 1.3 focused on reducing duplication and making the home screen use the same domain logic as the rest of the app.

The key improvements were:

- shared daily-pick loading and generation path
- shared reset and mark-called path
- reduced duplicate fetches in `HomeView`
- better refresh behavior on foreground return
- added persistence coverage for the shared generation path

### 1. Shared daily-pick logic

Before Version 1.3, `HomeView` still duplicated several operations that already existed elsewhere.

Version 1.3 moved the home screen onto the shared `TodayViewModel` flow for:

- loading today’s picks
- generating picks
- resetting picks
- marking a pick as called

This is one of the most important long-term code quality improvements in the sequence.

### 2. Expanded `TodayViewModel`

The view model gained a few public helpers so it could act as a reusable domain entry point instead of being only screen-specific.

This is a controlled refactor:

- no large architecture rewrite
- no unnecessary new abstraction layer
- just enough API surface to make shared behavior possible

### 3. Home screen refresh and fetch cleanup

The home screen now:

- refreshes when the app becomes active
- builds its UI from already-loaded `Person` values
- uses `count(for:)` for monthly totals instead of loading all objects

This improves both correctness and efficiency.

### 4. Test coverage for shared persistence behavior

Version 1.3 added a test that generates daily picks and verifies that the persisted identifiers match when reloaded.

This is important because the change was a refactor of shared state behavior, and persistence correctness is the main risk in that kind of work.

### What Version 1.3 meant conceptually

Version 1.3 improved execution consistency.

If Version 1.2 improved the quality of the rules, Version 1.3 improved how reliably different screens obey those same rules.

### How Version 1.3 connects to Version 1.2, Version 1.1, and `main`

Version 1.3 depends on the improvements introduced before it.

It makes the most sense as:

- Version 1.1 = better product shell
- Version 1.2 = better business logic
- Version 1.3 = better reuse of that logic across screens

That means Version 1.3 is best understood as a structural follow-up to Version 1.2, not as a separate feature island.

## How All Versions Connect to `main`

## Current `main`

Current `main` is effectively the Version 1.1 baseline.

It already includes:

- onboarding
- stronger pool management
- settings guidance
- reminder preview setup
- UI polish and bug fixes after `v1.0`

## How Version 1.2 connects to `main`

Version 1.2 should be merged into `main` as an improvement to:

- selection quality
- streak consistency
- reminder quality
- summary reliability

It complements `main` without changing the app’s overall structure.

## How Version 1.3 connects to `main`

Version 1.3 should be merged after Version 1.2 because it assumes the newer logic should be shared rather than duplicated.

It improves:

- consistency between screens
- maintainability
- reduced stale-state risk on the home screen

## The cleanest interpretation

The cleanest way to explain the codebase is:

- `main` already contains the product improvements that we are calling Version 1.1
- Version 1.2 improves the intelligence and reliability of the app’s logic
- Version 1.3 improves how the app reuses that logic

## What Changed in Product Terms

If you want a plain-language summary without code terms, this is the shortest accurate explanation:

### Initial Version

The app could already generate daily relationship reminders and track progress.

### Version 1.1

The app became easier to use, easier to configure, and easier for a new user to understand.

### Version 1.2

The app got better at deciding who to surface, better at calculating streaks, and better at reminding the user at meaningful times.

### Version 1.3

The app became more internally consistent so different screens behave the same way and the home screen stays fresher and more efficient.

## What Changed in Engineering Terms

### Initial Version

- core architecture and product loop established

### Version 1.1

- stronger UX and workflow framing
- richer pool management
- onboarding and settings maturity

### Version 1.2

- stronger business rules
- shared streak logic
- expanded test coverage for decision-making code

### Version 1.3

- reduced duplication
- shared state flow through `TodayViewModel`
- lighter home-screen fetch path

## Recommended Mental Model

Use this model when thinking about the codebase:

### Layer 1: Product foundation

The initial version introduced the app’s core habit loop.

### Layer 2: Product usability

Version 1.1 made the app understandable and easier to adopt.

### Layer 3: Decision quality

Version 1.2 made the app’s behavior smarter.

### Layer 4: Execution consistency

Version 1.3 made the app use those smarter rules more consistently across screens.

## Recommended Merge Story

If you later merge or present this work, the clean story is:

1. `main` already represents the app after the first round of product maturation.
2. Version 1.2 adds smarter prioritization, streak logic, and reminder behavior.
3. Version 1.3 removes duplicated daily-pick behavior and routes more of the app through shared logic.

That sequence is coherent both technically and from a release-note perspective.

## Final Takeaway

The codebase did not evolve by replacing the original app.
It evolved by tightening it in stages.

The initial version created the product.
Version 1.1 improved usability.
Version 1.2 improved intelligence.
Version 1.3 improved consistency.

That is the most accurate way to understand how these versions connect to each other and to the current `main` branch.
