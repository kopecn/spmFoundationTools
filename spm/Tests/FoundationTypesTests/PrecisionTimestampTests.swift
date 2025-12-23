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
}