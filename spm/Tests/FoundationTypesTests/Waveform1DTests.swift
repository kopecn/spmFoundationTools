import Foundation
import Testing

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("Waveform1D Initialization")
struct Waveform1DInitializationTests {

    @Test("Basic initialization with all parameters")
    func initializationWithAllParameters() {
        let startTime = PrecisionTimestamp()
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let dt = PrecisionTimeInterval(seconds: 0.001)

        let waveform = Waveform1D<Double>(values: values, dt: dt, t0: startTime)

        #expect(waveform.values == values)
        #expect(waveform.dt == dt)
        #expect(waveform.t0 == startTime)
    }

    @Test("Initialization with values only")
    func initializationWithValuesOnly() {
        let values = [1, 2, 3, 4, 5]
        let waveform = Waveform1D<Int>(values: values)

        #expect(waveform.values == values)
        #expect(waveform.dt == PrecisionTimeInterval(seconds: 1.0))
        #expect(waveform.t0 == nil)
    }

    @Test("Initialization with values and dt")
    func initializationWithValuesAndDt() {
        let values = [1.0, 2.0, 3.0]
        let dt = PrecisionTimeInterval(seconds: 0.5)
        let waveform = Waveform1D<Double>(values: values, dt: dt)

        #expect(waveform.values == values)
        #expect(waveform.dt == dt)
        #expect(waveform.t0 == nil)
    }

    @Test("Type aliases work correctly")
    func typeAliases() {
        let doubleWaveform = DoubleWaveform1D(values: [1.0, 2.0, 3.0])
        let floatWaveform = FloatWaveform1D(values: [1.0, 2.0, 3.0])
        let intWaveform = IntWaveform1D(values: [1, 2, 3])

        #expect(doubleWaveform.values.count == 3)
        #expect(floatWaveform.values.count == 3)
        #expect(intWaveform.values.count == 3)
    }
}

// MARK: - Computed Properties Suite
@Suite("Waveform1D Computed Properties")
struct Waveform1DComputedPropertiesTests {

    @Test("Duration calculation with multiple samples")
    func durationWithMultipleSamples() {
        let waveform = Waveform1D<Double>(values: [1.0, 2.0, 3.0, 4.0, 5.0], dtSeconds: 0.1)
        let expectedDuration: PrecisionTimeInterval = .oneDecisecond

        #expect(waveform.duration == expectedDuration)
    }

    @Test("Duration calculation with single sample")
    func durationWithSingleSample() {
        let waveform = Waveform1D<Double>(values: [1.0], dtSeconds: 0.1)

        #expect(waveform.duration == PrecisionTimeInterval.zero)
    }

    @Test("Duration calculation with empty array")
    func durationWithEmptyArray() {
        let waveform = Waveform1D<Double>(values: [Double](), dtSeconds: 0.1)

        #expect(waveform.duration == .zero)
    }

    // FIXME: --
    // @Test("Sampling frequency calculation")
    // func samplingFrequency() {
    //     let waveform = Waveform1D<Double>(values: [1.0, 2.0, 3.0], dtSeconds: 0.001)
    //     let expectedFrequency = 1.0 / 0.001

    //     #expect(waveform.samplingFrequency() == expectedFrequency)
    // }

    // FIXME: --
    // @Test("Nyquist frequency calculation")
    // func nyquistFrequency() {
    //     let waveform = Waveform1D<Double>(values: [1.0, 2.0, 3.0], dtSeconds: 0.002)
    //     let expectedNyquist = (1.0 / 0.002) / 2.0

    //     #expect(waveform.nyquistFrequency == expectedNyquist)
    // }

    @Test("Sample count")
    func sampleCount() {
        let waveform = Waveform1D<Double>(values: [1, 2, 3, 4, 5, 6])

        #expect(waveform.sampleCount == 6)
    }
}

// MARK: - Comparable Extension Suite
@Suite("Waveform1D Comparable Operations")
struct Waveform1DComparableTests {

