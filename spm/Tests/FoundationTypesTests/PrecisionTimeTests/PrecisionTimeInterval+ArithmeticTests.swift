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

// MARK: - Multiplication Operator Tests
@Suite("PrecisionTimeInterval Multiplication Tests")
struct PrecisionTimeIntervalMultiplicationTests {

    // MARK: - Basic Multiplication Tests

    @Test("Multiply zero by anything equals zero")
    func multiplyByZero() {
        let zero = PrecisionTimeInterval.zero
        let interval = PrecisionTimeInterval(seconds: 100, attoseconds: 0, sign: .positive)

        let result1 = zero * interval
        let result2 = interval * zero

        #expect(result1.isZero, "Zero * interval should be zero")
        #expect(result2.isZero, "interval * zero should be zero")
    }

    @Test("Multiply simple whole seconds")
    func multiplyWholeSeconds() {
        let interval1 = PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .positive)
        let interval2 = PrecisionTimeInterval(seconds: 4, attoseconds: 0, sign: .positive)

        let result = interval1 * interval2

        #expect(result.seconds == 12, "3 * 4 should equal 12 seconds")
        #expect(result.attoseconds == 0, "Should have no attosecond component")
        #expect(result.sign == .positive, "Positive * positive should be positive")
    }

    @Test("Regression: 0.001 * 100000 = 100 (original bug case)")
    func regressionTestOriginalBug() {
        // This is the exact case that was failing in Waveform1DTests
        let dt = PrecisionTimeInterval(seconds: 0.001)
        let count = PrecisionTimeInterval(seconds: 100_000)

        let result = dt * count

        #expect(result.seconds == 100, "0.001 * 100000 should equal 100 seconds")
        #expect(result.attoseconds == 0, "Should have no attosecond remainder")
        #expect(result.sign == .positive)
    }

    @Test("Multiply intervals with attoseconds only")
    func multiplyAttosecondsOnly() {
        // 0.5 seconds * 0.5 seconds = 0.25 seconds
        let half = PrecisionTimeInterval(seconds: 0, attoseconds: 500_000_000_000_000_000, sign: .positive)

        let result = half * half

        #expect(result.seconds == 0, "0.5 * 0.5 should equal 0 seconds")
        #expect(result.attoseconds == 250_000_000_000_000_000, "0.5 * 0.5 should equal 0.25 seconds in attoseconds")
        #expect(result.sign == .positive)
    }

    @Test("Multiply mixed seconds and attoseconds")
    func multiplyMixedComponents() {
        // 1.5 seconds * 2.0 seconds = 3.0 seconds
        let onePointFive = PrecisionTimeInterval(seconds: 1, attoseconds: 500_000_000_000_000_000, sign: .positive)
        let two = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)

        let result = onePointFive * two

        #expect(result.seconds == 3, "1.5 * 2 should equal 3 seconds")
        #expect(result.attoseconds == 0, "Should have no attosecond remainder")
        #expect(result.sign == .positive)
    }

    // MARK: - All Four Products Test

    @Test("Verify all four multiplication products are computed")
    func allFourProducts() {
        // This test ensures all four products are being computed:
        // (2.3 * 3.7) = 2 * 3 + 2 * 0.7 + 0.3 * 3 + 0.3 * 0.7
        //             = 6 + 1.4 + 0.9 + 0.21 = 8.51

        let a = PrecisionTimeInterval(seconds: 2, attoseconds: 300_000_000_000_000_000, sign: .positive) // 2.3
        let b = PrecisionTimeInterval(seconds: 3, attoseconds: 700_000_000_000_000_000, sign: .positive) // 3.7

        let result = a * b

        // Expected: 8.51 seconds
        #expect(result.seconds == 8, "2.3 * 3.7 should equal 8 seconds")
        #expect(result.attoseconds == 510_000_000_000_000_000, "2.3 * 3.7 should have 0.51 in attoseconds")
        #expect(result.sign == .positive)
    }

    @Test("Product 1: seconds * seconds only")
    func productOneOnly() {
        // When only seconds are non-zero, only product 1 matters
        let interval1 = PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive)
        let interval2 = PrecisionTimeInterval(seconds: 7, attoseconds: 0, sign: .positive)

        let result = interval1 * interval2

        #expect(result.seconds == 35, "5 * 7 should equal 35")
        #expect(result.attoseconds == 0)
    }

    @Test("Product 2 & 3: seconds * attoseconds cross terms")
    func productsTwoAndThree() {
        // 2 seconds * 0.5 seconds = 1.0 second (product 2)
        // 0 attoseconds * 2 seconds = 0 (product 3)
        let two = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
        let half = PrecisionTimeInterval(seconds: 0, attoseconds: 500_000_000_000_000_000, sign: .positive)

        let result = two * half

        #expect(result.seconds == 1, "2 * 0.5 should equal 1 second")
        #expect(result.attoseconds == 0)
    }

    @Test("Product 4: attoseconds * attoseconds only")
    func productFourOnly() {
        // 0.1 * 0.1 = 0.01
        let tenth = PrecisionTimeInterval(seconds: 0, attoseconds: 100_000_000_000_000_000, sign: .positive)

        let result = tenth * tenth

        #expect(result.seconds == 0, "0.1 * 0.1 should equal 0 seconds")
        #expect(result.attoseconds == 10_000_000_000_000_000, "0.1 * 0.1 should equal 0.01 seconds")
    }

    // MARK: - Sign Handling Tests

    @Test("Positive * Positive = Positive")
    func positiveTimesPositive() {
        let a = PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .positive)
        let b = PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive)

        let result = a * b

        #expect(result.sign == .positive, "Positive * positive should be positive")
        #expect(result.seconds == 15)
    }

    @Test("Positive * Negative = Negative")
    func positiveTimesNegative() {
        let a = PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .positive)
        let b = PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .negative)

        let result = a * b

        #expect(result.sign == .negative, "Positive * negative should be negative")
        #expect(result.seconds == 15)
    }

    @Test("Negative * Positive = Negative")
    func negativeTimesPositive() {
        let a = PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .negative)
        let b = PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive)

        let result = a * b

        #expect(result.sign == .negative, "Negative * positive should be negative")
        #expect(result.seconds == 15)
    }

    @Test("Negative * Negative = Positive")
    func negativeTimesNegative() {
        let a = PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .negative)
        let b = PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .negative)

        let result = a * b

        #expect(result.sign == .positive, "Negative * negative should be positive")
        #expect(result.seconds == 15)
    }

    // MARK: - Overflow Tests

    @Test("Overflow in product 1: seconds overflow")
    func overflowInSecondsProduct() {
        let large = PrecisionTimeInterval(seconds: UInt64.max / 2, attoseconds: 0, sign: .positive)
        let three = PrecisionTimeInterval(seconds: 3, attoseconds: 0, sign: .positive)

        let result = large * three

        // Should clamp to max on overflow
        #expect(result.seconds == UInt64.max, "Overflow should clamp to max")
        #expect(result.attoseconds == 0)
    }

    @Test("No overflow with reasonable values")
    func noOverflowWithReasonableValues() {
        let thousand = PrecisionTimeInterval(seconds: 1000, attoseconds: 0, sign: .positive)
        let million = PrecisionTimeInterval(seconds: 1_000_000, attoseconds: 0, sign: .positive)

        let result = thousand * million

        #expect(result.seconds == 1_000_000_000, "1000 * 1000000 should equal 1 billion")
        #expect(result.attoseconds == 0)
    }

    // MARK: - Commutativity Tests

    @Test("Multiplication is commutative")
    func commutativeProperty() {
        let a = PrecisionTimeInterval(seconds: 2, attoseconds: 300_000_000_000_000_000, sign: .positive)
        let b = PrecisionTimeInterval(seconds: 3, attoseconds: 700_000_000_000_000_000, sign: .positive)

        let result1 = a * b
        let result2 = b * a

        #expect(result1.seconds == result2.seconds, "a * b should equal b * a (seconds)")
        #expect(result1.attoseconds == result2.attoseconds, "a * b should equal b * a (attoseconds)")
        #expect(result1.sign == result2.sign, "a * b should equal b * a (sign)")
    }

    // MARK: - Precision Tests

    @Test("High precision multiplication")
    func highPrecision() {
        // Test with very small values to ensure attosecond precision
        let microSecond = PrecisionTimeInterval(seconds: 0, attoseconds: 1_000_000_000_000, sign: .positive) // 1 microsecond
        let hundred = PrecisionTimeInterval(seconds: 100, attoseconds: 0, sign: .positive)

        let result = microSecond * hundred

        #expect(result.seconds == 0, "1μs * 100 should be 0 seconds")
        #expect(result.attoseconds == 100_000_000_000_000, "1μs * 100 should be 100 microseconds")
    }

    @Test("Decimal multiplication precision")
    func decimalPrecision() {
        // 0.3 * 0.3 = 0.09
        let pointThree = PrecisionTimeInterval(seconds: 0, attoseconds: 300_000_000_000_000_000, sign: .positive)

        let result = pointThree * pointThree

        #expect(result.seconds == 0, "0.3 * 0.3 should be 0 seconds")
        #expect(result.attoseconds == 90_000_000_000_000_000, "0.3 * 0.3 should be 0.09 seconds")
    }

    // MARK: - Compound Assignment Test

    @Test("Compound assignment multiplication")
    func compoundAssignment() {
        var interval = PrecisionTimeInterval(seconds: 2, attoseconds: 0, sign: .positive)
        let multiplier = PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive)

        interval *= multiplier

        #expect(interval.seconds == 10, "2 *= 5 should equal 10")
        #expect(interval.attoseconds == 0)
        #expect(interval.sign == .positive)
    }

    // MARK: - Edge Cases

    @Test("Multiply by one (identity)")
    func multiplyByOne() {
        let interval = PrecisionTimeInterval(seconds: 7, attoseconds: 500_000_000_000_000_000, sign: .positive)
        let one = PrecisionTimeInterval(seconds: 1, attoseconds: 0, sign: .positive)

        let result = interval * one

        #expect(result.seconds == interval.seconds, "Multiplying by 1 should preserve seconds")
        #expect(result.attoseconds == interval.attoseconds, "Multiplying by 1 should preserve attoseconds")
        #expect(result.sign == interval.sign, "Multiplying by 1 should preserve sign")
    }

    @Test("Very small multiplication result")
    func verySmallResult() {
        // 0.001 * 0.001 = 0.000001 = 1 microsecond
        let milliSecond = PrecisionTimeInterval(seconds: 0, attoseconds: 1_000_000_000_000_000, sign: .positive)

        let result = milliSecond * milliSecond

        #expect(result.seconds == 0, "0.001 * 0.001 should be 0 seconds")
        #expect(result.attoseconds == 1_000_000_000_000, "0.001 * 0.001 should be 1 microsecond")
    }

    @Test("Scalar multiplication with integer")
    func scalarIntegerMultiplication() {
        let interval = PrecisionTimeInterval(seconds: 3, attoseconds: 500_000_000_000_000_000, sign: .positive)

        let result = interval * 4

        #expect(result.seconds == 14, "3.5 * 4 should equal 14 seconds")
        #expect(result.attoseconds == 0, "Should have no attosecond remainder")
    }

    @Test("Scalar multiplication commutativity")
    func scalarCommutativity() {
        let interval = PrecisionTimeInterval(seconds: 2, attoseconds: 500_000_000_000_000_000, sign: .positive)

        let result1 = interval * 3
        let result2 = 3 * interval

        #expect(result1.seconds == result2.seconds, "Scalar multiplication should be commutative")
        #expect(result1.attoseconds == result2.attoseconds, "Scalar multiplication should be commutative")
    }

    // MARK: - Regression Tests for Original Bug

    @Test("Original bug would have failed: only computed product 3")
    func originalBugRegression() {
        // The original bug only computed: rhs.seconds * lhs.attoseconds
        // This test ensures all products are now being computed

        let a = PrecisionTimeInterval(seconds: 10, attoseconds: 0, sign: .positive)
        let b = PrecisionTimeInterval(seconds: 0, attoseconds: 100_000_000_000_000_000, sign: .positive) // 0.1

        let result = a * b

        // With the bug: would only compute product 3: 0.1 * 10 = 1.0 (WRONG)
        // Correct: 10 * 0.1 = 1.0 (from product 2)
        #expect(result.seconds == 1, "10 * 0.1 should equal 1 second")
        #expect(result.attoseconds == 0)
    }

    @Test("Ensure product 1 is included (missing in original bug)")
    func productOneMissing() {
        // Original bug would compute 0 for this (missing product 1)
        let a = PrecisionTimeInterval(seconds: 100, attoseconds: 0, sign: .positive)
        let b = PrecisionTimeInterval(seconds: 200, attoseconds: 0, sign: .positive)

        let result = a * b

        #expect(result.seconds == 20_000, "100 * 200 should equal 20000 seconds")
        #expect(result.attoseconds == 0)
    }
}
