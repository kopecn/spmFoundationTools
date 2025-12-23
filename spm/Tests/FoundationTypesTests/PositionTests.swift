import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("Position Initialization")
struct PositionInitializationTests {

    @Test("Basic initialization with components - Float")
    func basicInitializationFloat() {
        let position = FloatPosition(x: 1.0, y: 2.0, z: 3.0)

        #expect(position.x == 1.0)
        #expect(position.y == 2.0)
        #expect(position.z == 3.0)
        #expect(position.vector == SIMD3<Float>(1.0, 2.0, 3.0))
    }

    @Test("Basic initialization with components - Double")
    func basicInitializationDouble() {
        let position = DoublePosition(x: -1.5, y: 2.5, z: -3.5)

        #expect(position.x == -1.5)
        #expect(position.y == 2.5)
        #expect(position.z == -3.5)
        #expect(position.vector == SIMD3<Double>(-1.5, 2.5, -3.5))
    }

    @Test("SIMD3 vector initialization")
    func simd3VectorInitialization() {
        let vector = SIMD3<Float>(4.0, 5.0, 6.0)
        let position = FloatPosition(vector: vector)

        #expect(position.vector == vector)
        #expect(position.x == 4.0)
        #expect(position.y == 5.0)
        #expect(position.z == 6.0)
    }

    @Test("Cylindrical coordinates initialization - Float")
    func cylindricalCoordinatesInitializationFloat() {
        let radius: Float = 5.0
        let angle: Float = Float.pi / 4  // 45 degrees
        let height: Float = 10.0

        let position = FloatPosition(cylindrical: radius, angle: angle, height: height)

        let expectedX = radius * cos(angle)
        let expectedY = radius * sin(angle)

        #expect(abs(position.x - expectedX) < 1e-6)
        #expect(abs(position.y - expectedY) < 1e-6)
        #expect(position.z == height)
    }

    @Test("Cylindrical coordinates initialization - Double")
    func cylindricalCoordinatesInitializationDouble() {
        let radius: Double = 3.0
        let angle: Double = Double.pi / 6  // 30 degrees
        let height: Double = 7.0

        let position = DoublePosition(cylindrical: radius, angle: angle, height: height)

        let expectedX = radius * cos(angle)
        let expectedY = radius * sin(angle)

        #expect(abs(position.x - expectedX) < 1e-10)
        #expect(abs(position.y - expectedY) < 1e-10)
        #expect(position.z == height)
    }

    @Test("Spherical coordinates initialization - Float")
    func sphericalCoordinatesInitializationFloat() {
        let radius: Float = 10.0
        let azimuth: Float = Float.pi / 3  // 60 degrees
        let elevation: Float = Float.pi / 6  // 30 degrees

        let position = FloatPosition(spherical: radius, azimuth: azimuth, elevation: elevation)

        let expectedX = radius * cos(elevation) * cos(azimuth)
        let expectedY = radius * cos(elevation) * sin(azimuth)
        let expectedZ = radius * sin(elevation)

        #expect(abs(position.x - expectedX) < 1e-6)
        #expect(abs(position.y - expectedY) < 1e-6)
        #expect(abs(position.z - expectedZ) < 1e-6)
    }

    @Test("Spherical coordinates initialization - Double")
    func sphericalCoordinatesInitializationDouble() {
        let radius: Double = 8.0
        let azimuth: Double = Double.pi / 4  // 45 degrees
        let elevation: Double = Double.pi / 3  // 60 degrees

        let position = DoublePosition(spherical: radius, azimuth: azimuth, elevation: elevation)

        let expectedX = radius * cos(elevation) * cos(azimuth)
        let expectedY = radius * cos(elevation) * sin(azimuth)
        let expectedZ = radius * sin(elevation)

        #expect(abs(position.x - expectedX) < 1e-10)
        #expect(abs(position.y - expectedY) < 1e-10)
        #expect(abs(position.z - expectedZ) < 1e-10)
    }

    @Test("Components array initialization - success")
    func componentsArrayInitializationSuccess() {
        let components: [Double] = [1.0, 2.0, 3.0]
        let position = DoublePosition(components: components)

        #expect(position != nil)
        #expect(position!.x == 1.0)
        #expect(position!.y == 2.0)
        #expect(position!.z == 3.0)
    }

