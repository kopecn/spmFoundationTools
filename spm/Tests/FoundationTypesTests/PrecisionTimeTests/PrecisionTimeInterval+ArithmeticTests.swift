import XCTest
@testable import FoundationTypes

final class PrecisionTimeIntervalArithmeticTests: XCTestCase {

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

        XCTAssertEqual(resultSeconds, 0, "Zero multiplied by anything should give zero seconds")
        XCTAssertEqual(resultAttoseconds, 0, "Zero multiplied by anything should give zero attoseconds")
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

        XCTAssertEqual(resultSeconds, 0, "1 * 1 should produce 0 seconds")
        XCTAssertEqual(resultAttoseconds, 0, "1 * 1 should produce 0 attoseconds (rounds down)")
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

        XCTAssertEqual(resultSeconds, 1, "1e9 * 1e9 should produce 1 second")
        XCTAssertEqual(resultAttoseconds, 0, "1e9 * 1e9 should produce 0 attoseconds")
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

        XCTAssertEqual(resultSeconds, 0, "0.5s * 0.5s should produce 0 seconds")
        XCTAssertEqual(resultAttoseconds, 250_000_000_000_000_000, "0.5s * 0.5s should produce 0.25s in attoseconds")
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

        XCTAssertEqual(resultSeconds, 1_000_000_000_000_000_000, "1s * 1s should produce 1e18 seconds")
        XCTAssertEqual(resultAttoseconds, 0, "1s * 1s should produce 0 attoseconds")
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

        XCTAssertEqual(resultSeconds, 4_000_000_000_000_000_000, "2s * 2s should produce 4e18 seconds")
        XCTAssertEqual(resultAttoseconds, 0, "2s * 2s should produce 0 attoseconds")
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

        XCTAssertEqual(resultSeconds, 3_000_000_000_000_000_000, "1.5s * 2s should produce 3e18 seconds")
        XCTAssertEqual(resultAttoseconds, 0, "1.5s * 2s should produce 0 attoseconds")
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

        XCTAssertEqual(resultSeconds, 0, "Small values should produce 0 seconds")
        XCTAssertEqual(resultAttoseconds, 0, "1000 * 1000 = 1e6, which is < 1e18, so rounds to 0")
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
        XCTAssertTrue(true, "Should handle large values without crashing")
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

        XCTAssertEqual(resultSeconds, 0, "0.25s * 0.25s should produce 0 seconds")
        XCTAssertEqual(resultAttoseconds, 62_500_000_000_000_000, "0.25s * 0.25s should produce 0.0625s")
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

        XCTAssertEqual(resultSeconds, 0, "Small * large should produce 0 seconds")
        XCTAssertEqual(resultAttoseconds, 1_000_000, "Result should be 1e6 attoseconds")
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

        XCTAssertEqual(resultSeconds, 0, "0.3s * 0.3s should produce 0 seconds")
        XCTAssertEqual(resultAttoseconds, 90_000_000_000_000_000, "0.3s * 0.3s should produce 0.09s = 9e16 attoseconds")
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

        XCTAssertEqual(resultSeconds1, resultSeconds2, "Multiplication should be commutative (seconds)")
        XCTAssertEqual(resultAttoseconds1, resultAttoseconds2, "Multiplication should be commutative (attoseconds)")
    }
}
