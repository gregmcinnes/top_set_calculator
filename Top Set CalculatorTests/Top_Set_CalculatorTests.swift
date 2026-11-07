//
//  Top_Set_CalculatorTests.swift
//  Top Set CalculatorTests
//
//  Created by Greg McInnes on 12/28/25.
//

import Foundation
import SwiftUI
import Testing
@testable import Top_Set_Calculator

@MainActor
struct WeightInputTests {
    @Test func acceptsPeriodAndCommaDecimals() {
        #expect(WeightInput.parse("102.5") == 102.5)
        #expect(WeightInput.parse("102,5") == 102.5)
    }
    
    @Test func rejectsValuesThatAreNotUsableWeights() {
        for text in ["", ".", "0", "-5", "abc", "nan", "inf", "1e300", "99999999999999999999"] {
            #expect(WeightInput.parse(text) == nil, "\(text)")
        }
    }
    
    @Test func respectsCustomMaximum() {
        #expect(WeightInput.parse("3000", maximum: 2500) == nil)
        #expect(WeightInput.parse("2500", maximum: 2500) == 2500)
    }
}

@MainActor
struct WeightFormattingTests {
    private let locale = Locale(identifier: "en_US")
    
    @Test func keepsQuarterWeightsAndDropsTrailingZeros() {
        #expect(1.25.weightString(locale: locale) == "1.25")
        #expect(135.0.weightString(locale: locale) == "135")
        #expect(102.5.weightString(locale: locale) == "102.5")
    }
    
    @Test func doesNotGroupThousands() {
        #expect(1500.0.weightString(locale: locale) == "1500")
    }
}

@MainActor
struct OneRepMaxTests {
    @Test func singleRepIsTheLiftedWeight() {
        for estimate in OneRepMax.estimates(weight: 300, reps: 1) {
            #expect(estimate.value == 300, "\(estimate.name)")
        }
    }
    
    @Test func matchesPublishedFormulas() throws {
        let estimates = OneRepMax.estimates(weight: 200, reps: 5)
        let epley = try #require(estimates.first { $0.name == "Epley" })
        let brzycki = try #require(estimates.first { $0.name == "Brzycki" })
        #expect(abs(epley.value - 233.33) < 0.01)
        #expect(abs(brzycki.value - 225) < 0.01)
    }
    
    @Test func rejectsRepsOutOfRange() {
        #expect(OneRepMax.estimates(weight: 200, reps: 0).isEmpty)
        #expect(OneRepMax.estimates(weight: 200, reps: 31).isEmpty)
    }
}

@MainActor
struct StrengthScoringTests {
    // Hand-computed from the published coefficients: 600 kg total at 100 kg bodyweight
    @Test func maleReferenceScores() {
        #expect(abs(StrengthScoring.ipfGL(totalKg: 600, bodyweightKg: 100, isMale: true) - 75.8) < 0.1)
    }
    
    @Test func scoresStayPositiveAtExtremeBodyweights() {
        for bodyweight in [1.0, 5, 20, 40, 100, 200, 300, 1000] {
            for isMale in [true, false] {
                #expect(StrengthScoring.wilks(totalKg: 500, bodyweightKg: bodyweight, isMale: isMale) > 0)
                #expect(StrengthScoring.dots(totalKg: 500, bodyweightKg: bodyweight, isMale: isMale) > 0)
                #expect(StrengthScoring.ipfGL(totalKg: 500, bodyweightKg: bodyweight, isMale: isMale) > 0)
            }
        }
    }
}

@MainActor
struct PlateCalculatorTests {
    private func weights(_ result: PlateCalculatorResult) -> [Double] {
        result.platesPerSide.map(\.weight)
    }
    
    @Test func loadsStandardImperialWeight() {
        let result = PlateCalculator(barWeight: 45, useMetric: false).calculate(totalWeight: 225)
        #expect(weights(result) == [45, 45])
        #expect(result.isExact)
    }
    