    @Test("Peak-to-peak calculation for comparable types")
    func peakToPeakComparable() {
        let waveform = Waveform1D<Double>(values: [1.0, 5.0, 2.0, 8.0, 3.0])
        let expectedPeakToPeak = 8.0 - 1.0

        #expect(waveform.peakToPeak == expectedPeakToPeak)
    }

    @Test("Peak-to-peak with empty array")
    func peakToPeakEmpty() {
        let waveform = Waveform1D<Double>(values: [Double]())

        #expect(waveform.peakToPeak == nil)
    }

    @Test("Minimum value calculation")
    func minimumValue() {
        let waveform = Waveform1D<Int>(values: [3, 1, 4, 1, 5])

        #expect(waveform.minimum == 1)
    }

    @Test("Maximum value calculation")
    func maximumValue() {
        let waveform = Waveform1D<Int>(values: [3, 1, 4, 1, 5])

        #expect(waveform.maximum == 5)
    }

    @Test("Min/Max with empty array")
    func minMaxEmpty() {
        let waveform = Waveform1D<Int>(values: [Int]())

        #expect(waveform.minimum == nil)
        #expect(waveform.maximum == nil)
    }
}

// MARK: - BinaryFloatingPoint Extension Suite
@Suite("Waveform1D Floating Point Operations")
struct Waveform1DFloatingPointTests {

    @Test("Mean calculation for floating point")
    func meanFloatingPoint() {
        let waveform = Waveform1D<Double>(values: [1.0, 2.0, 3.0, 4.0, 5.0])
        let expectedMean = 3.0

        #expect(waveform.mean == expectedMean)
    }

    @Test("Mean with empty array")
    func meanEmpty() {
        let waveform = Waveform1D<Double>(values: [Double]())

        #expect(waveform.mean == 0.0)
    }

    @Test("RMS calculation")
    func rmsCalculation() {
        let waveform = Waveform1D<Double>(values: [3.0, 4.0])  // 3-4-5 triangle
        let expectedRMS = sqrt((9.0 + 16.0) / 2.0)  // sqrt(25/2) = sqrt(12.5)

        #expect(abs(waveform.rms - expectedRMS) < 1e-10)
    }

    @Test("RMS with empty array")
    func rmsEmpty() {
        let waveform = Waveform1D<Float>(values: [Float]())

        #expect(waveform.rms == 0.0)
    }

    @Test("Standard deviation calculation")
    func standardDeviation() {
        let waveform = Waveform1D<Double>(values: [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0])
        // Expected std dev ≈ 2.138 (using sample standard deviation)

        #expect(waveform.standardDeviation > 2.0)
        #expect(waveform.standardDeviation < 3.0)
    }

    @Test("Standard deviation with single value")
    func standardDeviationSingle() {
        let waveform = Waveform1D<Double>(values: [5.0])

        #expect(waveform.standardDeviation == 0.0)
    }

    @Test("Variance calculation")
    func variance() {
        let waveform = Waveform1D<Double>(values: [1.0, 2.0, 3.0])
        let expectedVariance = ((1.0 - 2.0) * (1.0 - 2.0) + (2.0 - 2.0) * (2.0 - 2.0) + (3.0 - 2.0) * (3.0 - 2.0)) / 2.0

        #expect(abs(waveform.variance - expectedVariance) < 1e-10)
    }

    @Test("Variance with single value")
    func varianceSingle() {
        let waveform = Waveform1D<Double>(values: [5.0])

        #expect(waveform.variance == 0.0)
    }
}

// MARK: - BinaryInteger Extension Suite
@Suite("Waveform1D Integer Operations")
struct Waveform1DIntegerTests {

    @Test("Mean calculation for integers")
    func meanInteger() {
        let waveform = Waveform1D<Int>(values: [1, 2, 3, 4, 5])
        let expectedMean = 15 / 5  // Integer division

        #expect(waveform.mean == expectedMean)
    }

    @Test("Sum calculation for integers")
    func sumInteger() {
        let waveform = Waveform1D<Int>(values: [1, 2, 3, 4, 5])
        let expectedSum = 15

        #expect(waveform.sum == expectedSum)
    }