    @Test("Components array initialization - failure")
    func componentsArrayInitializationFailure() {
        let tooFewComponents: [Float] = [1.0, 2.0]
        let tooManyComponents: [Float] = [1.0, 2.0, 3.0, 4.0]

        #expect(FloatPosition(components: tooFewComponents) == nil)
        #expect(FloatPosition(components: tooManyComponents) == nil)
    }

    @Test("Zero initialization")
    func zeroInitialization() {
        let position = DoublePosition(x: 0.0, y: 0.0, z: 0.0)

        #expect(position.x == 0.0)
        #expect(position.y == 0.0)
        #expect(position.z == 0.0)
        #expect(position == DoublePosition.origin)
    }
}

// MARK: - Static Properties Tests Suite
@Suite("Position Static Properties")
struct PositionStaticPropertiesTests {

    @Test("Origin position - Float")
    func originPositionFloat() {
        let origin = FloatPosition.origin

        #expect(origin.x == 0.0)
        #expect(origin.y == 0.0)
        #expect(origin.z == 0.0)
        #expect(origin.vector == SIMD3<Float>(0, 0, 0))
    }

    @Test("Origin position - Double")
    func originPositionDouble() {
        let origin = DoublePosition.origin

        #expect(origin.x == 0.0)
        #expect(origin.y == 0.0)
        #expect(origin.z == 0.0)
        #expect(origin.vector == SIMD3<Double>(0, 0, 0))
    }

    @Test("Unit X position")
    func unitXPosition() {
        let unitX = FloatPosition.unitX

        #expect(unitX.x == 1.0)
        #expect(unitX.y == 0.0)
        #expect(unitX.z == 0.0)
        #expect(unitX.vector == SIMD3<Float>(1, 0, 0))
    }

    @Test("Unit Y position")
    func unitYPosition() {
        let unitY = DoublePosition.unitY

        #expect(unitY.x == 0.0)
        #expect(unitY.y == 1.0)
        #expect(unitY.z == 0.0)
        #expect(unitY.vector == SIMD3<Double>(0, 1, 0))
    }

    @Test("Unit Z position")
    func unitZPosition() {
        let unitZ = FloatPosition.unitZ

        #expect(unitZ.x == 0.0)
        #expect(unitZ.y == 0.0)
        #expect(unitZ.z == 1.0)
        #expect(unitZ.vector == SIMD3<Float>(0, 0, 1))
    }

    @Test("All unit positions are unit magnitude")
    func allUnitPositionsAreUnitMagnitude() {
        #expect(FloatPosition.unitX.isUnit == true)
        #expect(FloatPosition.unitY.isUnit == true)
        #expect(FloatPosition.unitZ.isUnit == true)

        #expect(DoublePosition.unitX.isUnit == true)
        #expect(DoublePosition.unitY.isUnit == true)
        #expect(DoublePosition.unitZ.isUnit == true)
    }
}

// MARK: - Component Access Tests Suite
@Suite("Position Component Access")
struct PositionComponentAccessTests {

    @Test("Component getters")
    func componentGetters() {
        let position = DoublePosition(x: 10.0, y: 20.0, z: 30.0)

        #expect(position.x == 10.0)
        #expect(position.y == 20.0)
        #expect(position.z == 30.0)
    }

    @Test("Component setters")
    func componentSetters() {
        var position = FloatPosition(x: 1.0, y: 2.0, z: 3.0)

        position.x = 10.0
        position.y = 20.0
        position.z = 30.0

        #expect(position.x == 10.0)
        #expect(position.y == 20.0)
        #expect(position.z == 30.0)
        #expect(position.vector == SIMD3<Float>(10.0, 20.0, 30.0))
    }

    @Test("Components array property")
    func componentsArrayProperty() {
        let position = DoublePosition(x: 5.5, y: -2.3, z: 7.8)
        let components = position.components

        #expect(components.count == 3)
        #expect(components[0] == 5.5)
        #expect(components[1] == -2.3)
        #expect(components[2] == 7.8)
    }

    @Test("Vector property synchronization")
    func vectorPropertySynchronization() {
        var position = FloatPosition(x: 1.0, y: 2.0, z: 3.0)

        // Modify through vector
        position.vector = SIMD3<Float>(4.0, 5.0, 6.0)

        #expect(position.x == 4.0)
        #expect(position.y == 5.0)
        #expect(position.z == 6.0)

        // Modify through components
        position.x = 7.0
        #expect(position.vector.x == 7.0)

        position.y = 8.0
        #expect(position.vector.y == 8.0)

        position.z = 9.0
        #expect(position.vector.z == 9.0)
    }
}