    @Test func loadsMetricQuarterPlates() {
        let result = PlateCalculator(barWeight: 20, useMetric: true).calculate(totalWeight: 62.5)
        #expect(weights(result) == [20, 1.25])
        #expect(result.isExact)
    }
    
    @Test func weightUnderTheBarIsBarOnly() {
        let result = PlateCalculator(barWeight: 45, useMetric: false).calculate(totalWeight: 30)
        #expect(result.platesPerSide.isEmpty)
        #expect(result.achievableWeight == 45)
        #expect(result.isExact)
    }
    
    @Test func achievableWeightRecalculatesToTheSamePlates() {
        // Near misses used to round the remainder, which lost a plate on the recalculation
        let calculator = PlateCalculator(barWeight: 20, useMetric: true)
        let first = calculator.calculate(totalWeight: 62.6)
        let second = calculator.calculate(totalWeight: first.achievableWeight)
        #expect(first.achievableWeight == 62.5)
        #expect(weights(first) == weights(second))
    }
    
    @Test func inventoryFindsExactLoadThatLargestFirstMisses() {
        let calculator = PlateCalculator(
            barWeight: 45,
            availablePlates: StandardPlates.plates,
            plateInventory: [45: 1, 35: 2]
        )
        let result = calculator.calculate(totalWeight: 185)
        #expect(weights(result) == [35, 35])
        #expect(result.isExact)
    }
    
    @Test func inventoryGetsAsCloseAsPossibleWithoutGoingOver() {
        let calculator = PlateCalculator(
            barWeight: 45,
            availablePlates: StandardPlates.plates,
            plateInventory: [45: 1, 10: 1]
        )
        let result = calculator.calculate(totalWeight: 500)
        #expect(weights(result) == [45, 10])
        #expect(result.achievableWeight == 155)
        #expect(!result.isExact)
    }
    
    @Test func inventoryPrefersFewerPlates() {
        let calculator = PlateCalculator(
            barWeight: 45,
            availablePlates: StandardPlates.plates,
            plateInventory: [45: 1, 25: 2, 10: 5]
        )
        // 50 per side: 45 strands 5, and both 25 + 25 and five 10s are exact
        #expect(weights(calculator.calculate(totalWeight: 145)) == [25, 25])
    }
}

@MainActor
struct BarWeightConversionTests {
    @Test func standardBarsMapToTheirCounterpart() {
        #expect(AppSettings.barWeight(45, convertedToMetric: true) == 20)
        #expect(AppSettings.barWeight(20, convertedToMetric: false) == 45)
        #expect(AppSettings.barWeight(35, convertedToMetric: true) == 15)
    }
    
    @Test func customBarsConvertNumerically() {
        #expect(AppSettings.barWeight(50, convertedToMetric: true) == 22.5)
        #expect(AppSettings.barWeight(18, convertedToMetric: false) == 39.5)
    }
}

@MainActor
struct ColorHexTests {
    @Test func grayscaleColorsKeepTheirValue() {
        #expect(Color(uiColor: .white).toHex() == "FFFFFF")
        #expect(Color(uiColor: .black).toHex() == "000000")
    }
    
    @Test func roundTripsThroughHex() throws {
        let color = try #require(Color(hex: "3366CC"))
        #expect(color.toHex() == "3366CC")
    }
    
    @Test func detectsLightColors() throws {
        #expect(Color(uiColor: .white).isLight)
        #expect(!Color(uiColor: .black).isLight)
    }
}

@MainActor
struct RoundingTests {
    @Test func roundsToTheStep() {
        #expect(WeightRounding.round(263.3, to: 5) == 265)
        #expect(WeightRounding.round(101.2, to: 2.5) == 100)
    }
    
    @Test func zeroLeavesWeightsAlone() {
        #expect(WeightRounding.round(263.3, to: 0) == 263.3)
    }
    