    @Test("Sum with empty array")
    func sumEmpty() {
        let waveform = Waveform1D<Int>(values: [Int]())

        #expect(waveform.sum == 0)
    }
}

// MARK: - SignedInteger Extension Suite
@Suite("Waveform1D Signed Integer Operations")
struct Waveform1DSignedIntegerTests {

    @Test("Absolute sum calculation")
    func absoluteSum() {
        let waveform = Waveform1D<Int>(values: [-2, 3, -4, 5, -1])
        let expectedAbsoluteSum = 2 + 3 + 4 + 5 + 1

        #expect(waveform.absoluteSum == expectedAbsoluteSum)
    }

    @Test("Absolute sum with all positive values")
    func absoluteSumPositive() {
        let waveform = Waveform1D<Int>(values: [1, 2, 3, 4, 5])
        let expectedAbsoluteSum = 15

        #expect(waveform.absoluteSum == expectedAbsoluteSum)
    }

    @Test("Absolute sum with empty array")
    func absoluteSumEmpty() {
        let waveform = Waveform1D<Int>(values: [Int]())

        #expect(waveform.absoluteSum == 0)
    }
}

// MARK: - Edge Cases and Integration Suite
@Suite("Waveform1D Edge Cases")
struct Waveform1DEdgeCasesTests {

    @Test("Large dataset performance", .timeLimit(.minutes(1)))
    func largeDataset() {
        let largeArray = Array(repeating: 1.0, count: 100_000)
        let waveform = Waveform1D<Double>(values: largeArray, dtSeconds: 0.001)

        #expect(waveform.sampleCount == 100_000)
        #expect(waveform.mean == 1.0)
        #expect(waveform.duration.secondsAsDouble == 99.999)  // (100000-1) * 0.001
    }

    @Test("Floating point precision")
    func floatingPointPrecision() {
        let waveform = Waveform1D<Double>(values: [0.1, 0.2, 0.3])
        let expectedMean = 0.2

        #expect(abs(waveform.mean - expectedMean) < 1e-15)
    }

    @Test("Negative values handling")
    func negativeValues() {
        let waveform = Waveform1D<Double>(values: [-5.0, -2.0, 3.0, 7.0])

        #expect(waveform.minimum == -5.0)
        #expect(waveform.maximum == 7.0)
        #expect(waveform.peakToPeak == 12.0)
        #expect(waveform.mean == 0.75)  // (-5-2+3+7)/4
    }
}

// MARK: - Codable and File Operations Suite
@Suite("Waveform1D Codable and File Operations")
struct Waveform1DCodableTests {