// MARK: - Computed Properties Tests Suite
@Suite("Position Computed Properties")
struct PositionComputedPropertiesTests {

    @Test("Magnitude calculation - Float")
    func magnitudeCalculationFloat() {
        let position = FloatPosition(x: 3.0, y: 4.0, z: 0.0)

        #expect(abs(position.magnitude - 5.0) < 1e-6)
        #expect(abs(position.magnitudeSquared - 25.0) < 1e-6)
    }

    @Test("Magnitude calculation - Double")
    func magnitudeCalculationDouble() {
        let position = DoublePosition(x: 1.0, y: 1.0, z: 1.0)
        let expectedMagnitude = sqrt(3.0)

        #expect(abs(position.magnitude - expectedMagnitude) < 1e-10)
        #expect(abs(position.magnitudeSquared - 3.0) < 1e-10)
    }

    @Test("Zero magnitude")
    func zeroMagnitude() {
        let origin = FloatPosition.origin

        #expect(origin.magnitude == 0.0)
        #expect(origin.magnitudeSquared == 0.0)
    }

    @Test("Unit position check - true cases")
    func unitPositionCheckTrueCases() {
        #expect(FloatPosition.unitX.isUnit == true)
        #expect(FloatPosition.unitY.isUnit == true)
        #expect(FloatPosition.unitZ.isUnit == true)

        let normalizedPosition = FloatPosition(x: 3.0, y: 4.0, z: 0.0).normalized
        #expect(normalizedPosition.isUnit == true)
    }

    @Test("Unit position check - false cases")
    func unitPositionCheckFalseCases() {
        let position = DoublePosition(x: 2.0, y: 3.0, z: 4.0)
        #expect(position.isUnit == false)

        let origin = DoublePosition.origin
        #expect(origin.isUnit == false)
    }

    @Test("Normalized property - Float")
    func normalizedPropertyFloat() {
        let position = FloatPosition(x: 3.0, y: 4.0, z: 0.0)
        let normalized = position.normalized

        #expect(abs(normalized.magnitude - 1.0) < 1e-6)
        #expect(normalized.isUnit == true)

        // Original should be unchanged
        #expect(position.magnitude == 5.0)

        // Direction should be preserved
        #expect(abs(normalized.x - 0.6) < 1e-6)  // 3/5
        #expect(abs(normalized.y - 0.8) < 1e-6)  // 4/5
        #expect(normalized.z == 0.0)
    }

    @Test("Normalized property - Double")
    func normalizedPropertyDouble() {
        let position = DoublePosition(x: 1.0, y: 2.0, z: 2.0)
        let normalized = position.normalized

        #expect(abs(normalized.magnitude - 1.0) < 1e-10)
        #expect(normalized.isUnit == true)

        // Original should be unchanged
        #expect(position.magnitude == 3.0)
    }

    @Test("Normalize zero vector")
    func normalizeZeroVector() {
        let zero = FloatPosition.origin
        let normalized = zero.normalized

        #expect(normalized == FloatPosition.origin)
    }

    @Test("Mutating normalize - Float")
    func mutatingNormalizeFloat() {
        var position = FloatPosition(x: 6.0, y: 8.0, z: 0.0)
        let originalMagnitude = position.magnitude

        position.normalize()

        #expect(abs(position.magnitude - 1.0) < 1e-6)
        #expect(position.isUnit == true)
        #expect(originalMagnitude == 10.0)

        // Direction should be preserved
        #expect(abs(position.x - 0.6) < 1e-6)
        #expect(abs(position.y - 0.8) < 1e-6)
        #expect(position.z == 0.0)
    }

    @Test("Mutating normalize - Double")
    func mutatingNormalizeDouble() {
        var position = DoublePosition(x: 0.0, y: 3.0, z: 4.0)

        position.normalize()

        #expect(abs(position.magnitude - 1.0) < 1e-10)
        #expect(position.isUnit == true)

        #expect(position.x == 0.0)
        #expect(abs(position.y - 0.6) < 1e-10)  // 3/5
        #expect(abs(position.z - 0.8) < 1e-10)  // 4/5
    }