    @Test func defaultsMatchTheFreePlateSet() {
        #expect(WeightRounding.defaultIncrement(useMetric: false) == 2 * StandardPlates.plates.map(\.weight).min()!)
        #expect(WeightRounding.defaultIncrement(useMetric: true) == 2 * StandardPlates.metricPlates.map(\.weight).min()!)
    }
}

@MainActor
struct OneRepMaxMedianTests {
    @Test func singleRepIsTheLiftedWeight() {
        #expect(OneRepMax.median(weight: 300, reps: 1) == 300)
    }
    
    @Test func isNotDraggedUpByBrzyckiAtHighReps() throws {
        let median = try #require(OneRepMax.median(weight: 100, reps: 30))
        #expect(median < 185)
        #expect(median > 160)
    }
    
    @Test func rejectsRepsOutOfRange() {
        #expect(OneRepMax.median(weight: 100, reps: 31) == nil)
    }
}

@MainActor
struct RPETableTests {
    @Test func reverseLookupInvertsForwardLookup() {
        let e1RM = RPETable.e1RM(weight: 275, reps: 5, rpe: 8)
        #expect(abs(e1RM - 339.5) < 0.1)
        #expect(abs(RPETable.weight(e1RM: e1RM, reps: 5, rpe: 8) - 275) < 0.001)
    }
    
    @Test func singleAtTenIsTheMax() {
        #expect(RPETable.percentage(reps: 1, rpe: 10) == 1)
    }
}

@MainActor
struct WarmupPlanTests {
    private func sets(_ top: Double, _ length: WarmupPlan.Length = .standard) -> [WarmupPlan.WarmupSet] {
        WarmupPlan.sets(topSet: top, barLoad: 45, length: length) { WeightRounding.round($0, to: 5) }
    }
    
    @Test func rampsFromTheBarToBelowTheTopSet() {
        let plan = sets(315)
        #expect(plan.map(\.weight) == [45, 160, 220, 270])
        #expect(plan.map(\.reps) == [10, 5, 3, 1])
    }
    
    @Test func lightTopSetsDropStepsThatCollapse() {
        let weights = sets(60).map(\.weight)
        #expect(weights == [45, 50])
    }
    
    @Test func nothingToWarmUpToAtOrBelowTheBar() {
        #expect(sets(45).isEmpty)
    }
    
    @Test func longerPlansHaveMoreSets() {
        #expect(sets(405, .short).count < sets(405, .standard).count)
        #expect(sets(405, .standard).count < sets(405, .long).count)
    }
}

@MainActor
struct BackoffPlanTests {
    @Test func percentDropIsBelowTheTopSet() {
        #expect(BackoffPlan.weight(topSet: 300, topReps: 3, topRPE: 8, backoffReps: 5, target: .percentDrop(0.1)) == 270)
    }
    
    @Test func rpeTargetGoesThroughTheEstimatedMax() {
        // 300 x 3 @ 8 is 86%, so e1RM is 348.8; 5 reps @ 7 is 78%
        let weight = BackoffPlan.weight(topSet: 300, topReps: 3, topRPE: 8, backoffReps: 5, target: .rpe(7))
        #expect(abs(weight - 272.1) < 0.1)
    }
}

@MainActor
struct MeetPlanTests {
    @Test func attemptsClimbInFederationSteps() {
        let attempts = MeetPlan.attempts(thirdKg: 200, style: .standard)
        #expect(attempts == MeetPlan.Attempts(opener: 182.5, second: 192.5, third: 200))
    }
    
    @Test func stylesOpenAtDifferentWeights() {
        #expect(MeetPlan.attempts(thirdKg: 200, style: .conservative).opener < MeetPlan.attempts(thirdKg: 200, style: .aggressive).opener)
    }
    
    @Test func competitionLoadIncludesCollars() {
        let result = MeetPlan.calculator.calculate(totalWeight: 200)
        #expect(result.platesPerSide.map(\.weight) == [25, 25, 25, 10, 2.5])
        #expect(result.isExact)
    }
}