    // Helper function to create a temporary directory
    private func createTempDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("WaveformTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }

    // Helper function to clean up temporary directory
    private func cleanupTempDirectory(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    @Test("JSON encoding and decoding for DoubleWaveform1D")
    func jsonCodingDoubleWaveform() throws {
        let startTime = PrecisionTimestamp()
        let originalWaveform = DoubleWaveform1D(
            values: [1.5, 2.7, 3.9, 4.1, 5.3],
            dtSeconds: 0.001,
            t0: startTime
        )

        // Encode to JSON
        let jsonData = try originalWaveform.toJSONData()
        #expect(jsonData.count > 0)

        // Decode from JSON
        let decodedWaveform = try DoubleWaveform1D.from(jsonData: jsonData)

        #expect(decodedWaveform.values == originalWaveform.values)
        #expect(decodedWaveform.dt == originalWaveform.dt)
        #expect(decodedWaveform.t0 == originalWaveform.t0)
    }

    @Test("JSON encoding and decoding for FloatWaveform1D")
    func jsonCodingFloatWaveform() throws {
        let originalWaveform = FloatWaveform1D(
            values: [1.0, 2.0, 3.0],
            dtSeconds: 0.5
        )

        let jsonData = try originalWaveform.toJSONData()
        let decodedWaveform = try FloatWaveform1D.from(jsonData: jsonData)

        #expect(decodedWaveform.values == originalWaveform.values)
        #expect(decodedWaveform.dt == originalWaveform.dt)
        #expect(decodedWaveform.t0 == nil)
    }

    @Test("JSON encoding and decoding for IntWaveform1D")
    func jsonCodingIntWaveform() throws {
        let originalWaveform = IntWaveform1D(
            values: [10, 20, 30, 40, 50],
            dtSeconds: 2.0
        )

        let jsonData = try originalWaveform.toJSONData()
        let decodedWaveform = try IntWaveform1D.from(jsonData: jsonData)

        #expect(decodedWaveform.values == originalWaveform.values)
        #expect(decodedWaveform.dt == originalWaveform.dt)
        #expect(decodedWaveform.t0 == nil)
    }

    @Test("JSON string conversion")
    func jsonStringConversion() throws {
        let waveform = DoubleWaveform1D(
            values: [1.0, 2.0, 3.0],
            dtSeconds: 0.1
        )

        let jsonString = try waveform.toJSONString()
        #expect(jsonString.contains("values"))
        #expect(jsonString.contains("dt"))
        #expect(jsonString.contains("1"))
        #expect(jsonString.contains("2"))
        #expect(jsonString.contains("3"))
        #expect(jsonString.contains("0.1"))
    }

    @Test("Save and load from file - DoubleWaveform1D")
    func saveLoadDoubleWaveformFile() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let fileURL = tempDir.appendingPathComponent("double_waveform.json")
        let startTime = PrecisionTimestamp()

        let originalWaveform = DoubleWaveform1D(
            values: [1.1, 2.2, 3.3, 4.4, 5.5],
            dtSeconds: 0.002,
            t0: startTime
        )

        // Save to file
        try originalWaveform.save(to: fileURL)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        // Load from file
        let loadedWaveform = try DoubleWaveform1D.load(from: fileURL)

        #expect(loadedWaveform.values == originalWaveform.values)
        #expect(loadedWaveform.dt == originalWaveform.dt)
        #expect(loadedWaveform.t0 == originalWaveform.t0)
    }

    @Test("Save and load from file - FloatWaveform1D")
    func saveLoadFloatWaveformFile() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let fileURL = tempDir.appendingPathComponent("float_waveform.json")

        let originalWaveform = FloatWaveform1D(
            values: [1.5, 2.5, 3.5],
            dtSeconds: 0.05
        )

        try originalWaveform.save(to: fileURL)
        let loadedWaveform = try FloatWaveform1D.load(from: fileURL)

        #expect(loadedWaveform.values == originalWaveform.values)
        #expect(loadedWaveform.dt == originalWaveform.dt)
        #expect(loadedWaveform.t0 == nil)
    }

    @Test("Save and load from file - IntWaveform1D")
    func saveLoadIntWaveformFile() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let fileURL = tempDir.appendingPathComponent("int_waveform.json")

        let originalWaveform = IntWaveform1D(
            values: [100, 200, 300, 400],
            dtSeconds: 1.0
        )

        try originalWaveform.save(to: fileURL)
        let loadedWaveform = try IntWaveform1D.load(from: fileURL)

