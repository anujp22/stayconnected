# StayConnected — Color System Research & Proposal

_Research + a recommended direction. No code yet. Written to inform the color pass._

## 0. Honest framing: what color psychology can and can't claim

Most "color psychology" you'll find online is overstated pop-science ("blue
makes you productive," "red boosts sales"). The rigorous, replicable findings
are narrower than the folklore. What we can actually lean on:

1. **Arousal is driven more by saturation & brightness than hue.** Highly
   saturated, bright colors raise arousal (alertness, mild tension); muted,
   desaturated colors lower it (calm). This is the single most reliable lever —
   and the most important one for a calm app.
2. **Warm vs. cool is a real perceptual/affective axis.** Warm hues
   (red→orange→yellow) read as advancing, energetic, intimate; cool hues
   (green→blue→violet) read as receding, calm, distant. Warm = human/close;
   cool = trust/serene but risks clinical/cold.
3. **Cultural associations are learned, strong, and context-dependent.** In
   Western/US contexts (our user): blue = trust/calm/stability; green =
   growth/health/safety/"go"; red = alarm/error/urgency/love (context-split);
   amber/yellow = warmth/caution; earth tones = comfort/groundedness. These are
   conventions, not biology — but conventions are exactly what a UI should honor.
4. **Contrast & legibility are not psychology — they're measurable and
   non-negotiable.** WCAG contrast, not vibes, governs text and state colors.
5. **Don't encode meaning in hue alone.** ~8% of men have red-green color
   vision deficiency; state/meaning must also carry via icon, label, or
   position.

Everything below is applied within those guardrails.

---

## 1. What is StayConnected, emotionally? (the brief the color must serve)

The product's whole thesis is **low-pressure, guilt-free reconnection**. The
CLAUDE.md principle is explicit: *"Calm by design… deliberately avoids
pace/quota shaming… keep copy warm and forward-looking."* The emotional jobs:

- **Reassure, don't nag.** Reduce the anxiety/guilt of "I'm bad at staying in
  touch." Never feel like a productivity tool cracking a whip.
- **Warmth & human closeness.** It's about *people you love*, not tasks.
- **Trust & safety.** Everything is on-device, private; the UI should feel
  safe and dependable.
- **Quiet motivation.** Celebrate momentum (streaks, "reached this month")
  gently — encouraging, never competitive or alarmist.

Translated to color strategy, that means:

| Need | Color lever |
|---|---|
| Calm, low anxiety | Low saturation, soft brightness, generous neutral space |
| Human warmth / closeness | A **warm** presence in the palette (not all-cool) |
| Trust, serenity, safety | A **calm cool** anchor (blue/teal/green family) |
| Gentle motivation | A warm accent for streaks/celebration — soft, not neon |
| No shame | **No red** in the core UI; muted amber for the rare caution |

The winning structure is a **warm–cool balance**: a calm cool *primary* for
trust + serenity, a warm *secondary* for humanity + encouragement, resting on a
**warm neutral** base for comfort. Pure-cool feels clinical; pure-warm feels
chaotic. This app wants "a warm, trusted friend."

---

## 2. Diagnosis of the current palette

| Token | Value | Read |
|---|---|---|
| BrandPrimary | `#3CB4F9` | Bright **sky cyan** — clean, but reads *tech/notification*, slightly cold & high-arousal |
| PrimaryDeep | `#0F2A5A` | Deep navy — good for depth/gradient |
| AccentSand | `#F2E3D3` | Warm cream — **the warmth is here, but it's barely used** |
| Background (light) | `#F7F5F2` | Warm off-white — good, cozy |
| Background (dark) | `#0F172A` | **Cool navy** — fights the warm light mode; clinical at night |
| Success | `#22C55E` | Fairly **vivid** green — a touch loud for "calm" |
| Warning | `#F59E0B` | Amber — appropriate, used sparingly |
| Streak flame | `orange` (system) | **Off-palette** — not a defined token |

**The core problem: a warm/cool identity split.** Light mode is warm (cream), but
the brand is a cold cyan and dark mode is a cold navy. The one genuinely warm,
human element (sand) is decorative and underused. The app *says* "warm, calm,
human connection" but the color *says* "clean tech utility." The streak flame
reaching for `orange` is a symptom — the palette had no warm accent to give it,
so it grabbed a random one.

**The opportunity:** resolve the split decisively toward warm-calm, make the
warm accent a first-class citizen, and soften saturation for true calm.

---

## 3. Color-by-color, for this app

- **Teal / blue-green** — the sweet spot of "calm + trust + *alive*". Blue's
  trust and green's growth/health/relationship connotations meet here. Feels
  organic and human in a way pure tech-blue doesn't. Strong primary candidate.
- **Sage / muted green** — calm, restorative, growth, "tending" something
  (relationships as a garden you tend — on-theme). Excellent for success and as
  a soft primary.
- **Blue** — maximal trust/serenity but the coldest; risks clinical. Good if
  warmed (periwinkle, softer sky) and balanced with warm neutrals.
- **Cream / warm neutral** — comfort, calm, groundedness ("hygge"). The base
  that makes everything feel safe and unclinical. Should be the whole surface
  system, not an accent.
- **Terracotta / clay / warm amber** — warmth, encouragement, hearth, human
  energy — *without* red's alarm. Ideal for streaks, celebration, and the warm
  secondary. Soft/desaturated to stay calm.
