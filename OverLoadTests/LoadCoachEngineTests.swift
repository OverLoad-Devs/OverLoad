import Foundation
import Testing
@testable import OverLoad

struct LoadCoachEngineTests {
    private func session(_ reps: Int, _ weight: Double = 100, count: Int = 3) -> [SetRecord] {
        (0..<count).map { _ in SetRecord(reps: reps, weight: weight, date: .now) }
    }

    @Test func noHistory() {
        let result = LoadCoachEngine.suggestNext(history: [])
        #expect(result.status == .hold)
        #expect(result.reason == "Log your first session")
        #expect(result.weight == 0)
        #expect(result.reps == 8)
    }
    @Test func progress() {
        let result = LoadCoachEngine.suggestNext(history: [session(12)])
        #expect(result.status == .progress)
        #expect(result.weight == 105)
        #expect(result.reps == 8)
    }
    @Test func hold() {
        let result = LoadCoachEngine.suggestNext(history: [session(10)])
        #expect(result.status == .hold)
        #expect(result.weight == 100)
        #expect(result.reps == 11)
    }
    @Test func everySetMustReachUpperBound() {
        let result = LoadCoachEngine.suggestNext(history: [session(12) + session(10, count: 1)])
        #expect(result.status == .hold)
        #expect(result.weight == 100)
    }
    @Test func plateau() {
        let history = [session(10), session(10), session(10)]
        #expect(LoadCoachEngine.isPlateaued(history: history))
        #expect(LoadCoachEngine.suggestNext(history: history).status == .plateau)
    }
    @Test func improvementBreaksPlateau() {
        let history = [session(8), session(9), session(10)]
        #expect(!LoadCoachEngine.isPlateaued(history: history))
        #expect(LoadCoachEngine.suggestNext(history: history).status == .hold)
    }
    @Test func consecutivePlateausDeload() {
        let result = LoadCoachEngine.suggestNext(history: Array(repeating: session(10), count: 4))
        #expect(result.status == .deload)
        #expect(result.weight == 90)
        #expect(result.reps == 8)
    }
    @Test func consecutiveLowTopSetsDeload() {
        let result = LoadCoachEngine.suggestNext(history: [session(7), session(6)])
        #expect(result.status == .deload)
        #expect(result.weight == 90)
    }
    @Test func oneLowSessionDoesNotDeload() {
        #expect(LoadCoachEngine.suggestNext(history: [session(7)]).status == .hold)
    }
    @Test(arguments: [(95.0, 85.0), (125.0, 115.0), (0.0, 0.0)])
    func roundsDeloadToNearestFive(weight: Double, expected: Double) {
        let result = LoadCoachEngine.suggestNext(history: [session(7, weight), session(7, weight)])
        #expect(result.weight == expected)
    }
    @Test func emptySessionsAreIgnored() {
        #expect(LoadCoachEngine.suggestNext(history: [[], []]).reason == "Log your first session")
    }
    @Test func plateauOverridesProgress() {
        #expect(LoadCoachEngine.suggestNext(history: [session(12), session(12), session(12)]).status == .plateau)
    }
}
