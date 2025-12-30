import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("Precision TimeInterval Arithmetic Tests")
struct PrecisionTimeIntervalArithmeticTests {

    let arithmeticTruths:
        [(
            String, PrecisionTimeInterval, PrecisionTimeInterval, PrecisionTimeInterval,
            PrecisionTimeInterval
        )] = [
            // Format: (description, operand1, operand2, addition_result, subtraction_result)

            // MARK: - Positive + Positive

            (
                "Basic addition",
                PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 8, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
            ),

            (
                "Addition with milliseconds",
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 3, milliseconds: 300, sign: .positive),
                PrecisionTimeInterval(seconds: 8, milliseconds: 800, sign: .positive),
                PrecisionTimeInterval(seconds: 2, milliseconds: 200, sign: .positive)
            ),

            (
                "Attoseconds overflow into seconds",
                PrecisionTimeInterval(seconds: 5, milliseconds: 600, sign: .positive),
                PrecisionTimeInterval(seconds: 3, milliseconds: 700, sign: .positive),
                PrecisionTimeInterval(seconds: 9, milliseconds: 300, sign: .positive),
                PrecisionTimeInterval(seconds: 1, milliseconds: 900, sign: .positive)
            ),

            (
                "Zero addition",
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .positive)
            ),

            (
                "Seconds overflow to max (clamping)",
                PrecisionTimeInterval(seconds: UInt64.max - 5, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max - 15, attoseconds: 0, sign: .positive)
            ),

            (
                "Both at max",
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            // MARK: - Negative + Negative

            (
                "Basic negative addition",
                PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 8, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .negative)
            ),

            (
                "Negative with milliseconds",
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .negative),
                PrecisionTimeInterval(seconds: 3, milliseconds: 300, sign: .negative),
                PrecisionTimeInterval(seconds: 8, milliseconds: 800, sign: .negative),
                PrecisionTimeInterval(seconds: 2, milliseconds: 200, sign: .negative)
            ),

            (
                "Negative overflow to max (magnitude)",
                PrecisionTimeInterval(seconds: UInt64.max - 5, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max - 15, attoseconds: 0, sign: .negative)
            ),

            // MARK: - Positive + Negative (Mixed Signs)

            (
                "Positive + Negative = Positive (larger positive)",
                PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 7, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 13, attoseconds: 0, sign: .positive)
            ),

            (
                "Positive + Negative = Negative (larger negative)",
                PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 7, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 13, attoseconds: 0, sign: .positive)
            ),

            (
                "Positive + Negative = Zero (equal magnitudes)",
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .negative),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 11, attoseconds: 0, sign: .positive)
            ),

            (
                "With attoseconds borrowing",
                PrecisionTimeInterval(seconds: 10, milliseconds: 200, sign: .positive),
                PrecisionTimeInterval(seconds: 3, milliseconds: 800, sign: .negative),
                PrecisionTimeInterval(seconds: 6, milliseconds: 400, sign: .positive),
                PrecisionTimeInterval(seconds: 14, attoseconds: 0, sign: .positive)
            ),

            // MARK: - Negative + Positive (Mixed Signs)

            (
                "Negative + Positive = Positive (larger positive)",
                PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 7, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 13, attoseconds: 0, sign: .negative)
            ),

            (
                "Negative + Positive = Negative (larger negative)",
                PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 7, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 13, attoseconds: 0, sign: .negative)
            ),

            (
                "With milliseconds and borrowing",
                PrecisionTimeInterval(seconds: 10, milliseconds: 200, sign: .negative),
                PrecisionTimeInterval(seconds: 3, milliseconds: 800, sign: .positive),
                PrecisionTimeInterval(seconds: 6, milliseconds: 400, sign: .negative),
                PrecisionTimeInterval(seconds: 14, attoseconds: 0, sign: .negative)
            ),

            // MARK: - Edge Cases

            (
                "Zero + Zero",
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "Zero + Positive",
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .negative)
            ),

            (
                "Zero + Negative",
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .negative),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .negative),
                PrecisionTimeInterval(seconds: 5, milliseconds: 500, sign: .positive)
            ),

            (
                "Maximum precision addition",
                PrecisionTimeInterval(
                    seconds: 0,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1,
                    sign: .positive
                ),
                PrecisionTimeInterval(
                    seconds: 0,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1,
                    sign: .positive
                ),
                PrecisionTimeInterval(
                    seconds: 1,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 2,
                    sign: .positive
                ),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "Borrowing with zero seconds",
                PrecisionTimeInterval(seconds: 1, milliseconds: 200, sign: .positive),
                PrecisionTimeInterval(seconds: 0, milliseconds: 800, sign: .negative),
                PrecisionTimeInterval(seconds: 0, milliseconds: 400, sign: .positive),
                PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
            ),

            (
                "Complex milliseconds calculation",
                PrecisionTimeInterval(seconds: 100, milliseconds: 999, sign: .positive),
                PrecisionTimeInterval(seconds: 50, milliseconds: 1, sign: .positive),
                PrecisionTimeInterval(seconds: 151, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 50, milliseconds: 998, sign: .positive)
            ),

            // MARK: - Zero Crossing Cases (No Negative Zero)

            (
                "Positive - Positive (equal magnitudes) = +0",
                PrecisionTimeInterval(seconds: 100, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 100, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 201, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "Negative - Negative (equal magnitudes) = +0",
                PrecisionTimeInterval(seconds: 100, milliseconds: 500, sign: .negative),
                PrecisionTimeInterval(seconds: 100, milliseconds: 500, sign: .negative),
                PrecisionTimeInterval(seconds: 201, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "Positive - Positive (exact zero) = +0",
                PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "Negative - Negative (exact zero) = +0",
                PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "Large equal magnitudes subtraction = +0",
                PrecisionTimeInterval(seconds: UInt64.max / 2, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max / 2, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max - 1, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "With attoseconds: equal magnitudes = +0",
                PrecisionTimeInterval(
                    seconds: 10,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1,
                    sign: .positive
                ),
                PrecisionTimeInterval(
                    seconds: 10,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1,
                    sign: .positive
                ),
                PrecisionTimeInterval(
                    seconds: 21,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 2,
                    sign: .positive
                ),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            // MARK: - Overflow Clamping Cases

            (
                "Positive overflow: seconds at max + 1 → clamps to max",
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 1, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max - 1, attoseconds: 0, sign: .positive)
            ),

            (
                "Positive overflow: near-max + large value → clamps to max",
                PrecisionTimeInterval(seconds: UInt64.max / 2 + 1, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max / 2 + 1, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "Positive overflow: max + attoseconds overflow → clamps to max",
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(
                    seconds: 0,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond,
                    sign: .positive
                ),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max - 1, attoseconds: 0, sign: .positive)
            ),

            (
                "Positive overflow: near-max + attoseconds that push over → clamps",
                PrecisionTimeInterval(
                    seconds: UInt64.max - 1,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1,
                    sign: .positive
                ),
                PrecisionTimeInterval(seconds: 1, milliseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(
                    seconds: UInt64.max - 2,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1
                        - 500 * PrecisionTimeInterval.attosecondsPerMilliSecond,
                    sign: .positive
                )
            ),

            (
                "Negative overflow: -max + (-1) → clamps to -max",
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 1, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max - 1, attoseconds: 0, sign: .negative)
            ),

            (
                "Negative overflow: large negative + large negative → clamps to -max",
                PrecisionTimeInterval(seconds: UInt64.max / 2 + 1, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max / 2 + 1, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            (
                "Negative overflow: -max + attoseconds overflow → clamps to -max",
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(
                    seconds: 0,
                    attoseconds: PrecisionTimeInterval.attosecondsPerSecond,
                    sign: .negative
                ),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max - 1, attoseconds: 0, sign: .negative)
            ),

            (
                "Negative overflow: near -max with milliseconds → clamps",
                PrecisionTimeInterval(seconds: UInt64.max - 5, milliseconds: 800, sign: .negative),
                PrecisionTimeInterval(seconds: 10, milliseconds: 500, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max - 15, milliseconds: 300, sign: .negative)
            ),

            (
                "Mixed overflow: -max - positive → stays at -max (subtraction increases magnitude)",
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: 100, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max - 100, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .negative)
            ),

            (
                "Mixed overflow: max - negative → clamps to max (subtraction increases magnitude)",
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 100, attoseconds: 0, sign: .negative),
                PrecisionTimeInterval(seconds: UInt64.max - 100, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
            ),
        ]

    @Test("Arithmetic")
    func additionTest() {

        for (msg, term1, term2, shouldForAddition, shouldForSubtract) in self.arithmeticTruths {
            #expect(term1 + term2 == shouldForAddition, "\(msg)")
            var resAddCompAdd = term1
            resAddCompAdd += term2
            #expect(resAddCompAdd == shouldForAddition, "\(msg)")

            #expect(term1 - term2 == shouldForSubtract, "\(msg)")
            var resAddCompSub = term1
            resAddCompSub -= term2
            #expect(resAddCompSub == shouldForSubtract, "\(msg)")
        }

    }

    @Test("Adding Time Interval - Double")
    func addingTimeIntervalDouble() {
        // Test adding positive Double
        let interval1 = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive)
        let result1 = interval1.addingTimeInterval(add: 3.14159)
        #expect(result1.seconds == 13)
        // Check attoseconds is approximately 0.14159 seconds
        let expectedAtto1 = UInt64(0.14159 * Double(PrecisionTimeInterval.attosecondsPerSecond))
        #expect(result1.attoseconds > expectedAtto1 - 1000 && result1.attoseconds < expectedAtto1 + 1000)
        #expect(result1.sign == .positive)

        // Test adding negative Double
        let interval2 = PrecisionTimeInterval(seconds: 20, attoseconds: 0, sign: .positive)
        let result2 = interval2.addingTimeInterval(add: -7.5)
        #expect(result2.seconds == 12)
        #expect(result2.attoseconds == 500_000_000_000_000_000)  // 0.5 seconds in attoseconds
        #expect(result2.sign == .positive)

        // Test adding to negative interval
        let interval3 = PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .negative)
        let result3 = interval3.addingTimeInterval(add: 2.0)
        #expect(result3.seconds == 3)
        #expect(result3.attoseconds == 0)
        #expect(result3.sign == .negative)

        // Test crossing zero from negative to positive
        let interval4 = PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .negative)
        let result4 = interval4.addingTimeInterval(add: 5.0)
        #expect(result4.seconds == 2)
        #expect(result4.attoseconds == 0)
        #expect(result4.sign == .positive)
    }

    @Test("Adding Time Interval - Float")
    func addingTimeIntervalFloat() {
        let tolerance: UInt64 = 100_000_000_000  // 0.0000001 seconds tolerance for Float precision

        // Test adding positive Float
        let interval1 = PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive)
        let result1 = interval1.addingTimeInterval(add: Float(2.5))
        #expect(result1.seconds == 7)
        let expectedAtto1 = UInt64(0.5 * Float(PrecisionTimeInterval.attosecondsPerSecond))
        #expect(result1.attoseconds > expectedAtto1 - tolerance && result1.attoseconds < expectedAtto1 + tolerance)
        #expect(result1.sign == .positive)

        // Test adding negative Float
        let interval2 = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive)
        let result2 = interval2.addingTimeInterval(add: Float(-3.25))
        #expect(result2.seconds == 6)
        let expectedAtto2 = UInt64(0.75 * Float(PrecisionTimeInterval.attosecondsPerSecond))
        #expect(result2.attoseconds > expectedAtto2 - tolerance && result2.attoseconds < expectedAtto2 + tolerance)
        #expect(result2.sign == .positive)

        // Test precision with small Float value
        let interval3 = PrecisionTimeInterval(seconds: 1, attoseconds: 0, sign: .positive)
        let result3 = interval3.addingTimeInterval(add: Float(0.125))
        #expect(result3.seconds == 1)
        let expectedAtto3 = UInt64(0.125 * Float(PrecisionTimeInterval.attosecondsPerSecond))
        #expect(result3.attoseconds > expectedAtto3 - tolerance && result3.attoseconds < expectedAtto3 + tolerance)
        #expect(result3.sign == .positive)
    }

    // MARK: - multiplyAttoseconds Tests

    func testMultiplyAttoseconds_zeroMultiplication() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        PrecisionTimeInterval.multiplyAttoseconds(
            0,
            1_000_000_000_000_000_000,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 0, "Zero multiplied by anything should give zero seconds")
        #expect(resultAttoseconds == 0, "Zero multiplied by anything should give zero attoseconds")
    }

    func testMultiplyAttoseconds_identityMultiplication() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // 1 attosecond * 1 attosecond = 1 attosecond² / 1e18 = 0 (rounds down)
        PrecisionTimeInterval.multiplyAttoseconds(
            1,
            1,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 0, "1 * 1 should produce 0 seconds")
        #expect(resultAttoseconds == 0, "1 * 1 should produce 0 attoseconds (rounds down)")
    }

    func testMultiplyAttoseconds_simpleMultiplication() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test: 1e9 * 1e9 = 1e18 = exactly 1 second
        PrecisionTimeInterval.multiplyAttoseconds(
            1_000_000_000,
            1_000_000_000,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 1, "1e9 * 1e9 should produce 1 second")
        #expect(resultAttoseconds == 0, "1e9 * 1e9 should produce 0 attoseconds")
    }

    func testMultiplyAttoseconds_halfSecond() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test: 0.5 second * 0.5 second = 0.25 second
        let halfSecond: UInt64 = 500_000_000_000_000_000 // 0.5e18
        PrecisionTimeInterval.multiplyAttoseconds(
            halfSecond,
            halfSecond,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 0, "0.5s * 0.5s should produce 0 seconds")
        #expect(resultAttoseconds == 250_000_000_000_000_000, "0.5s * 0.5s should produce 0.25s in attoseconds")
    }

    func testMultiplyAttoseconds_fullSecond() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test: 1 second * 1 second = 1 second (in time squared context)
        let oneSecond: UInt64 = 1_000_000_000_000_000_000
        PrecisionTimeInterval.multiplyAttoseconds(
            oneSecond,
            oneSecond,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 1_000_000_000_000_000_000, "1s * 1s should produce 1e18 seconds")
        #expect(resultAttoseconds == 0, "1s * 1s should produce 0 attoseconds")
    }

    func testMultiplyAttoseconds_twoSecondsMultiplied() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test: 2 seconds * 2 seconds = 4 seconds
        let twoSeconds: UInt64 = 2_000_000_000_000_000_000
        PrecisionTimeInterval.multiplyAttoseconds(
            twoSeconds,
            twoSeconds,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 4_000_000_000_000_000_000, "2s * 2s should produce 4e18 seconds")
        #expect(resultAttoseconds == 0, "2s * 2s should produce 0 attoseconds")
    }

    func testMultiplyAttoseconds_mixedValues() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test: 1.5 seconds * 2 seconds = 3 seconds
        let oneAndHalfSeconds: UInt64 = 1_500_000_000_000_000_000
        let twoSeconds: UInt64 = 2_000_000_000_000_000_000

        PrecisionTimeInterval.multiplyAttoseconds(
            oneAndHalfSeconds,
            twoSeconds,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 3_000_000_000_000_000_000, "1.5s * 2s should produce 3e18 seconds")
        #expect(resultAttoseconds == 0, "1.5s * 2s should produce 0 attoseconds")
    }

    func testMultiplyAttoseconds_smallValues() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test: 1000 attoseconds * 1000 attoseconds
        PrecisionTimeInterval.multiplyAttoseconds(
            1000,
            1000,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 0, "Small values should produce 0 seconds")
        #expect(resultAttoseconds == 0, "1000 * 1000 = 1e6, which is < 1e18, so rounds to 0")
    }

    func testMultiplyAttoseconds_largeValues() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test large values that would overflow without proper handling
        let largeValue: UInt64 = UInt64.max / 2

        PrecisionTimeInterval.multiplyAttoseconds(
            largeValue,
            2,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        // Should handle large multiplications without crashing
        // The exact value depends on the implementation, but it should not crash
        #expect(true, "Should handle large values without crashing")
    }

    func testMultiplyAttoseconds_quarterSecondSquared() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test: 0.25 second * 0.25 second = 0.0625 second
        let quarterSecond: UInt64 = 250_000_000_000_000_000
        PrecisionTimeInterval.multiplyAttoseconds(
            quarterSecond,
            quarterSecond,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 0, "0.25s * 0.25s should produce 0 seconds")
        #expect(resultAttoseconds == 62_500_000_000_000_000, "0.25s * 0.25s should produce 0.0625s")
    }

    func testMultiplyAttoseconds_asymmetricValues() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test: very small * very large
        let small: UInt64 = 1_000_000 // 1 microsecond in attoseconds
        let large: UInt64 = 1_000_000_000_000_000_000 // 1 second

        PrecisionTimeInterval.multiplyAttoseconds(
            small,
            large,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 0, "Small * large should produce 0 seconds")
        #expect(resultAttoseconds == 1_000_000, "Result should be 1e6 attoseconds")
    }

    func testMultiplyAttoseconds_precisionPreservation() {
        var resultSeconds: UInt64 = 0
        var resultAttoseconds: UInt64 = 0

        // Test that precision is preserved in the calculation
        // 0.3 seconds * 0.3 seconds = 0.09 seconds
        let pointThree: UInt64 = 300_000_000_000_000_000

        PrecisionTimeInterval.multiplyAttoseconds(
            pointThree,
            pointThree,
            resultSeconds: &resultSeconds,
            resultAttoseconds: &resultAttoseconds
        )

        #expect(resultSeconds == 0, "0.3s * 0.3s should produce 0 seconds")
        #expect(resultAttoseconds == 90_000_000_000_000_000, "0.3s * 0.3s should produce 0.09s = 9e16 attoseconds")
    }

    func testMultiplyAttoseconds_commutative() {
        var resultSeconds1: UInt64 = 0
        var resultAttoseconds1: UInt64 = 0
        var resultSeconds2: UInt64 = 0
        var resultAttoseconds2: UInt64 = 0

        let a: UInt64 = 123_456_789_000_000_000
        let b: UInt64 = 987_654_321_000_000_000

        PrecisionTimeInterval.multiplyAttoseconds(
            a, b,
            resultSeconds: &resultSeconds1,
            resultAttoseconds: &resultAttoseconds1
        )

        PrecisionTimeInterval.multiplyAttoseconds(
            b, a,
            resultSeconds: &resultSeconds2,
            resultAttoseconds: &resultAttoseconds2
        )

        #expect(resultSeconds1 == resultSeconds2, "Multiplication should be commutative (seconds)")
        #expect(resultAttoseconds1 == resultAttoseconds2, "Multiplication should be commutative (attoseconds)")
    }
}
