import Foundation

struct SetRecord {
    let reps: Int
    let weight: Double
    let date: Date
}

enum CoachStatus: String { case progress, hold, plateau, deload }

struct Suggestion {
    let weight: Double
    let reps: Int
    let status: CoachStatus
    let reason: String
}

/// Starter policy; the Load Coach team owns tuning these values.
struct LoadCoachConfig {
    static let repRange = 8...12
    static let weightIncrement = 5.0
    static let plateauSessionCount = 3
    static let consecutivePlateauChecks = 2
    static let lowRepSessionCount = 2
    static let deloadFraction = 0.10
    static let roundingIncrement = 5.0
}

enum LoadCoachEngine {
    private static func sessions(_ history: [[SetRecord]]) -> [[SetRecord]] {
        history.map { $0.filter { $0.reps > 0 && $0.weight >= 0 && $0.weight.isFinite } }
            .filter { !$0.isEmpty }
    }

    private static func top(_ sets: [SetRecord]) -> SetRecord? {
        sets.max { lhs, rhs in
            if lhs.weight == rhs.weight { return lhs.reps < rhs.reps }
            return lhs.weight < rhs.weight
        }
    }

    static func isPlateaued(history: [[SetRecord]]) -> Bool {
        let recent = sessions(history).suffix(LoadCoachConfig.plateauSessionCount)
        guard recent.count == LoadCoachConfig.plateauSessionCount else { return false }
        let scores = recent.map { $0.map { $0.weight * Double($0.reps) }.max() ?? 0 }
        return zip(scores, scores.dropFirst()).allSatisfy { $1 <= $0 }
    }

    static func suggestNext(history: [[SetRecord]]) -> Suggestion {
        let history = sessions(history)
        guard let last = history.last, let topSet = top(last) else {
            return Suggestion(weight: 0, reps: LoadCoachConfig.repRange.lowerBound,
                              status: .hold, reason: "Log your first session")
        }
        let plateau = isPlateaued(history: history)
        let checks = LoadCoachConfig.consecutivePlateauChecks
        let repeatedPlateau = history.count >= LoadCoachConfig.plateauSessionCount + checks - 1
            && (0..<checks).allSatisfy { offset in
                isPlateaued(history: Array(history.dropLast(offset)))
            }
        let recent = history.suffix(LoadCoachConfig.lowRepSessionCount)
        let lowReps = recent.count == LoadCoachConfig.lowRepSessionCount
            && recent.allSatisfy { (top($0)?.reps ?? 0) < LoadCoachConfig.repRange.lowerBound }
        if repeatedPlateau || lowReps {
            let weight = (topSet.weight * (1 - LoadCoachConfig.deloadFraction)
                          / LoadCoachConfig.roundingIncrement).rounded() * LoadCoachConfig.roundingIncrement
            return Suggestion(weight: max(0, weight), reps: LoadCoachConfig.repRange.lowerBound,
                              status: .deload, reason: lowReps ? "Top set below 8 reps twice; reduce load 10%." : "Two plateau checks; reduce load 10%.")
        }
        if plateau {
            return Suggestion(weight: topSet.weight, reps: min(topSet.reps + 1, LoadCoachConfig.repRange.upperBound),
                              status: .plateau, reason: "Best set volume has not increased over three sessions.")
        }
        if last.allSatisfy({ $0.reps >= LoadCoachConfig.repRange.upperBound }) {
            return Suggestion(weight: topSet.weight + LoadCoachConfig.weightIncrement,
                              reps: LoadCoachConfig.repRange.lowerBound, status: .progress,
                              reason: "Every set reached 12 reps; add 5 lb.")
        }
        return Suggestion(weight: topSet.weight,
                          reps: min(max(topSet.reps + 1, LoadCoachConfig.repRange.lowerBound), LoadCoachConfig.repRange.upperBound),
                          status: .hold, reason: "Keep the load and aim for one more rep.")
    }
}