- **Dusty rose / coral** — intimacy, care, affection (very "relationship"),
  but more style-coded and can skew one demographic; use as accent at most.
- **Red** — alarm, error, urgency, shame. **Avoid in core UI.** Reserve only
  for genuinely destructive confirmation (e.g. remove-from-pool), never for
  progress or state.
- **Orange (bright) / yellow (bright)** — high arousal; great in *muted* form
  (amber, ochre) for warmth, risky at full saturation for a calm app.

---

## 4. Three concrete directions

Each is a full palette (light-mode values shown; dark-mode notes follow). All
target the same emotional brief; they differ in how far they move.

### Direction A — "Warm Sanctuary"  ⟵ recommended
_Calm sage-teal + terracotta warmth + true cream. Resolves the split fully._

| Role | Light | Note |
|---|---|---|
| Brand (primary) | `#3E8E82` | Muted **sage-teal** — calm, organic, trustworthy, not techy |
| Brand deep | `#1F4D45` | Forest teal for gradient/emphasis |
| Warm accent | `#E08A5F` | Soft **terracotta** — streaks, celebration, warm energy |
| Success | `#5DA47C` | Gentle green, harmonized with brand (not neon) |
| Caution | `#D99A4E` | Muted amber (rename Warning→Caution) |
| Background | `#FAF6F0` | Warm cream |
| Surface (card) | `#FFFFFF` / `#FFFDF9` | Soft white |
| Text primary | `#26201C` | Warm near-black |
| Text secondary | `#6E655E` | Warm gray |
| Divider | `#E9E1D8` | Warm hairline |

Dark mode: **warm** charcoal, not navy — bg `#1B1613`, card `#282019`, brand
lightens to `#5FB3A4`, accent `#E89B78`. Cozy, nighttime-friendly.

Why it wins: it makes the app *feel like its promise*. Sage-teal keeps trust +
calm; terracotta finally gives warmth/encouragement a real home (and a proper
streak color); cream unifies everything as comfortable and safe. Distinctive vs.
the sea of blue productivity apps.

### Direction B — "Serene Trust"  (safe evolution)
_Keep the blue-family trust, just warm and soften it._

Brand `#5B84D6` (softer, warmer blue — less cyan), deep `#2A4A7F`, warm accent
amber `#EBA96A`, success `#4FA980`, cream neutrals as in A. Lower risk, keeps the
current "trust" read, fixes the cold-cyan and warms dark mode. Least departure.

### Direction C — "Quiet Bloom"  (bold, intimate)
_Lead with warmth._ Brand dusty-clay `#C57B63` or rose `#BE7C86`, secondary sage
`#7FA98C`, cream base. Most emotionally "relationship/care," most distinctive —
but style-coded and the biggest departure; higher taste risk.

---

## 5. The functional / semantic layer (independent of which direction)

Move from **raw color names** to **semantic roles** in `Theme.Palette`, so
meaning is centralized and re-skinning is trivial:

`brand`, `brandDeep`, `accentWarm`, `success`, `caution`, `destructive`
(red, only for delete), `background`, `surface`, `surfaceElevated`,
`textPrimary`, `textSecondary`, `divider`, `streak`, and a `heatmapScale`
(4 steps). Map app elements:

- **Hero card & primary CTA** → `brand`→`brandDeep` gradient (signature moment).
- **Streak flame** → `accentWarm` (retire the off-palette system orange).
- **"New" chip** → `brand` tint; **"Connected" chip / heatmap / success** →
  `success`.
- **Cadence chips** → neutral/`brand` tint.
- **Tab bar active** → `brand`.
- **Pool warning banner** → `caution` (soft), never red.

---

## 6. Accessibility & dark mode (non-negotiable)

- **Contrast:** every text/background pair meets **WCAG AA** (4.5:1 body,
  3:1 large text & UI glyphs). Colored text on tinted chips must be checked
  (e.g. brand text on 14%-brand fill). I'll verify each pair with numbers before
  shipping.
- **Never hue-alone:** status already pairs color with a **label** (New/
  Connected) and the heatmap uses **opacity steps** — keep both so it's
  colorblind-safe. Consider adding a subtle shape/label cue anywhere that's
  purely colored.
- **Dark mode:** warm the dark surfaces (see A/B) so night use feels cozy, not
  clinical; re-tune brand/accent lightness for contrast on dark.
- **Don't over-saturate:** keep saturation moderate — it's the main calm lever.

---

## 7. Why this is cheap to execute

Phase 0's `Theme.Palette` + the just-completed literal sweep mean **every color
in the app flows from one file and a handful of asset-catalog colorsets.**
Changing direction = editing ~10 colorsets (light+dark values) + possibly adding
2 tokens (`accentWarm`, `streak`, `destructive`). No view code changes for the
recolor itself. We can prototype a direction, screenshot all six screens, and
compare side-by-side in an afternoon.

## 8. Recommendation

Ship **Direction A ("Warm Sanctuary")**: it's the only option that fully
resolves the warm/cool identity split and makes the interface *embody* the
app's calm, human, guilt-free promise — while staying trustworthy and calm via
the sage-teal anchor. Direction B is the safe fallback if you want to keep the
blue equity; C if you want to be bold.

**Decision needed:** which direction to prototype first.
