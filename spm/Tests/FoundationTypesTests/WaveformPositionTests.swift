import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Basic Functionality Tests Suite
@Suite("WaveformPosition Basic Functionality")
struct WaveformPositionBasicTests {

    @Test("Basic initialization")
    func basicInitialization() {
        let positions = [FloatPosition.origin, FloatPosition.unitX]
        let waveform = FloatWaveformPosition(values: positions, dt: 0.001, t0: Date())

        #expect(waveform.values.count == 2)
        #expect(waveform.dt == 0.001)
        #expect(waveform.t0 != nil)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let positions = [DoublePosition.origin, DoublePosition.unitX, DoublePosition.unitY]
        let waveform = DoubleWaveformPosition(values: positions, dt: 0.01, t0: Date())

        let encoder = JSONEncoder()
        let data = try encoder.encode(waveform)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DoubleWaveformPosition.self, from: data)

        #expect(decoded.values == waveform.values)
        #expect(decoded.dt == waveform.dt)
    }

    @Test("CSV export and import")
    func csvExportImport() throws {
        let positions = [
            FloatPosition(x: 1.0, y: 2.0, z: 3.0),
            FloatPosition(x: 4.0, y: 5.0, z: 6.0),
        ]
        let waveform = FloatWaveformPosition(values: positions, dt: 0.1, t0: Date())

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_poss.csv")

        try waveform.exportToCSV(to: tempURL)
        let imported = try FloatWaveformPosition.importFromCSV(from: tempURL)

        #expect(imported.values.count == waveform.values.count)
        #expect(abs(imported.dt - waveform.dt) < 1e-6)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
}

// MARK: - Error Handling Tests Suite
@Suite("WaveformPosition Error Handling")
struct WaveformPositionErrorHandlingTests {

    @Test("Empty CSV file error")
    func emptyCsvFileError() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("empty.csv")

        // Create empty file
        try "".write(to: tempURL, atomically: true, encoding: .utf8)