    @Test("Mutating normalize zero vector")
    func mutatingNormalizeZeroVector() {
        var zero = DoublePosition.origin
        zero.normalize()

        #expect(zero == DoublePosition.origin)
    }
}

// MARK: - Equatable Tests Suite
@Suite("Position Equatable")
struct PositionEquatableTests {

    @Test("Equality - identical positions")
    func equalityIdenticalPositions() {
        let pos1 = FloatPosition(x: 1.0, y: 2.0, z: 3.0)
        let pos2 = FloatPosition(x: 1.0, y: 2.0, z: 3.0)

        #expect(pos1 == pos2)
    }

    @Test("Equality - different positions")
    func equalityDifferentPositions() {
        let pos1 = DoublePosition(x: 1.0, y: 2.0, z: 3.0)
        let pos2 = DoublePosition(x: 1.0, y: 2.0, z: 3.1)

        #expect(pos1 != pos2)
    }

    @Test("Equality - static properties")
    func equalityStaticProperties() {
        #expect(FloatPosition.origin == FloatPosition(x: 0.0, y: 0.0, z: 0.0))
        #expect(DoublePosition.unitX == DoublePosition(x: 1.0, y: 0.0, z: 0.0))
        #expect(FloatPosition.unitY == FloatPosition(x: 0.0, y: 1.0, z: 0.0))
        #expect(DoublePosition.unitZ == DoublePosition(x: 0.0, y: 0.0, z: 1.0))
    }

    @Test("Self equality")
    func selfEquality() {
        let position = FloatPosition(x: 10.0, y: 20.0, z: 30.0)

        #expect(position == position)
    }

    @Test("Inequality reflexivity")
    func inequalityReflexivity() {
        let pos1 = DoublePosition(x: 1.0, y: 2.0, z: 3.0)
        let pos2 = DoublePosition(x: 3.0, y: 2.0, z: 1.0)

        if pos1 != pos2 {
            #expect(pos2 != pos1)
        }
    }
}

// MARK: - Hashable Tests Suite
@Suite("Position Hashable")
struct PositionHashableTests {

    @Test("Hash consistency")
    func hashConsistency() {
        let position = FloatPosition(x: 1.5, y: 2.5, z: 3.5)
        let hash1 = position.hashValue
        let hash2 = position.hashValue

        #expect(hash1 == hash2)
    }

    @Test("Equal positions have equal hashes")
    func equalPositionsEqualHashes() {
        let pos1 = DoublePosition(x: 7.0, y: 8.0, z: 9.0)
        let pos2 = DoublePosition(x: 7.0, y: 8.0, z: 9.0)

        #expect(pos1 == pos2)
        #expect(pos1.hashValue == pos2.hashValue)
    }

    @Test("Set operations work correctly")
    func setOperationsWorkCorrectly() {
        let pos1 = FloatPosition(x: 1.0, y: 2.0, z: 3.0)
        let pos2 = FloatPosition(x: 4.0, y: 5.0, z: 6.0)
        let pos3 = FloatPosition(x: 1.0, y: 2.0, z: 3.0)  // Same as pos1

        let positionSet: Set = [pos1, pos2, pos3]

        #expect(positionSet.count == 2)  // pos1 and pos3 should be treated as the same
        #expect(positionSet.contains(pos1))
        #expect(positionSet.contains(pos2))
        #expect(positionSet.contains(pos3))
    }

    @Test("Dictionary operations work correctly")
    func dictionaryOperationsWorkCorrectly() {
        let pos1 = DoublePosition.origin
        let pos2 = DoublePosition.unitX

        var positionDict: [DoublePosition: String] = [:]
        positionDict[pos1] = "Origin"
        positionDict[pos2] = "Unit X"

        #expect(positionDict[pos1] == "Origin")
        #expect(positionDict[pos2] == "Unit X")
        #expect(positionDict[DoublePosition(x: 0.0, y: 0.0, z: 0.0)] == "Origin")
    }
}

// MARK: - String Representation Tests Suite
@Suite("Position String Representation")
struct PositionStringRepresentationTests {

    @Test("Description format")
    func descriptionFormat() {
        let position = FloatPosition(x: 1.5, y: 2.5, z: 3.5)
        let description = position.description

        #expect(description.contains("Position"))
        #expect(description.contains("1.5"))
        #expect(description.contains("2.5"))
        #expect(description.contains("3.5"))
        #expect(description.contains("x:"))
        #expect(description.contains("y:"))
        #expect(description.contains("z:"))
    }

