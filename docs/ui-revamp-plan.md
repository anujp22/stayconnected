# StayConnected — UI Revamp Plan

_Written 2026-07-13. A design + implementation plan. No code changes yet._

## Chosen direction: "Warm Calm, elevated"

Rather than a jarring reidentity, we keep StayConnected's existing soul — the
calm teal palette, the warm sand accent, the anti-shaming copy — and elevate it
into something that reads as a **crafted boutique product** instead of a clean
iOS template. We do this with three levers:

1. A real **design system** so every surface is consistent and future changes
   are one-line edits.
2. **Signature identity moments** — a custom tab bar, a serif display face on
   large titles, one restrained brand gradient, a streak flame — so the app is
   memorable.
3. **Motion & feedback** — springy progress, staggered pick entrances, a small
   celebration on connect — so the app feels alive and rewarding.

The existing palette is kept verbatim:
- `BrandPrimary` #3CB4F9 (cyan), `PrimaryDeep` #0F2A5A (deep teal-navy)
- `AccentSand` #F2E3D3 (warm sand) — **promoted** from a barely-used pin tint to
  a real secondary surface
- `Background` #F7F5F2 light / #0F172A dark, `Card` white / #1E293B
- `Success`, `Warning`, `TextPrimary/Secondary`, `Divider` unchanged

---

## Phase 0 — Design system foundation (prerequisite for everything)

**New file:** `Views/Theme.swift`

- `Theme.Radius` (chip 10, card 20, pill 18, hero 26)
- `Theme.Space` (xs 6, sm 10, md 16, lg 24, xl 32)
- `Theme.Palette` — typed accessors so we stop scattering `Color("…")` string
  literals (typo-prone, no autocomplete)
- `Theme.brandGradient` — `BrandPrimary → PrimaryDeep` diagonal, the one
  signature gradient, used only on the Home hero + primary CTA
- Display font helper: `.displayTitle()` → `.system(.largeTitle, design: .serif)`
  weight bold. Applied to the six `largeTitle` screen headers. (Serif on the big
  title only; body stays SF — this is the "editorial accent" without hurting
  legibility.)

**New file:** `Views/Components/Surfaces.swift`

- `.cardSurface(radius:)` view modifier — replaces the ~9 hand-rolled
  `RoundedRectangle().fill(Card) + .overlay(stroke)` blocks in HomeView,
  SummaryView (`StatCard`, `SummarySectionCard`), SettingsView (`SettingsCard`),
  ContactRowCard, PoolView search field.
- `.heroSurface()` — gradient-tinted variant for the Home hero card (currently an
  inline `LinearGradient` in HomeView 405–422).
- `Chip` view — one component for the "Connected/New" pill (HomeView 277–294),
  cadence pill (ContactRowCard 39–48), and any future tags.

**New file:** `Views/Components/CircularIconButton.swift`

- A single 40×40 circular icon-button style with a tint parameter, replacing the
  raw `.borderedProminent`/`.bordered`/`.tint(...)` trio in the Home pick rows
  (HomeView 314–352) so Call / Done / Snooze read as one designed set.

_Impact: removes ~200 lines of duplicated chrome; every later phase becomes a
small, uniform edit. Ship this first, verify nothing shifts visually, then build
on it._

---

## Phase 1 — Custom tab bar (biggest identity win)

**File:** `Views/AppShellView.swift`

- Keep `TabView(selection:)` for paging; hide the system bar
  (`.toolbar(.hidden, for: .tabBar)` on each tab or `UITabBar` appearance).
- Overlay a floating capsule bar: `.ultraThinMaterial`, ~28pt corner radius,
  slight shadow, inset from the bottom safe area.
- Four items (Home / Pool / Summary / Settings). Active item tinted
  `BrandPrimary` with a soft pill highlight that slides between items via
  `matchedGeometryEffect`. Light haptic on switch.
- Respect Dynamic Type (fall back to labels-under-icons; don't crush at large
  sizes) and `.accessibilityElement` per item.

_This is the single change that most removes the "stock SwiftUI" feel._

---

## Phase 2 — Home (canonical screen; highest daily use)

**File:** `Views/HomeView.swift` (also the biggest refactor target — 831-line body)

Structural: extract the inline pick row into `TodayPickRow`, the hero into
`TodayHeroCard`, the header into `HomeHeader`. Purely mechanical, no behavior
change, but makes the screen maintainable and testable.

Visual/interaction upgrades:
- **Time-aware header:** "Good morning" / "Good afternoon" / "Good evening" +
  formatted date, serif display title. Small **streak flame chip** top-right
  (flame SF Symbol + current streak from `NotificationsService.streaks`) — gives
  the most-used screen a personal, alive anchor. Stays calm: no number if streak
  is 0, just a soft "New week" style nudge.
- **Hero card** uses `.heroSurface()` (the brand gradient) — currently a very
  faint 5%-opacity gradient; make it a touch more present but still soft.
- **Animate monthly progress:** `.animation(.spring(response: 0.5), value:
  monthlyProgress)` so it fills rather than snaps.
- **Staggered pick entrance:** rows transition in with
  `.move(edge: .trailing).combined(with: .opacity)` and a small per-index delay
  on generate/refresh.
- **Connect celebration:** when a pick is marked connected, animate the row's
  status chip New→Connected with a checkmark scale-bounce + the existing success
  haptic. This is the emotional payoff moment — currently silent.
