import CoreData
import Foundation

// MARK: - Supporting Types

struct Candidate {
    let person: Person
    let daysSincePick: Int
    let daysSinceCall: Int
    let neverContacted: Bool
    let isPinned: Bool
    let timesPickedThisMonth: Int
    let pickedThisMonth: Bool
}

final class SelectionService {
    // MARK: - Properties

    private let cal = Calendar.current

    // MARK: - Helpers

    private func daysBetween(_ from: Date?, and to: Date = Date()) -> Int {
        guard let from else { return Int.max }
        return cal
            .dateComponents(
                [.day],
                from: cal.startOfDay(for: from),
                to: cal.startOfDay(for: to)
            )
            .day ?? Int.max
    }

    // Prioritizes neglected contacts while still keeping daily picks varied.
    // MARK: - Public API

    func pickToday(
        from people: [Person],
        picksPerDay: Int,
        minGapDays: Int,
        today: Date = Date()
    ) -> [Person] {
        let candidates: [Candidate] = people
            .filter { $0.isInPool }
            .map { person in
                Candidate(
                    person: person,
                    daysSincePick: daysBetween(person.lastPickedAt, and: today),
                    daysSinceCall: daysBetween(person.lastCalledAt, and: today),
                    neverContacted: person.lastCalledAt == nil,
                    isPinned: person.isPinned,
                    timesPickedThisMonth: Int(person.timesPickedThisMonth),
                    pickedThisMonth: person.timesPickedThisMonth > 0
                )
            }

        let eligible = candidates.filter { $0.daysSincePick >= minGapDays }
        let fallbackOnly = candidates.filter { $0.daysSincePick < minGapDays }

        // Rank smarter: never-contacted first, then people who have gone the
        // longest since a real connection, then those not picked as often this
        // month, then longest wait since they were last surfaced by the app.
        func rank(_ list: [Candidate]) -> [Candidate] {
            list.sorted { a, b in
                if a.isPinned != b.isPinned {
                    return a.isPinned
                }

                if a.neverContacted != b.neverContacted {
                    return a.neverContacted
                }

                if a.daysSinceCall != b.daysSinceCall {
                    return a.daysSinceCall > b.daysSinceCall
                }

                if a.timesPickedThisMonth != b.timesPickedThisMonth {
                    return a.timesPickedThisMonth < b.timesPickedThisMonth
                }

                if a.pickedThisMonth != b.pickedThisMonth {
                    return !a.pickedThisMonth
                }

                if a.daysSincePick != b.daysSincePick {
                    return a.daysSincePick > b.daysSincePick
                }

                let leftName = a.person.displayName ?? ""
                let rightName = b.person.displayName ?? ""
                return leftName.localizedCaseInsensitiveCompare(rightName) == .orderedAscending
            }
        }

        let rankedEligible = rank(eligible)
        let rankedFallback = rank(fallbackOnly)

        let pool = Array(rankedEligible.prefix(picksPerDay)) + Array(
            rankedFallback.prefix(max(picksPerDay - rankedEligible.count, 0))
        )

        // Keep the strongest candidates near the top, but add light randomness
        // to the tail so the experience still feels fresh.
        let guaranteedCount = min(picksPerDay, min(pool.count, 2))
        let guaranteed = Array(pool.prefix(guaranteedCount)).map { $0.person }

        let remainderPool = Array(pool.dropFirst(guaranteedCount)).map { $0.person }
        var bucket = remainderPool
        var chosen = guaranteed

        while chosen.count < picksPerDay && !bucket.isEmpty {
            let idx = Int.random(in: 0..<bucket.count)
            let candidate = bucket.remove(at: idx)

            if !chosen.contains(where: { $0.objectID == candidate.objectID }) {
                chosen.append(candidate)
            }
        }

        if chosen.count < picksPerDay {
            for fallback in pool.map({ $0.person }) {
                guard chosen.count < picksPerDay else { break }
                if !chosen.contains(where: { $0.objectID == fallback.objectID }) {
                    chosen.append(fallback)
                }
            }
        }

        return chosen
    }
}