@MainActor
struct ScoreTargetTests {
    @Test func targetTotalScalesLinearly() throws {
        let total = try #require(StrengthScoring.total(forScore: 400, currentScore: 300, currentTotal: 450))
        #expect(total == 600)
    }
    
    @Test func reachingThatTotalHitsTheScore() throws {
        let current = StrengthScoring.dots(totalKg: 500, bodyweightKg: 90, isMale: true)
        let needed = try #require(StrengthScoring.total(forScore: 400, currentScore: current, currentTotal: 500))
        #expect(abs(StrengthScoring.dots(totalKg: needed, bodyweightKg: 90, isMale: true) - 400) < 0.001)
    }
}

@MainActor
struct CollarAndClosestLoadTests {
    private func calculator(inventory: [Double: Int]? = nil, collar: Double = 0) -> PlateCalculator {
        PlateCalculator(barWeight: 45, availablePlates: StandardPlates.plates, plateInventory: inventory, collarWeight: collar)
    }
    
    @Test func collarsCountTowardTheTotal() {
        let result = calculator(collar: 2.5).calculate(totalWeight: 140)
        #expect(result.platesPerSide.map(\.weight) == [45])
        #expect(result.achievableWeight == 140)
        #expect(result.isExact)
    }
    
    @Test func unlimitedPlatesRoundUpToTheNextStep() {
        #expect(calculator().closestLoad(atOrAbove: 137.5) == 140)
    }
    
    @Test func anExactLoadIsItsOwnClosest() {
        #expect(calculator().closestLoad(atOrAbove: 135) == 135)
    }
    
    @Test func inventoryFindsTheNextBuildableLoad() {
        // One 45 and one 10 per side: 100 is reachable only as 45 + 10 = 155 total
        #expect(calculator(inventory: [45: 1, 10: 1]).closestLoad(atOrAbove: 100) == 135)
        #expect(calculator(inventory: [45: 1, 10: 1]).closestLoad(atOrAbove: 136) == 155)
    }
    
    @Test func inventoryThatCantReachReturnsNil() {
        #expect(calculator(inventory: [45: 1]).closestLoad(atOrAbove: 500) == nil)
    }
}

@MainActor
struct ExtendedEquipmentTests {
    private func settings() -> AppSettings {
        let suite = "test-\(UUID().uuidString)"
        let settings = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        settings.useMetric = false
        settings.barWeight = 45
        return settings
    }
    
    private func withPremium(_ body: () -> Void) {
        StoreManager.debugForcePremium = true
        defer { StoreManager.debugForcePremium = false }
        body()
    }
    
    @Test func premiumLoadsStandardPlatesUnlessAskedFor55s() {
        withPremium {
            let settings = settings()
            let calculator = PlateCalculator(barWeight: 45, settings: settings)
            #expect(calculator.calculate(totalWeight: 225).platesPerSide.map(\.weight) == [45, 45])
            #expect(calculator.calculate(totalWeight: 405).platesPerSide.map(\.weight) == [45, 45, 45, 45])
            
            settings.use55LbPlates = true
            let with55s = PlateCalculator(barWeight: 45, settings: settings)
            #expect(with55s.calculate(totalWeight: 225).platesPerSide.first?.weight == 55)
        }
    }
    
    @Test func inventoryDecidesWhether55sAreUsed() {
        withPremium {
            let settings = settings()
            settings.useMyPlates = true
            settings.setPlateCount(2, for: 55)
            let calculator = PlateCalculator(barWeight: 45, settings: settings)
            #expect(calculator.calculate(totalWeight: 155).platesPerSide.map(\.weight) == [55])
        }
    }
    
    @Test func customPlatesJoinTheLoad() {
        withPremium {
            let settings = settings()
            #expect(settings.addCustomPlate(weight: 15))
            let calculator = PlateCalculator(barWeight: 45, settings: settings)
            #expect(calculator.calculate(totalWeight: 75).platesPerSide.map(\.weight) == [15])
        }
    }
    
