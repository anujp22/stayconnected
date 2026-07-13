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
    let cadenceDays: Int

    /// How overdue this person is relative to *their own* cadence.
    /// 1.0 means exactly due; >1 means overdue. Drives ranking so a close
    /// friend you haven't reached ranks above an acquaintance on schedule.
    var overdueRatio: Double {
        Double(daysSinceCall) / Double(max(cadenceDays, 1))
    }
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
            .filter { $0.isInPool && !$0.isSnoozed(asOf: today) }
            .map { person in
                Candidate(
                    person: person,
                    daysSincePick: daysBetween(person.lastPickedAt, and: today),
                    daysSinceCall: daysBetween(person.lastCalledAt, and: today),
                    neverContacted: person.lastCalledAt == nil,
                    isPinned: person.isPinned,
                    timesPickedThisMonth: Int(person.timesPickedThisMonth),
                    pickedThisMonth: person.timesPickedThisMonth > 0,
                    cadenceDays: person.contactCadence.days
                )
            }

        let eligible = candidates.filter { $0.daysSincePick >= minGapDays }
        let fallbackOnly = candidates.filter { $0.daysSincePick < minGapDays }

        // Rank smarter: pinned, then never-contacted, then whoever is most
        // overdue relative to their own cadence, then those not picked as often
        // this month, then longest wait since they were last surfaced.
        func rank(_ list: [Candidate]) -> [Candidate] {
            list.sorted { a, b in
                if a.isPinned != b.isPinned {
                    return a.isPinned
                }

                if a.neverContacted != b.neverContacted {
                    return a.neverContacted
                }

                // Most overdue relative to their own cadence comes first.
                if a.overdueRatio != b.overdueRatio {
                    return a.overdueRatio > b.overdueRatio
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
