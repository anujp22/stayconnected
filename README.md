# StayConnected

StayConnected is a gentle iOS app for keeping relationships warm — a small daily nudge to reach out to the people who matter, without guilt or busywork.

Each day it suggests a few people to reconnect with, chosen by how overdue they are for *your* rhythm with them. Reaching out is one tap and logs itself, so there's no relationship-log to maintain.

---

## ✨ Features

- A few daily picks, ranked by how overdue each person is for their own cadence
- Per-person cadence: Close, Regular, or Occasional
- One-tap reach-out (call or message) that logs the check-in automatically
- Gentle "not today" snooze that swaps in someone else
- One-line context notes ("ask about her new job")
- Connection history and a calm, non-shaming progress view
- Adaptive daily reminder
- Private by design — on device, no account
- Dark Mode support; minimal, modern SwiftUI interface

---

## 🧠 How It Works

StayConnected chooses each day's picks by:

- Cadence: how overdue a person is relative to their own desired rhythm
- Pinned and never-contacted people surfaced first
- A minimum gap so the same people don't repeat too soon
- A fallback when the pool is small, so you always get suggestions
- Snoozed people set aside until their snooze ends

This keeps you reconnecting with the right people without it ever feeling like a chore.

---

## 📱 Screens

### Home
Shows today's selected contacts and progress for the month.

![Home](screenshots/home.png)

### Pool
Your full list of contacts eligible for daily selection.

![Pool](screenshots/pool.png)

### Summary
Statistics about your connection habits including:

- Current streak
- Longest streak
- Calls made this month
- Remaining connections

![Summary](screenshots/summary.png)

### Settings
Configure:

- Picks per day
- Minimum gap between contacts
- Light / Dark / System appearance

![Settings](screenshots/settings.png)
---

## 🏗 Architecture

The app follows a clean SwiftUI architecture:

```
Views
ViewModels
Models
Services
```

**Views**
SwiftUI UI components.

**ViewModels**
State management and UI logic.

**Models**
Data structures and CoreData entities.

**Services**
Business logic including the contact selection algorithm.

---

## ⚙️ Technologies

- SwiftUI
- CoreData
- Contacts Framework
- iOS 18+

---

## 🎨 Design

The UI uses a minimal Apple-style design system with:

- Soft gradients
- Rounded cards
- Subtle shadows
- Calm color palette

---

## 🚀 Future Improvements

- Home & Lock Screen widgets ("who to reach out to today")
- iCloud sync (the Core Data model is already CloudKit-compatible)
- Birthday-aware picks
- Deeper per-person history

---

## 📄 License

MIT License