    @Test func duplicatePlateSizesAreRejected() {
        withPremium {
            let settings = settings()
            #expect(!settings.addCustomPlate(weight: 45))
            #expect(settings.addCustomPlate(weight: 15))
            #expect(!settings.addCustomPlate(weight: 15))
        }
    }
    
    @Test func removingACustomPlateClearsItsInventory() {
        let settings = settings()
        settings.addCustomPlate(weight: 15)
        settings.removeCustomPlate(weight: 15)
        #expect(settings.customPlates.isEmpty)
        #expect(settings.myPlates[15] == nil)
    }
    
    @Test func freeUsersGetNoCollarsOrCustomPlates() {
        let settings = settings()
        settings.collarWeight = 2.5
        settings.addCustomPlate(weight: 15)
        let calculator = PlateCalculator(barWeight: 45, settings: settings)
        #expect(calculator.collarWeight == 0)
        #expect(!calculator.availablePlates.contains { $0.weight == 15 })
    }
}

@MainActor
struct GymProfileTests {
    private func settings(suite: String = "test-\(UUID().uuidString)") -> AppSettings {
        let settings = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        settings.useMetric = false
        settings.barWeight = 45
        return settings
    }
    
    @Test func startsWithOneProfile() {
        let settings = settings()
        #expect(settings.gymProfiles.count == 1)
        #expect(settings.activeGymProfile?.name == "My Gym")
    }
    
    @Test func switchingRestoresEachSetupWithoutConvertingIt() throws {
        let settings = settings()
        let home = try #require(settings.activeGymProfileID)
        settings.barWeight = 35
        
        settings.addGymProfile(named: "Meet")
        settings.useMetric = true
        settings.barWeight = 20
        settings.collarWeightMetric = 2.5
        let meet = try #require(settings.activeGymProfileID)
        
        settings.selectGymProfile(id: home)
        #expect(settings.useMetric == false)
        #expect(settings.barWeight == 35)
        
        settings.selectGymProfile(id: meet)
        #expect(settings.useMetric == true)
        #expect(settings.barWeight == 20)
        #expect(settings.collarWeight == 2.5)
    }
    
    @Test func profilesSurviveARelaunch() throws {
        let suite = "test-\(UUID().uuidString)"
        let first = settings(suite: suite)
        first.addGymProfile(named: "Garage")
        first.barWeight = 35
        
        let second = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(second.gymProfiles.count == 2)
        #expect(second.activeGymProfile?.name == "Garage")
        #expect(second.activeGymProfile?.barWeight == 35)
    }
    
