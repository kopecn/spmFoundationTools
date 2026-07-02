import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("Arithmetic Initialization")
struct PrecisionTimestampTests {

    @Test("Addition")
    func basicInitializationFloat() {

        let additionTruths: [(PrecisionTimestamp, PrecisionTimeInterval, PrecisionTimestamp)] = [
            (
                PrecisionTimestamp(seconds: 15, attoseconds: 15),
                PrecisionTimeInterval(seconds: 10, attoseconds: 10, sign: .positive),
                PrecisionTimestamp(seconds: 25, attoseconds: 25)
            )
        ]

        for (lhs, rhs, res) in additionTruths {

            #expect(lhs + rhs == res)
        }
    }

    @Test("Adding Time Interval - Double")
    func addingTimeIntervalDouble() {
        // Test adding positive Double
        let timestamp1 = PrecisionTimestamp(seconds: 100, attoseconds: 0, sign: .positive)
        let result1 = timestamp1.addingTimeInterval(add: 2.5)
        #expect(result1.seconds == 102)
        #expect(result1.attoseconds == 500_000_000_000_000_000)  // 0.5 seconds in attoseconds
        #expect(result1.sign == .positive)

        // Test adding negative Double
        let timestamp2 = PrecisionTimestamp(seconds: 100, attoseconds: 0, sign: .positive)
        let result2 = timestamp2.addingTimeInterval(add: -5.5)
        #expect(result2.seconds == 94)
        #expect(result2.attoseconds == 500_000_000_000_000_000)
        #expect(result2.sign == .positive)

        // Test adding fractional seconds with precision
        let timestamp3 = PrecisionTimestamp(seconds: 50, attoseconds: 0, sign: .positive)
        let result3 = timestamp3.addingTimeInterval(add: 3.14159)
        #expect(result3.seconds == 53)
        // Check attoseconds is approximately 0.14159 seconds
        let expectedAtto = UInt64(0.14159 * Double(PrecisionTimeInterval.attosecondsPerSecond))
        #expect(result3.attoseconds > expectedAtto - 1000 && result3.attoseconds < expectedAtto + 1000)
    }

    @Test("Adding Time Interval - Float")
    func addingTimeIntervalFloat() {
        // Test adding positive Float
        let timestamp1 = PrecisionTimestamp(seconds: 10, attoseconds: 0, sign: .positive)
        let result1 = timestamp1.addingTimeInterval(add: Float(1.25))
        #expect(result1.seconds == 11)
        // Float has less precision, so allow tolerance
        let expectedAtto1 = UInt64(0.25 * Float(PrecisionTimeInterval.attosecondsPerSecond))
        let tolerance1: UInt64 = 100_000_000_000  // 0.0000001 seconds tolerance for Float precision
        #expect(result1.attoseconds > expectedAtto1 - tolerance1 && result1.attoseconds < expectedAtto1 + tolerance1)
        #expect(result1.sign == .positive)

        // Test adding negative Float
        let timestamp2 = PrecisionTimestamp(seconds: 20, attoseconds: 0, sign: .positive)
        let result2 = timestamp2.addingTimeInterval(add: Float(-3.75))
        #expect(result2.seconds == 16)
        let expectedAtto2 = UInt64(0.25 * Float(PrecisionTimeInterval.attosecondsPerSecond))
        let tolerance2: UInt64 = 10_000_000_000_000_000
        #expect(result2.attoseconds > expectedAtto2 - tolerance2 && result2.attoseconds < expectedAtto2 + tolerance2)
        #expect(result2.sign == .positive)
    }
}