        #expect(throws: WaveformCodingError.self) {
            try FloatWaveformPosition.importFromCSV(from: tempURL)
        }

        // Verify the specific error type by catching it
        do {
            _ = try FloatWaveformPosition.importFromCSV(from: tempURL)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch let error as WaveformCodingError {
            switch error {
            case .emptyCSVFile:
                // This is the expected error
                break
            default:
                #expect(Bool(false), "Expected .emptyCSVFile error, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Expected WaveformCodingError, got \(error)")
        }

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Invalid CSV format error")
    func invalidCsvFormatError() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("invalid.csv")

        // Create CSV with insufficient columns
        let invalidCSV = "timestamp,x,y\n1.0,2.0,3.0\n"
        try invalidCSV.write(to: tempURL, atomically: true, encoding: .utf8)

        #expect(throws: WaveformCodingError.self) {
            try DoubleWaveformPosition.importFromCSV(from: tempURL)
        }

        // Verify the specific error type and message
        do {
            _ = try DoubleWaveformPosition.importFromCSV(from: tempURL)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch let error as WaveformCodingError {
            switch error {
            case .invalidCSVFormat(let expected):
                #expect(expected == "timestamp,x,y,z")
            default:
                #expect(Bool(false), "Expected .invalidCSVFormat error, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Expected WaveformCodingError, got \(error)")
        }

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Insufficient data error")
    func insufficientDataError() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("insufficient.csv")

        // Create CSV with only header
        let csvWithHeaderOnly = "timestamp,x,y,z\n"
        try csvWithHeaderOnly.write(to: tempURL, atomically: true, encoding: .utf8)

        #expect(throws: WaveformCodingError.self) {
            try FloatWaveformPosition.importFromCSV(from: tempURL)
        }

        // Verify the specific error type
        do {
            _ = try FloatWaveformPosition.importFromCSV(from: tempURL)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch let error as WaveformCodingError {
            switch error {
            case .insufficientData:
                // This is the expected error
                break
            default:
                #expect(Bool(false), "Expected .insufficientData error, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Expected WaveformCodingError, got \(error)")
        }

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("String conversion failure error")
    func stringConversionFailureError() throws {

        // This test verifies the error type exists and has proper description
        let error = WaveformCodingError.stringConversionFailed
        #expect(error.errorDescription == "Failed to convert JSON data to string")
        #expect(error.localizedDescription == error.errorDescription)
    }

    @Test("All WaveformCodingError cases for positions")
    func allWaveformCodingErrorCases() {
        let allErrors: [WaveformCodingError] = [
            .stringConversionFailed,
            .invalidFileFormat,
            .missingRequiredField("positions"),
            .incompatibleComponentWaveforms,
            .emptyCSVFile,
            .invalidCSVFormat(expected: "timestamp,x,y,z"),
            .insufficientData,
        ]

        for error in allErrors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
            #expect(error.localizedDescription == error.errorDescription)
        }
    }
}

// MARK: - File Operations Tests Suite
@Suite("WaveformPosition File Operations")
struct WaveformPositionFileOperationsTests {

    private func createTempDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("WaveformPositionTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }

    private func cleanupTempDirectory(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    @Test("Save and load JSON file")
    func saveAndLoadJsonFile() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let positions = [
            DoublePosition(x: 1.0, y: 2.0, z: 3.0),
            DoublePosition(x: 4.0, y: 5.0, z: 6.0),
        ]
        let original = DoubleWaveformPosition(values: positions, dt: 0.01, t0: Date())

        let fileURL = tempDir.appendingPathComponent("test.json")
        try original.save(to: fileURL)

        let loaded = try DoubleWaveformPosition.load(from: fileURL)

        #expect(loaded.values == original.values)
        #expect(loaded.dt == original.dt)
        #expect(loaded.sampleCount == original.sampleCount)
    }

    @Test("JSON string conversion")
    func jsonStringConversion() throws {
        let positions = [FloatPosition.unitX, FloatPosition.unitY]
        let waveform = FloatWaveformPosition(values: positions, dt: 0.001)

        let jsonString = try waveform.toJSONString()

        #expect(jsonString.contains("\"values\""))
        #expect(jsonString.contains("\"dt\""))
        #expect(jsonString.contains("0.001"))
        #expect(jsonString.contains("\n"))  // Pretty printed
    }

    @Test("Convenience load methods")
    func convenienceLoadMethods() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        // Test Double convenience methods
        let doublePositions = [DoublePosition.origin, DoublePosition.unitZ]
        let doubleWaveform = DoubleWaveformPosition(values: doublePositions, dt: 0.1)

        let doubleJsonURL = tempDir.appendingPathComponent("double.json")
        try doubleWaveform.save(to: doubleJsonURL)
        let loadedDouble = try DoubleWaveformPosition.loadFromFile(doubleJsonURL)
        #expect(loadedDouble.values == doubleWaveform.values)

        // Test Float convenience methods
        let floatPositions = [FloatPosition.origin, FloatPosition.unitX]
        let floatWaveform = FloatWaveformPosition(values: floatPositions, dt: 0.05)

        let floatJsonURL = tempDir.appendingPathComponent("float.json")
        try floatWaveform.save(to: floatJsonURL)
        let loadedFloat = try FloatWaveformPosition.loadFromFile(floatJsonURL)
        #expect(loadedFloat.values == floatWaveform.values)
    }

    @Test("CSV convenience load methods")
    func csvConvenienceLoadMethods() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        // Create test CSV
        let csvContent = """
            timestamp,x,y,z
            0.0,1.0,2.0,3.0
            0.1,4.0,5.0,6.0
            """

        let csvURL = tempDir.appendingPathComponent("test.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        // Test Double CSV loading
        let doubleFromCSV = try DoubleWaveformPosition.loadFromCSV(csvURL)
        #expect(doubleFromCSV.values.count == 2)
        #expect(abs(doubleFromCSV.dt - 0.1) < 1e-10)

        // Test Float CSV loading
        let floatFromCSV = try FloatWaveformPosition.loadFromCSV(csvURL)
        #expect(floatFromCSV.values.count == 2)
        #expect(abs(floatFromCSV.dt - 0.1) < 1e-6)
    }

    @Test("File error handling - nonexistent file")
    func fileErrorHandlingNonexistent() {
        let nonexistentURL = URL(fileURLWithPath: "/tmp/nonexistent_poss.json")

        #expect(throws: Error.self) {
            try DoubleWaveformPosition.load(from: nonexistentURL)
        }
    }

    @Test("File error handling - invalid JSON")
    func fileErrorHandlingInvalidJson() throws {
        let tempDir = try createTempDirectory()
        defer { try? cleanupTempDirectory(tempDir) }

        let invalidFileURL = tempDir.appendingPathComponent("invalid.json")
        let invalidJSON = "{ invalid json for positions }"
        try invalidJSON.write(to: invalidFileURL, atomically: true, encoding: .utf8)

        #expect(throws: Error.self) {
            try FloatWaveformPosition.load(from: invalidFileURL)
        }
    }
}