- **Unified action buttons:** Call / Done / Snooze become `CircularIconButton`s
  (Phase 0), consistent sizing and tint.
- **Warmer empty state:** the "No pick for today" card gets a small illustrative
  SF Symbol motif (e.g. `cup.and.saucer` / `hands.sparkles`) and keeps the warm
  copy; center it rather than left-aligned text-only.
- **Pull-to-refresh** on the scroll as an alternative to the Generate button.

---

## Phase 3 — Summary as a dashboard (highest "wow" potential)

**File:** `Views/SummaryView.swift`

- **Hero row:** replace the two stacked streak `StatCard`s with a single hero
  showing a **ring/arc** for this-month progress (reuse the Home monthly target
  math) + the streak flame beside it. Gradient-fill the big numbers
  (`StatCard.value`) with `Theme.brandGradient`.
- **12-week activity heatmap** (the standout feature): a GitHub-style
  contribution grid built from `ConnectionEvent` dates — 7 rows (weekdays) ×
  ~12 columns, cell opacity scaled by connections that day. Genuinely motivating
  for a consistency app, and the data already exists (`ConnectionEvent.date`).
  New small component `ActivityHeatmap`, fed by a `[Date: Int]` bucketed in
  `refreshSummary()`.
- Section list rows: add the small contact avatar (reuse Home's
  `ContactAvatarInlineView`, extracted to `Components/`) so Summary lists match
  Home visually.
- Keep all copy and the "How this works" explainer.

---

## Phase 4 — Pool & pickers

**File:** `Views/PoolView.swift`, `Views/Components/ContactRowCard.swift`

- **ContactRowCard shows the real avatar** (extracted `ContactAvatarInlineView`)
  instead of the generic `person.fill` circle — makes the pool feel like *your*
  people. Falls back to initials/symbol.
- Show **cadence + last-connected** as a small chip row using the shared `Chip`.
- Search field adopts `.cardSurface()`; consider a subtle section header count
  chip ("12 people").
- **Add Contact** as a floating `+` button (brand gradient) bottom-right, in
  addition to / instead of the inline row — more discoverable, more app-like.
- `MultiContactPickerSheet`: selected rows get a brand-tinted background wash,
  not just the checkmark; add a small selected-count header.
- Empty pool state: friendly illustration + single prominent "Add your first
  people" CTA (ties into onboarding hand-off).

---

## Phase 5 — Settings, History, Onboarding polish

**SettingsView**
- `SettingsCard` → shared `.cardSurface()`; add a small leading SF Symbol per
  card title (frequency = `slider.horizontal.3`, reminder = `bell`, appearance =
  `paintbrush`) for scannability.
- The reminder **Preview** becomes a mini mock notification bubble (app icon +
  title + body on a rounded `.regularMaterial` card) so users see what they'll
  actually get.
- Move the three appearance options to show a tiny swatch preview.

**ContactHistoryView**
- It's currently a bare grouped `List`. Rebuild header as a profile card (avatar,
  name, cadence chip, total connections, last connected) and render history as a
  **vertical timeline** (dot + connector line) instead of flat rows.

**OnboardingView (AppShellView)**
- Cards adopt `.cardSurface()` + brand gradient on the hero title; add a subtle
  page-in animation. Add a lightweight progress/paging feel. Consider a branded
  hero graphic at top.

---

## Phase 6 — Motion & haptic language (cross-cutting)

- Standardize: light haptic on navigation/selection, success haptic on
  connect/save (already partly present — make it universal).
- Standard transitions: cards fade+scale in on appear; buttons already have the
  press scale in `PrimaryPillButtonStyle` — extend that feel to
  `CircularIconButton`.
- Respect `@Environment(\.accessibilityReduceMotion)` — gate the staggered/spring
  animations behind it.

---

## Sequencing & risk

| Phase | Effort | Risk | Payoff |
|-------|--------|------|--------|
| 0 Design system | M | Low | Enables everything |
| 1 Custom tab bar | M | Med (custom nav) | Highest identity |
| 2 Home | L | Med | Highest daily value |
| 3 Summary dashboard | L | Low | Highest "wow" |
| 4 Pool + pickers | M | Low | Personalization |
| 5 Settings/History/Onboarding | M | Low | Consistency |
| 6 Motion/haptics | S | Low | Polish gloss |

Recommended order: **0 → 1 → 2 → 3 → 4 → 5 → 6**, shipping/reviewing after each.
Phase 0 must land first. Each phase is independently shippable.

## New files (remember: manual pbxproj entries — 4 each, per CLAUDE.md gotcha)

- `Views/Theme.swift`
- `Views/Components/Surfaces.swift` (cardSurface, heroSurface, Chip)
- `Views/Components/CircularIconButton.swift`
- `Views/Components/ContactAvatarInlineView.swift` (extracted from HomeView)
- `Views/Components/FloatingTabBar.swift`
- `Views/Components/ActivityHeatmap.swift`
- `Views/Components/StreakFlame.swift`

## Explicitly preserved (non-negotiable per CLAUDE.md)

- "Calm by design": no pace/quota shaming, no warning-red progress, warm
  forward-looking copy. All new copy follows this.
- Auto-generate / reset / snooze / auto-check-in behavior unchanged — this is a
  presentation-layer revamp only.
- Swift Testing tests must still pass; Contacts I/O stays on detached background
  tasks.
