import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("Precision TimeInterval Initialization Tests")
struct PrecisionTimeIntervalInitializationTests {

    let initTruths: [(String, PrecisionTimeInterval, PrecisionTimeInterval)] = [
        // Note: - Sign cases have no impact

        (
            "// Basic attoseconds overflow wrapping",
            PrecisionTimeInterval(
                seconds: 15,
                attoseconds: PrecisionTimeInterval.attosecondsPerSecond * 5 + 4,
                sign: .positive
            ),
            PrecisionTimeInterval(seconds: 20, attoseconds: 4, sign: .positive)
        ),

        (
            "// Seconds overflow to max (seconds near max + attoseconds overflow)",
            PrecisionTimeInterval(
                seconds: UInt64.max - 1,
                attoseconds: PrecisionTimeInterval.attosecondsPerSecond * 2,
                sign: .positive
            ),
            PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
        ),

        (
            "// Seconds already at max with attoseconds overflow",
            PrecisionTimeInterval(
                seconds: UInt64.max,
                attoseconds: PrecisionTimeInterval.attosecondsPerSecond,
                sign: .positive
            ),
            PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
        ),

        (
            "// Seconds already at max with attoseconds above 0",
            PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 1, sign: .positive),
            PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
        ),

        (
            "// No overflow - exact values preserved",
            PrecisionTimeInterval(seconds: 10, attoseconds: 500, sign: .positive),
            PrecisionTimeInterval(seconds: 10, attoseconds: 500, sign: .positive)
        ),

        (
            "// Zero case",
            PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
            PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
        ),

        (
            "// Maximum valid attoseconds without overflow",
            PrecisionTimeInterval(
                seconds: 0,
                attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1,
                sign: .positive
            ),
            PrecisionTimeInterval(
                seconds: 0,
                attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1,
                sign: .positive
            )
        ),

        (
            "// Large attoseconds value wrapping into seconds",
            PrecisionTimeInterval(seconds: 0, attoseconds: UInt64.max, sign: .positive),
            PrecisionTimeInterval(seconds: 18, attoseconds: 446_744_073_709_551_615, sign: .positive)
        ),

        (
            "// Milliseconds init - normal case",
            PrecisionTimeInterval(seconds: 5, milliseconds: 1500, sign: .positive),
            PrecisionTimeInterval(
                seconds: 6,
                attoseconds: 500 * PrecisionTimeInterval.attosecondsPerMilliSecond,
                sign: .positive
            )
        ),

        (
            "// Milliseconds init - seconds overflow detection",
            PrecisionTimeInterval(seconds: UInt64.max, milliseconds: 1000, sign: .positive),
            PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
        ),

        (
            "// Milliseconds init - large milliseconds value",
            PrecisionTimeInterval(seconds: 0, milliseconds: 5_000, sign: .positive),
            PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive)
        ),
    ]

    @Test("Ensure Clamping")
    func initializationTest() {

        for (msg, shouldwrap, iswrapped) in initTruths {
            #expect(shouldwrap == iswrapped, "\(msg)")
        }
    }
}

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
                PrecisionTimeInterval(seconds: UInt64.max - 15, milliseconds: 300,sign: .negative)
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
        #expect(result2.attoseconds == 500_000_000_000_000_000) // 0.5 seconds in attoseconds
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
        let tolerance: UInt64 = 100_000_000_000 // 0.0000001 seconds tolerance for Float precision

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
}
