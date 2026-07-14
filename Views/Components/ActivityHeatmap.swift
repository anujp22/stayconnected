import SwiftUI

/// A GitHub-style contribution grid of the last several weeks of connection
/// activity — 7 rows (weekdays) × `weeks` columns, the rightmost column being
/// the current week. Cell intensity scales with how many people you reached
/// that day.
///
/// It reads from a pre-bucketed `[Date: Int]` (keyed by start-of-day) so the
/// view does no Core Data work itself. This is a motivating, at-a-glance view
/// of consistency — the payoff for an app about small daily habits.
struct ActivityHeatmap: View {
    /// Connection counts keyed by start-of-day.
    let counts: [Date: Int]
    var weeks: Int = 12
    var cell: CGFloat = 13
    var spacing: CGFloat = 4

    private let calendar = Calendar.current

    var body: some View {
        let today = calendar.startOfDay(for: Date())
        let todayRow = (calendar.component(.weekday, from: today) - calendar.firstWeekday + 7) % 7

        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack(spacing: spacing) {
                ForEach(0..<weeks, id: \.self) { col in
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { row in
                            cellView(col: col, row: row, today: today, todayRow: todayRow)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            legend
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Connection activity over the last \(weeks) weeks")
    }

    // MARK: - Cell

    @ViewBuilder
    private func cellView(col: Int, row: Int, today: Date, todayRow: Int) -> some View {
        // Offset in days back from today for this (column, row) slot.
        let offset = (weeks - 1 - col) * 7 + (todayRow - row)

        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(fill(forOffset: offset, today: today))
            .frame(width: cell, height: cell)
    }

    private func fill(forOffset offset: Int, today: Date) -> Color {
        // Future slots in the current week (below today) render as empty space.
        guard offset >= 0,
              let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
            return .clear
        }

        let count = counts[date] ?? 0
        guard count > 0 else {
            return Theme.Palette.divider.opacity(0.4)
        }
        return Theme.Palette.success.opacity(level(for: count))
    }

    /// Maps a day's connection count to an opacity band. Counts are small in
    /// practice (roughly 1–3/day), so a few discrete steps read best.
    private func level(for count: Int) -> Double {
        switch count {
        case 1: return 0.55
        case 2: return 0.78
        default: return 1.0
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 6) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(Theme.Palette.textSecondary)

            ForEach([0.0, 0.55, 0.78, 1.0], id: \.self) { op in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(op == 0 ? Theme.Palette.divider.opacity(0.4) : Theme.Palette.success.opacity(op))
                    .frame(width: 11, height: 11)
            }

            Text("More")
                .font(.caption2)
                .foregroundStyle(Theme.Palette.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    var sample: [Date: Int] = [:]
    for offset in 0..<84 where Int.random(in: 0...2) > 0 {
        if let d = cal.date(byAdding: .day, value: -offset, to: today) {
            sample[d] = Int.random(in: 1...3)
        }
    }
    return ActivityHeatmap(counts: sample)
        .padding()
        .cardSurface()
        .padding()
        .background(Theme.Palette.background)
}
