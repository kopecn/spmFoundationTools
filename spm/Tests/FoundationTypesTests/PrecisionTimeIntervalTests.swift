import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("Clamping Initialization")
struct PrecisionTimeIntervalTests {

    @Test("Ensure Clamping")
    func basicInitializationFloat() {

        let truths: [(PrecisionTimeInterval, PrecisionTimeInterval)] = [
            // Note: - Sign cases have no impact

            // Basic attoseconds overflow wrapping
            (
                PrecisionTimeInterval(seconds: 15, attoseconds: PrecisionTimeInterval.attosecondsPerSecond * 5 + 4, sign: .positive),
                PrecisionTimeInterval(seconds: 20, attoseconds: 4, sign: .positive)
            ),

            // Seconds overflow to max (seconds near max + attoseconds overflow)
            (
                PrecisionTimeInterval(seconds: UInt64.max - 1, attoseconds: PrecisionTimeInterval.attosecondsPerSecond * 2, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
            ),

            // Seconds already at max with attoseconds overflow
            (
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: PrecisionTimeInterval.attosecondsPerSecond, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
            ),

            // Seconds already at max with attoseconds above 0
            (
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 1, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
            ),

            // No overflow - exact values preserved
            (
                PrecisionTimeInterval(seconds: 10, attoseconds: 500, sign: .positive),
                PrecisionTimeInterval(seconds: 10, attoseconds: 500, sign: .positive)
            ),

            // Zero case
            (
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: 0, sign: .positive)
            ),

            // Maximum valid attoseconds without overflow
            (
                PrecisionTimeInterval(seconds: 0, attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1, sign: .positive),
                PrecisionTimeInterval(seconds: 0, attoseconds: PrecisionTimeInterval.attosecondsPerSecond - 1, sign: .positive)
            ),

            // Large attoseconds value wrapping into seconds
            (
                PrecisionTimeInterval(seconds: 0, attoseconds: UInt64.max, sign: .positive),
                PrecisionTimeInterval(seconds: 18, attoseconds: 446_744_073_709_551_615, sign: .positive)
            ),

            // Milliseconds init - normal case
            (
                PrecisionTimeInterval(seconds: 5, milliseconds: 1500, sign: .positive),
                PrecisionTimeInterval(seconds: 6, attoseconds: 500 * PrecisionTimeInterval.attosecondsPerMilliSecond, sign: .positive)
            ),

            // Milliseconds init - seconds overflow detection
            (
                PrecisionTimeInterval(seconds: UInt64.max, milliseconds: 1000, sign: .positive),
                PrecisionTimeInterval(seconds: UInt64.max, attoseconds: 0, sign: .positive)
            ),

            // Milliseconds init - large milliseconds value
            (
                PrecisionTimeInterval(seconds: 0, milliseconds: 5_000, sign: .positive),
                PrecisionTimeInterval(seconds: 5, attoseconds: 0, sign: .positive)
            ),
        ]

        for (shouldwrap, iswrapped) in truths {
            #expect(shouldwrap == iswrapped)
        }
    }
}