    @Test("Debug description format")
    func debugDescriptionFormat() {
        let position = DoublePosition(x: -1.0, y: 0.0, z: 1.0)
        let debugDescription = position.debugDescription

        #expect(debugDescription.contains("Position<Double>"))
        #expect(debugDescription.contains("-1.0"))
        #expect(debugDescription.contains("0.0"))
        #expect(debugDescription.contains("1.0"))
    }

    @Test("Static positions string representation")
    func staticPositionsStringRepresentation() {
        let origin = FloatPosition.origin
        let unitX = DoublePosition.unitX

        #expect(origin.description.contains("0.0"))
        #expect(unitX.description.contains("1.0"))
        #expect(!origin.debugDescription.isEmpty)
        #expect(!unitX.debugDescription.isEmpty)
    }
}

// MARK: - Codable Tests Suite
@Suite("Position Codable")
struct PositionCodableTests {

    @Test("JSON encoding and decoding - Float")
    func jsonEncodingDecodingFloat() throws {
        let original = FloatPosition(x: 1.5, y: -2.5, z: 3.5)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FloatPosition.self, from: data)

        #expect(decoded == original)
        #expect(decoded.x == original.x)
        #expect(decoded.y == original.y)
        #expect(decoded.z == original.z)
    }

    @Test("JSON encoding and decoding - Double")
    func jsonEncodingDecodingDouble() throws {
        let original = DoublePosition(x: 10.123456789, y: 20.987654321, z: -30.555555555)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DoublePosition.self, from: data)

        #expect(decoded == original)
        #expect(decoded.x == original.x)
        #expect(decoded.y == original.y)
        #expect(decoded.z == original.z)
    }

    @Test("JSON structure validation")
    func jsonStructureValidation() throws {
        let position = FloatPosition(x: 5.0, y: 10.0, z: 15.0)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(position)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"x\""))
        #expect(jsonString.contains("\"y\""))
        #expect(jsonString.contains("\"z\""))
        #expect(jsonString.contains("5"))
        #expect(jsonString.contains("10"))
        #expect(jsonString.contains("15"))
    }

    @Test("Decode from manual JSON")
    func decodeFromManualJSON() throws {
        let jsonString = """
            {
                "x": 7.5,
                "y": -2.3,
                "z": 9.8
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let position = try decoder.decode(DoublePosition.self, from: data)

        #expect(position.x == 7.5)
        #expect(position.y == -2.3)
        #expect(position.z == 9.8)
    }

    @Test("Array of positions encoding/decoding")
    func arrayOfPositionsEncodingDecoding() throws {
        let positions = [
            FloatPosition.origin,
            FloatPosition.unitX,
            FloatPosition.unitY,
            FloatPosition.unitZ,
            FloatPosition(x: 1.0, y: 2.0, z: 3.0),
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(positions)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([FloatPosition].self, from: data)

        #expect(decoded.count == positions.count)
        for (original, decodedPos) in zip(positions, decoded) {
            #expect(decodedPos == original)
        }
    }
}

// MARK: - Edge Cases Tests Suite
@Suite("Position Edge Cases")
struct PositionEdgeCasesTests {

    @Test("Very large coordinates")
    func veryLargeCoordinates() {
        let largePosition = DoublePosition(x: 1e15, y: 1e15, z: 1e15)

        #expect(largePosition.x == 1e15)
        #expect(largePosition.y == 1e15)
        #expect(largePosition.z == 1e15)

        let magnitude = largePosition.magnitude
        #expect(magnitude > 0)
        #expect(magnitude.isFinite)
    }

    @Test("Very small coordinates")
    func verySmallCoordinates() {
        let smallPosition = FloatPosition(x: 1e-30, y: 1e-30, z: 1e-30)

        #expect(smallPosition.x == 1e-30)
        #expect(smallPosition.y == 1e-30)
        #expect(smallPosition.z == 1e-30)

        let magnitude = smallPosition.magnitude
        #expect(magnitude >= 0)
        #expect(magnitude.isFinite)
    }

    @Test("Negative coordinates")
    func negativeCoordinates() {
        let negativePosition = DoublePosition(x: -10.0, y: -20.0, z: -30.0)

        #expect(negativePosition.x == -10.0)
        #expect(negativePosition.y == -20.0)
        #expect(negativePosition.z == -30.0)

        let magnitude = negativePosition.magnitude
        let expectedMagnitude = sqrt(10.0 * 10.0 + 20.0 * 20.0 + 30.0 * 30.0)
        #expect(abs(magnitude - expectedMagnitude) < 1e-10)
    }

    @Test("Mixed positive and negative coordinates")
    func mixedPositiveNegativeCoordinates() {
        let mixedPosition = FloatPosition(x: -5.0, y: 10.0, z: -15.0)

        let magnitude = mixedPosition.magnitude
        let expectedMagnitude: Float = sqrt(25.0 + 100.0 + 225.0)  // sqrt(350)
        #expect(abs(magnitude - expectedMagnitude) < 1e-6)

        let normalized = mixedPosition.normalized
        #expect(normalized.isUnit == true)

        // Signs should be preserved
        #expect(normalized.x < 0)
        #expect(normalized.y > 0)
        #expect(normalized.z < 0)
    }

    @Test("NaN and infinity handling")
    func nanAndInfinityHandling() {
        // NaN coordinates
        let nanPosition = FloatPosition(x: Float.nan, y: 1.0, z: 2.0)
        #expect(nanPosition.x.isNaN)
        #expect(nanPosition.magnitude.isNaN)

        // Infinity coordinates
        let infPosition = DoublePosition(x: Double.infinity, y: 1.0, z: 2.0)
        #expect(infPosition.x.isInfinite)
        #expect(infPosition.magnitude.isInfinite)
    }

    @Test("Coordinate system edge cases")
    func coordinateSystemEdgeCases() {
        // Test with angle = 0
        let cylindrical1 = FloatPosition(cylindrical: 5.0, angle: 0.0, height: 10.0)
        #expect(abs(cylindrical1.x - 5.0) < 1e-6)
        #expect(abs(cylindrical1.y - 0.0) < 1e-6)
        #expect(cylindrical1.z == 10.0)

        // Test with angle = π/2
        let cylindrical2 = DoublePosition(cylindrical: 3.0, angle: Double.pi / 2, height: 7.0)
        #expect(abs(cylindrical2.x - 0.0) < 1e-10)
        #expect(abs(cylindrical2.y - 3.0) < 1e-10)
        #expect(cylindrical2.z == 7.0)

        // Test spherical with elevation = π/2 (north pole)
        let spherical1 = FloatPosition(spherical: 10.0, azimuth: 0.0, elevation: Float.pi / 2)
        #expect(abs(spherical1.x - 0.0) < 1e-6)
        #expect(abs(spherical1.y - 0.0) < 1e-6)
        #expect(abs(spherical1.z - 10.0) < 1e-6)

        // Test spherical with elevation = -π/2 (south pole)
        let spherical2 = DoublePosition(spherical: 5.0, azimuth: 0.0, elevation: -Double.pi / 2)
        #expect(abs(spherical2.x - 0.0) < 1e-10)
        #expect(abs(spherical2.y - 0.0) < 1e-10)
        #expect(abs(spherical2.z - (-5.0)) < 1e-10)
    }
}

// MARK: - ISO Spherical Coordinates Tests Suite
@Suite("Position ISO 80000-2:2019 Spherical Coordinates")
struct PositionISOSphericalCoordinatesTests {

    @Test("ISO spherical initialization - Float - north pole")
    func isoSphericalInitializationFloatNorthPole() {
        let radius: Float = 10.0
        let azimuth: Float = 0.0  // Azimuth is arbitrary at poles
        let polar: Float = 0.0  // 0 = north pole (+z axis)

        let position = FloatPosition(sphericalISO: radius, azimuth: azimuth, polar: polar)

        // At north pole: x=0, y=0, z=radius
        #expect(abs(position.x - 0.0) < 1e-6)
        #expect(abs(position.y - 0.0) < 1e-6)
        #expect(abs(position.z - 10.0) < 1e-6)
    }

    @Test("ISO spherical initialization - Float - south pole")
    func isoSphericalInitializationFloatSouthPole() {
        let radius: Float = 5.0
        let azimuth: Float = 0.0  // Azimuth is arbitrary at poles
        let polar: Float = Float.pi  // π = south pole (-z axis)

        let position = FloatPosition(sphericalISO: radius, azimuth: azimuth, polar: polar)

        // At south pole: x=0, y=0, z=-radius
        #expect(abs(position.x - 0.0) < 1e-6)
        #expect(abs(position.y - 0.0) < 1e-6)
        #expect(abs(position.z - (-5.0)) < 1e-6)
    }

    @Test("ISO spherical initialization - Float - equator")
    func isoSphericalInitializationFloatEquator() {
        let radius: Float = 8.0
        let azimuth: Float = Float.pi / 4  // 45 degrees
        let polar: Float = Float.pi / 2  // π/2 = equator (xy-plane)

        let position = FloatPosition(sphericalISO: radius, azimuth: azimuth, polar: polar)

        // At equator: z=0, x and y form circle
        let expectedX = radius * sin(polar) * cos(azimuth)
        let expectedY = radius * sin(polar) * sin(azimuth)
        let expectedZ = radius * cos(polar)

        #expect(abs(position.x - expectedX) < 1e-6)
        #expect(abs(position.y - expectedY) < 1e-6)
        #expect(abs(position.z - expectedZ) < 1e-6)
        #expect(abs(position.z) < 1e-6)  // Should be at equator
    }

    @Test("ISO spherical initialization - Double - general case")
    func isoSphericalInitializationDoubleGeneralCase() {
        let radius: Double = 10.0
        let azimuth: Double = Double.pi / 3  // 60 degrees
        let polar: Double = Double.pi / 4  // 45 degrees from +z

        let position = DoublePosition(sphericalISO: radius, azimuth: azimuth, polar: polar)

        let expectedX = radius * sin(polar) * cos(azimuth)
        let expectedY = radius * sin(polar) * sin(azimuth)
        let expectedZ = radius * cos(polar)

        #expect(abs(position.x - expectedX) < 1e-10)
        #expect(abs(position.y - expectedY) < 1e-10)
        #expect(abs(position.z - expectedZ) < 1e-10)
    }

    @Test("ISO vs mathematical convention comparison - north pole")
    func isoVsMathematicalConventionNorthPole() {
        // North pole in ISO: polar = 0
        // North pole in mathematical: elevation = π/2
        let radius: Double = 10.0

        let isoPosition = DoublePosition(sphericalISO: radius, azimuth: 0.0, polar: 0.0)
        let mathPosition = DoublePosition(spherical: radius, azimuth: 0.0, elevation: Double.pi / 2)

        // Both should give same position at north pole
        #expect(abs(isoPosition.x - mathPosition.x) < 1e-10)
        #expect(abs(isoPosition.y - mathPosition.y) < 1e-10)
        #expect(abs(isoPosition.z - mathPosition.z) < 1e-10)
        #expect(abs(isoPosition.z - 10.0) < 1e-10)
    }

    @Test("ISO vs mathematical convention comparison - south pole")
    func isoVsMathematicalConventionSouthPole() {
        // South pole in ISO: polar = π
        // South pole in mathematical: elevation = -π/2
        let radius: Float = 5.0

        let isoPosition = FloatPosition(sphericalISO: radius, azimuth: 0.0, polar: Float.pi)
        let mathPosition = FloatPosition(spherical: radius, azimuth: 0.0, elevation: -Float.pi / 2)

        // Both should give same position at south pole
        #expect(abs(isoPosition.x - mathPosition.x) < 1e-6)
        #expect(abs(isoPosition.y - mathPosition.y) < 1e-6)
        #expect(abs(isoPosition.z - mathPosition.z) < 1e-6)
        #expect(abs(isoPosition.z - (-5.0)) < 1e-6)
    }

    @Test("ISO vs mathematical convention comparison - equator")
    func isoVsMathematicalConventionEquator() {
        // Equator in ISO: polar = π/2
        // Equator in mathematical: elevation = 0
        let radius: Double = 8.0
        let azimuth: Double = Double.pi / 6

        let isoPosition = DoublePosition(sphericalISO: radius, azimuth: azimuth, polar: Double.pi / 2)
        let mathPosition = DoublePosition(spherical: radius, azimuth: azimuth, elevation: 0.0)

        // Both should give same position at equator
        #expect(abs(isoPosition.x - mathPosition.x) < 1e-10)
        #expect(abs(isoPosition.y - mathPosition.y) < 1e-10)
        #expect(abs(isoPosition.z - mathPosition.z) < 1e-10)
        #expect(abs(isoPosition.z) < 1e-10)
    }
}