        #expect(loadedWaveform.values == originalWaveform.values)
        #expect(loadedWaveform.dt == originalWaveform.dt)
        #expect(loadedWaveform.t0 == nil)
    }

    @Test("Convenience loadFromFile methods")
    func convenienceLoadMethods() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        // Test DoubleWaveform1D convenience method
        let doubleFileURL = tempDir.appendingPathComponent("double_convenience.json")
        let doubleWaveform = DoubleWaveform1D(values: [1.0, 2.0, 3.0], dtSeconds: 0.1)
        try doubleWaveform.save(to: doubleFileURL)
        let loadedDouble = try DoubleWaveform1D.loadFromFile(doubleFileURL)
        #expect(loadedDouble.values == doubleWaveform.values)

        // Test FloatWaveform1D convenience method
        let floatFileURL = tempDir.appendingPathComponent("float_convenience.json")
        let floatWaveform = FloatWaveform1D(values: [1.0, 2.0, 3.0], dtSeconds: 0.1)
        try floatWaveform.save(to: floatFileURL)
        let loadedFloat = try FloatWaveform1D.loadFromFile(floatFileURL)
        #expect(loadedFloat.values == floatWaveform.values)

        // Test IntWaveform1D convenience method
        let intFileURL = tempDir.appendingPathComponent("int_convenience.json")
        let intWaveform = IntWaveform1D(values: [1, 2, 3], dtSeconds: 0.1)
        try intWaveform.save(to: intFileURL)
        let loadedInt = try IntWaveform1D.loadFromFile(intFileURL)
        #expect(loadedInt.values == intWaveform.values)
    }

    @Test("Large waveform file operations", .timeLimit(.minutes(1)))
    func largeWaveformFileOperations() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let fileURL = tempDir.appendingPathComponent("large_waveform.json")

        // Create a large waveform
        let largeArray = Array(0..<10_000).map { Double($0) * 0.001 }
        let largeWaveform = DoubleWaveform1D(values: largeArray, dtSeconds: 0.0001)

        // Save and load
        try largeWaveform.save(to: fileURL)
        let loadedWaveform = try DoubleWaveform1D.load(from: fileURL)

        #expect(loadedWaveform.values.count == largeArray.count)
        #expect(loadedWaveform.values.first == largeArray.first)
        #expect(loadedWaveform.values.last == largeArray.last)
        #expect(loadedWaveform.dt == largeWaveform.dt)
    }

    @Test("Empty waveform encoding/decoding")
    func emptyWaveformCoding() throws {
        let emptyWaveform = DoubleWaveform1D(values: [], dtSeconds: 1.0)

        let jsonData = try emptyWaveform.toJSONData()
        let decodedWaveform = try DoubleWaveform1D.from(jsonData: jsonData)

        #expect(decodedWaveform.values.isEmpty)
        #expect(decodedWaveform.dt == .oneSecond)
        #expect(decodedWaveform.t0 == nil)
    }

    @Test("File error handling - nonexistent file")
    func fileErrorHandlingNonexistent() throws {
        let nonexistentURL = URL(fileURLWithPath: "/tmp/nonexistent_file.json")

        #expect(throws: Error.self) {
            try DoubleWaveform1D.load(from: nonexistentURL)
        }
    }

    @Test("File error handling - invalid JSON")
    func fileErrorHandlingInvalidJSON() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let invalidFileURL = tempDir.appendingPathComponent("invalid.json")
        let invalidJSON = "{ invalid json content }"
        try invalidJSON.write(to: invalidFileURL, atomically: true, encoding: .utf8)

        #expect(throws: Error.self) {
            try DoubleWaveform1D.load(from: invalidFileURL)
        }
    }

    @Test("File error handling - missing required fields")
    func fileErrorHandlingMissingFields() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let incompleteFileURL = tempDir.appendingPathComponent("incomplete.json")
        let incompleteJSON = """
            {
                "values": [1.0, 2.0, 3.0]
            }
            """
        try incompleteJSON.write(to: incompleteFileURL, atomically: true, encoding: .utf8)

        #expect(throws: Error.self) {
            try DoubleWaveform1D.load(from: incompleteFileURL)
        }
    }

    @Test("File error handling - invalid dt value (negative)")
    func fileErrorHandlingInvalidDtNegative() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let invalidFileURL = tempDir.appendingPathComponent("invalid_dt.json")
        let invalidJSON = """
            {
                "values": [1.0, 2.0, 3.0],
                "dt": -0.5
            }
            """
        try invalidJSON.write(to: invalidFileURL, atomically: true, encoding: .utf8)

        #expect(throws: WaveformCodingError.self) {
            try DoubleWaveform1D.load(from: invalidFileURL)
        }
    }

    @Test("File error handling - invalid dt value (zero)")
    func fileErrorHandlingInvalidDtZero() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let invalidFileURL = tempDir.appendingPathComponent("zero_dt.json")
        let invalidJSON = """
            {
                "values": [1.0, 2.0, 3.0],
                "dt": 0.0
            }
            """
        try invalidJSON.write(to: invalidFileURL, atomically: true, encoding: .utf8)

        #expect(throws: WaveformCodingError.self) {
            try DoubleWaveform1D.load(from: invalidFileURL)
        }
    }

    @Test("File permissions and directory creation")
    func filePermissionsAndDirectoryCreation() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        // Create a nested directory structure
        let nestedDir = tempDir.appendingPathComponent("nested/deep/structure")
        let fileURL = nestedDir.appendingPathComponent("waveform.json")

        let waveform = DoubleWaveform1D(values: [1.0, 2.0, 3.0], dtSeconds: 0.1)

        // This should fail because the directory doesn't exist
        #expect(throws: Error.self) {
            try waveform.save(to: fileURL)
        }

        // Create the directory structure
        try FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)

        // Now it should work
        try waveform.save(to: fileURL)
        let loadedWaveform = try DoubleWaveform1D.load(from: fileURL)
        #expect(loadedWaveform.values == waveform.values)
    }

    @Test("WaveformCodingError error descriptions")
    func waveformCodingErrorDescriptions() throws {
        // Test stringConversionFailed error
        let stringError = WaveformCodingError.stringConversionFailed
        #expect(stringError.errorDescription == "Failed to convert JSON data to string")

        // Test invalidFileFormat error
        let formatError = WaveformCodingError.invalidFileFormat
        #expect(formatError.errorDescription == "Invalid file format for waveform data")

        // Test missingRequiredField error
        let missingFieldError = WaveformCodingError.missingRequiredField("values")
        #expect(missingFieldError.errorDescription == "Missing required field: values")

        // Test with different field name
        let missingDtError = WaveformCodingError.missingRequiredField("dt")
        #expect(missingDtError.errorDescription == "Missing required field: dt")

        // Test incompatibleComponentWaveforms error
        let incompatibleError = WaveformCodingError.incompatibleComponentWaveforms
        #expect(
            incompatibleError.errorDescription == "Component waveforms have incompatible dimensions or sampling rates"
        )

        // Test emptyCSVFile error
        let emptyCSVError = WaveformCodingError.emptyCSVFile
        #expect(emptyCSVError.errorDescription == "CSV file is empty")

        // Test invalidCSVFormat error
        let invalidCSVError = WaveformCodingError.invalidCSVFormat(expected: "timestamp,value")
        #expect(invalidCSVError.errorDescription == "CSV file has invalid format - expected timestamp,value columns")

        // Test insufficientData error
        let insufficientDataError = WaveformCodingError.insufficientData
        #expect(insufficientDataError.errorDescription == "Insufficient data points in CSV file")
    }

    @Test("String conversion failure in toJSONString")
    func stringConversionFailureInToJSONString() throws {
        // Test the error type itself
        let error = WaveformCodingError.stringConversionFailed
        #expect(error.localizedDescription.contains("Failed to convert JSON data to string"))
    }

    @Test("All WaveformCodingError cases are covered")
    func allWaveformCodingErrorCases() throws {
        // Ensure all error cases have proper descriptions
        let allErrors: [WaveformCodingError] = [
            .stringConversionFailed,
            .invalidFileFormat,
            .missingRequiredField("example"),
            .incompatibleComponentWaveforms,
            .emptyCSVFile,
            .invalidCSVFormat(expected: "timestamp,value"),
            .insufficientData,
        ]

        for error in allErrors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("Simulate string conversion failure with corrupted data")
    func simulateStringConversionFailure() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let fileURL = tempDir.appendingPathComponent("corrupted.json")

        // Create a valid waveform first
        let waveform = DoubleWaveform1D(values: [1.0, 2.0, 3.0], dtSeconds: 0.001)
        let validData = try waveform.toJSONData()

        // Manually create corrupted data that can't be converted to UTF-8 string
        var corruptedData = validData
        corruptedData.append(contentsOf: [0xFF, 0xFE, 0xFD])  // Invalid UTF-8 sequence

        // Write the corrupted data
        try corruptedData.write(to: fileURL)

        // Try to load it - this should fail during decoding, not string conversion
        // But it exercises our error handling paths
        #expect(throws: Error.self) {
            try DoubleWaveform1D.load(from: fileURL)
        }
    }

}