    @Test func deletingTheActiveProfileSwitchesAway() throws {
        let settings = settings()
        let first = try #require(settings.activeGymProfileID)
        settings.barWeight = 35
        settings.addGymProfile(named: "Second")
        settings.barWeight = 25
        settings.deleteGymProfile(id: try #require(settings.activeGymProfileID))
        #expect(settings.activeGymProfileID == first)
        #expect(settings.barWeight == 35)
    }
    
    @Test func theLastProfileCantBeDeleted() throws {
        let settings = settings()
        settings.deleteGymProfile(id: try #require(settings.activeGymProfileID))
        #expect(settings.gymProfiles.count == 1)
    }
}

@MainActor
struct LiftStoreTests {
    private func makeStore() -> (LiftStore, URL) {
        let url = URL.temporaryDirectory.appending(path: "lifts-\(UUID().uuidString).json")
        return (LiftStore(fileURL: url), url)
    }
    
    private func entry(_ lift: TrackedLift, _ weight: Double, _ reps: Int, rpe: Double? = nil, metric: Bool = false, daysAgo: Int = 0) -> LiftEntry {
        LiftEntry(
            liftID: lift.id,
            date: Date(timeIntervalSinceNow: Double(-daysAgo) * 86_400),
            weight: weight,
            reps: reps,
            rpe: rpe,
            isMetric: metric
        )
    }
    
    @Test func startsWithTheBigFourLifts() {
        let (store, _) = makeStore()
        #expect(store.lifts.map(\.name) == LiftStore.defaultLifts)
    }
    
    @Test func firstEntryIsNotAPRButABeatenBestIs() throws {
        let (store, _) = makeStore()
        let squat = store.lifts[0]
        #expect(store.add(entry(squat, 300, 1)).prImprovement == nil)
        #expect(store.add(entry(squat, 290, 1)).prImprovement == nil)
        #expect(try #require(store.add(entry(squat, 310, 1)).prImprovement) == 10)
    }
    
    @Test func latestAndBestAreDifferent() throws {
        let (store, _) = makeStore()
        let squat = store.lifts[0]
        store.add(entry(squat, 300, 1, daysAgo: 5))
        store.add(entry(squat, 280, 1, daysAgo: 1))
        #expect(store.latest(for: squat.id)?.weight == 280)
        #expect(store.best(for: squat.id)?.weight == 300)
    }
    
    @Test func comparesAcrossUnits() {
        let (store, _) = makeStore()
        let squat = store.lifts[0]
        store.add(entry(squat, 100, 1, metric: true))
        // 225 lb is about 102 kg, so this beats the earlier 100 kg
        #expect(store.add(entry(squat, 225, 1)).prImprovement != nil)
    }
    
    @Test func rpeEntriesUseTheTable() {
        let logged = LiftEntry(liftID: UUID(), date: .now, weight: 275, reps: 5, rpe: 8, isMetric: false)
        #expect(abs(logged.e1RM(useMetric: false) - 339.5) < 0.1)
    }
    
    @Test func persistsAcrossLaunches() {
        let (store, url) = makeStore()
        let squat = store.lifts[0]
        store.add(entry(squat, 300, 1))
        store.addLift(named: "Front Squat")
        
        let reloaded = LiftStore(fileURL: url)
        #expect(reloaded.entries.count == 1)
        #expect(reloaded.lifts.count == 5)
    }
    
    @Test func unreadableFileIsKeptNotOverwritten() throws {
        let url = URL.temporaryDirectory.appending(path: "lifts-\(UUID().uuidString).json")
        try Data("not json".utf8).write(to: url)
        let store = LiftStore(fileURL: url)
        #expect(store.lifts.count == 4)
        #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("unreadable").path))
    }
    
    @Test func duplicateAndBlankLiftNamesAreRejected() {
        let (store, _) = makeStore()
        #expect(store.addLift(named: "squat") == nil)
        #expect(store.addLift(named: "   ") == nil)
    }
    
    @Test func deletingALiftRemovesItsHistory() {
        let (store, _) = makeStore()
        let squat = store.lifts[0]
        store.add(entry(squat, 300, 1))
        store.deleteLift(id: squat.id)
        #expect(store.entries.isEmpty)
    }
}

@MainActor
struct RecentWeightsTests {
    @Test func newestFirstWithoutDuplicates() {
        #expect(RecentWeights.adding(225, to: [135, 225, 315]) == [225, 135, 315])
    }
    
    @Test func keepsOnlyTheLimit() {
        let list = (1...10).map(Double.init)
        #expect(RecentWeights.adding(99, to: list).count == RecentWeights.limit)
    }
    
    @Test func roundTrips() {
        #expect(RecentWeights.decode(RecentWeights.encode([102.5, 135])) == [102.5, 135])
        #expect(RecentWeights.decode("").isEmpty)
    }
}

@MainActor
struct ResultShareCardTests {
    @Test func rendersAtTheCardWidth() throws {
        let renderer = ImageRenderer(content: ResultShareCard(title: "Estimated 1RM", value: "262.4 lb", detail: "225 lb × 5"))
        renderer.scale = 3
        let image = try #require(renderer.uiImage)
        #expect(image.size.width == 360)
        #expect(image.size.height > 100)
        if let path = ProcessInfo.processInfo.environment["SHARE_CARD_PATH"], let data = image.pngData() {
            try data.write(to: URL(filePath: path))
        }
    }
}
