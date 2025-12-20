import Foundation
import Testing
import simd

@testable import FoundationTypes

// MARK: - Initialization Tests Suite
@Suite("Quaternion Initialization")
struct QuaternionInitializationTests {

    @Test("Component initialization - Float")
    func componentInitializationFloat() {
        let quat = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)

        #expect(quat.x == 1.0)
        #expect(quat.y == 2.0)
        #expect(quat.z == 3.0)
        #expect(quat.w == 4.0)
        #expect(quat.vector == SIMD4<Float>(1.0, 2.0, 3.0, 4.0))
    }

    @Test("Component initialization - Double")
    func componentInitializationDouble() {
        let quat = DoubleQuaternion(x: 1.5, y: 2.5, z: 3.5, w: 4.5)

        #expect(quat.x == 1.5)
        #expect(quat.y == 2.5)
        #expect(quat.z == 3.5)
        #expect(quat.w == 4.5)
        #expect(quat.vector == SIMD4<Double>(1.5, 2.5, 3.5, 4.5))
    }

    @Test("SIMD4 vector initialization")
    func simd4VectorInitialization() {
        let vector = SIMD4<Float>(0.1, 0.2, 0.3, 0.4)
        let quat = FloatQuaternion(vector: vector)

        #expect(quat.vector == vector)
        #expect(quat.x == 0.1)
        #expect(quat.y == 0.2)
        #expect(quat.z == 0.3)
        #expect(quat.w == 0.4)
    }

    @Test("Imaginary and real parts initialization")
    func imaginaryRealInitialization() {
        let imaginary = SIMD3<Double>(1.0, 2.0, 3.0)
        let real = 4.0
        let quat = DoubleQuaternion(imaginary: imaginary, real: real)

        #expect(quat.x == 1.0)
        #expect(quat.y == 2.0)
        #expect(quat.z == 3.0)
        #expect(quat.w == 4.0)
        #expect(quat.imaginary == imaginary)
        #expect(quat.real == real)
    }

    @Test("Axis-angle initialization - Float")
    func axisAngleInitializationFloat() {
        let axis = simd_normalize(SIMD3<Float>(1.0, 1.0, 1.0))
        let angle: Float = .pi / 4
        let quat = FloatQuaternion(axis: axis, angle: angle)

        // Verify quaternion is normalized (approximately)
        let magnitude = sqrt(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w)
        #expect(abs(magnitude - 1.0) < 1e-6)

        // Verify w component for 45-degree rotation
        let expectedW = cos(angle / 2)
        #expect(abs(quat.w - expectedW) < 1e-6)
    }

    @Test("Axis-angle initialization - Double")
    func axisAngleInitializationDouble() {
        let axis = simd_normalize(SIMD3<Double>(0.0, 1.0, 0.0))  // Y-axis
        let angle: Double = .pi / 2  // 90 degrees
        let quat = DoubleQuaternion(axis: axis, angle: angle)

        // Verify quaternion is normalized
        let magnitude = sqrt(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w)
        #expect(abs(magnitude - 1.0) < 1e-15)

        // Verify components for 90-degree Y rotation
        #expect(abs(quat.x) < 1e-15)  // Should be 0
        #expect(abs(quat.y - sin(angle / 2)) < 1e-15)  // sin(π/4)
        #expect(abs(quat.z) < 1e-15)  // Should be 0
        #expect(abs(quat.w - cos(angle / 2)) < 1e-15)  // cos(π/4)
    }

    @Test("Euler angles initialization - Float")
    func eulerAnglesInitializationFloat() {
        let roll: Float = .pi / 6  // 30 degrees
        let pitch: Float = .pi / 4  // 45 degrees
        let yaw: Float = .pi / 3  // 60 degrees

        let quat = FloatQuaternion(roll: roll, pitch: pitch, yaw: yaw)

        // Verify quaternion is normalized
        let magnitude = sqrt(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w)
        #expect(abs(magnitude - 1.0) < 1e-6)

        // Verify quaternion is not zero or identity (since we have non-zero rotations)
        #expect(quat != FloatQuaternion.zero)
        #expect(quat != FloatQuaternion.identity)
    }

    @Test("Euler angles initialization - Double")
    func eulerAnglesInitializationDouble() {
        let roll: Double = 0.0
        let pitch: Double = 0.0
        let yaw: Double = .pi / 2  // 90-degree yaw only

        let quat = DoubleQuaternion(roll: roll, pitch: pitch, yaw: yaw)

        // Verify quaternion is normalized
        let magnitude = sqrt(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w)
        #expect(abs(magnitude - 1.0) < 1e-15)

        // For pure yaw rotation, x and y should be 0
        #expect(abs(quat.x) < 1e-15)
        #expect(abs(quat.y) < 1e-15)
    }

    @Test("Zero angle axis-angle initialization")
    func zeroAngleAxisAngle() {
        let axis = SIMD3<Float>(1.0, 0.0, 0.0)
        let angle: Float = 0.0
        let quat = FloatQuaternion(axis: axis, angle: angle)

        // Zero rotation should give identity quaternion
        #expect(abs(quat.x) < 1e-6)
        #expect(abs(quat.y) < 1e-6)
        #expect(abs(quat.z) < 1e-6)
        #expect(abs(quat.w - 1.0) < 1e-6)
    }

    @Test("Zero Euler angles initialization")
    func zeroEulerAngles() {
        let quat = DoubleQuaternion(roll: 0.0, pitch: 0.0, yaw: 0.0)

        // All zero rotations should give identity quaternion
        #expect(abs(quat.x) < 1e-15)
        #expect(abs(quat.y) < 1e-15)
        #expect(abs(quat.z) < 1e-15)
        #expect(abs(quat.w - 1.0) < 1e-15)
    }
}

// MARK: - Static Properties Tests Suite
@Suite("Quaternion Static Properties")
struct QuaternionStaticPropertiesTests {

    @Test("Identity quaternion - Float")
    func identityQuaternionFloat() {
        let identity = FloatQuaternion.identity

        #expect(identity.x == 0.0)
        #expect(identity.y == 0.0)
        #expect(identity.z == 0.0)
        #expect(identity.w == 1.0)
        #expect(identity.vector == SIMD4<Float>(0, 0, 0, 1))
    }

    @Test("Identity quaternion - Double")
    func identityQuaternionDouble() {
        let identity = DoubleQuaternion.identity

        #expect(identity.x == 0.0)
        #expect(identity.y == 0.0)
        #expect(identity.z == 0.0)
        #expect(identity.w == 1.0)
        #expect(identity.vector == SIMD4<Double>(0, 0, 0, 1))
    }

    @Test("Zero quaternion - Float")
    func zeroQuaternionFloat() {
        let zero = FloatQuaternion.zero

        #expect(zero.x == 0.0)
        #expect(zero.y == 0.0)
        #expect(zero.z == 0.0)
        #expect(zero.w == 0.0)
        #expect(zero.vector == SIMD4<Float>(0, 0, 0, 0))
    }

    @Test("Zero quaternion - Double")
    func zeroQuaternionDouble() {
        let zero = DoubleQuaternion.zero

        #expect(zero.x == 0.0)
        #expect(zero.y == 0.0)
        #expect(zero.z == 0.0)
        #expect(zero.w == 0.0)
        #expect(zero.vector == SIMD4<Double>(0, 0, 0, 0))
    }

    @Test("Static properties are distinct")
    func staticPropertiesDistinct() {
        let identity = FloatQuaternion.identity
        let zero = FloatQuaternion.zero

        #expect(identity != zero)
        #expect(identity.vector != zero.vector)
    }
}

// MARK: - Component Access Tests Suite
@Suite("Quaternion Component Access")
struct QuaternionComponentAccessTests {

    @Test("Component getters")
    func componentGetters() {
        let quat = DoubleQuaternion(x: 1.1, y: 2.2, z: 3.3, w: 4.4)

        #expect(quat.x == 1.1)
        #expect(quat.y == 2.2)
        #expect(quat.z == 3.3)
        #expect(quat.w == 4.4)
    }

    @Test("Component setters")
    func componentSetters() {
        var quat = FloatQuaternion.zero

        quat.x = 10.0
        quat.y = 20.0
        quat.z = 30.0
        quat.w = 40.0

        #expect(quat.x == 10.0)
        #expect(quat.y == 20.0)
        #expect(quat.z == 30.0)
        #expect(quat.w == 40.0)
        #expect(quat.vector == SIMD4<Float>(10, 20, 30, 40))
    }

    @Test("Imaginary part getter")
    func imaginaryPartGetter() {
        let quat = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let imaginary = quat.imaginary

        #expect(imaginary == SIMD3<Double>(1.0, 2.0, 3.0))
        #expect(imaginary.x == quat.x)
        #expect(imaginary.y == quat.y)
        #expect(imaginary.z == quat.z)
    }

    @Test("Imaginary part setter")
    func imaginaryPartSetter() {
        var quat = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let newImaginary = SIMD3<Float>(10.0, 20.0, 30.0)

        quat.imaginary = newImaginary

        #expect(quat.x == 10.0)
        #expect(quat.y == 20.0)
        #expect(quat.z == 30.0)
        #expect(quat.w == 4.0)  // Real part should remain unchanged
        #expect(quat.imaginary == newImaginary)
    }

    @Test("Real part getter and setter")
    func realPartGetterSetter() {
        var quat = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)

        #expect(quat.real == 4.0)
        #expect(quat.real == quat.w)

        quat.real = 100.0

        #expect(quat.real == 100.0)
        #expect(quat.w == 100.0)
        #expect(quat.x == 1.0)  // Imaginary parts should remain unchanged
        #expect(quat.y == 2.0)
        #expect(quat.z == 3.0)
    }

    @Test("Vector property consistency")
    func vectorPropertyConsistency() {
        let quat = FloatQuaternion(x: 5.0, y: 6.0, z: 7.0, w: 8.0)

        #expect(quat.vector.x == quat.x)
        #expect(quat.vector.y == quat.y)
        #expect(quat.vector.z == quat.z)
        #expect(quat.vector.w == quat.w)
    }
}

// MARK: - Equatable Tests Suite
@Suite("Quaternion Equatable")
struct QuaternionEquatableTests {

    @Test("Equality - identical quaternions")
    func equalityIdentical() {
        let quat1 = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let quat2 = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)

        #expect(quat1 == quat2)
    }

    @Test("Equality - different quaternions")
    func equalityDifferent() {
        let quat1 = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let quat2 = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 5.0)

        #expect(quat1 != quat2)
    }

    @Test("Equality - identity quaternions")
    func equalityIdentity() {
        let identity1 = FloatQuaternion.identity
        let identity2 = FloatQuaternion.identity

        #expect(identity1 == identity2)
    }

    @Test("Equality - zero quaternions")
    func equalityZero() {
        let zero1 = DoubleQuaternion.zero
        let zero2 = DoubleQuaternion.zero

        #expect(zero1 == zero2)
    }

    @Test("Inequality - identity vs zero")
    func inequalityIdentityZero() {
        let identity = FloatQuaternion.identity
        let zero = FloatQuaternion.zero

        #expect(identity != zero)
    }

    @Test("Equality with tiny differences")
    func equalityTinyDifferences() {
        let quat1 = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let quat2 = DoubleQuaternion(x: 1.0000000000001, y: 2.0, z: 3.0, w: 4.0)

        // Should not be equal due to floating point precision
        #expect(quat1 != quat2)
    }

    @Test("Self equality")
    func selfEquality() {
        let quat = FloatQuaternion(x: 1.5, y: 2.5, z: 3.5, w: 4.5)

        #expect(quat == quat)
    }
}

// MARK: - Hashable Tests Suite
@Suite("Quaternion Hashable")
struct QuaternionHashableTests {

    @Test("Hash consistency")
    func hashConsistency() {
        let quat = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let hash1 = quat.hashValue
        let hash2 = quat.hashValue

        #expect(hash1 == hash2)
    }

    @Test("Equal quaternions have equal hashes")
    func equalQuaternionsEqualHashes() {
        let quat1 = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let quat2 = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)

        #expect(quat1 == quat2)
        #expect(quat1.hashValue == quat2.hashValue)
    }

    @Test("Different quaternions likely have different hashes")
    func differentQuaternionsDifferentHashes() {
        let quat1 = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let quat2 = FloatQuaternion(x: 5.0, y: 6.0, z: 7.0, w: 8.0)

        #expect(quat1 != quat2)
        // Hash collision is possible but unlikely for significantly different values
        #expect(quat1.hashValue != quat2.hashValue)
    }

    @Test("Set operations work correctly")
    func setOperations() {
        let quat1 = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let quat2 = DoubleQuaternion(x: 5.0, y: 6.0, z: 7.0, w: 8.0)
        let quat3 = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)  // Same as quat1

        let quaternionSet: Set = [quat1, quat2, quat3]

        #expect(quaternionSet.count == 2)  // quat1 and quat3 should be treated as the same
        #expect(quaternionSet.contains(quat1))
        #expect(quaternionSet.contains(quat2))
        #expect(quaternionSet.contains(quat3))
    }

    @Test("Dictionary keys work correctly")
    func dictionaryKeys() {
        let quat1 = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let quat2 = FloatQuaternion(x: 5.0, y: 6.0, z: 7.0, w: 8.0)

        var dict: [FloatQuaternion: String] = [:]
        dict[quat1] = "first"
        dict[quat2] = "second"

        #expect(dict[quat1] == "first")
        #expect(dict[quat2] == "second")
        #expect(dict.count == 2)

        // Overwrite with same key
        dict[quat1] = "first_updated"
        #expect(dict[quat1] == "first_updated")
        #expect(dict.count == 2)
    }
}

// MARK: - String Representation Tests Suite
@Suite("Quaternion String Representation")
struct QuaternionStringRepresentationTests {

    @Test("Description format")
    func descriptionFormat() {
        let quat = FloatQuaternion(x: 1.5, y: 2.5, z: 3.5, w: 4.5)
        let description = quat.description

        #expect(description.contains("Quaternion"))
        #expect(description.contains("1.5"))
        #expect(description.contains("2.5"))
        #expect(description.contains("3.5"))
        #expect(description.contains("4.5"))
        #expect(description.contains("x:"))
        #expect(description.contains("y:"))
        #expect(description.contains("z:"))
        #expect(description.contains("w:"))
    }

    @Test("Debug description format")
    func debugDescriptionFormat() {
        let quat = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let debugDescription = quat.debugDescription

        #expect(debugDescription.contains("Quaternion<Double>"))
        #expect(debugDescription.contains("1.0"))
        #expect(debugDescription.contains("2.0"))
        #expect(debugDescription.contains("3.0"))
        #expect(debugDescription.contains("4.0"))
    }

    @Test("Identity quaternion description")
    func identityQuaternionDescription() {
        let identity = FloatQuaternion.identity
        let description = identity.description

        #expect(description.contains("0.0"))
        #expect(description.contains("1.0"))
    }

    @Test("Zero quaternion description")
    func zeroQuaternionDescription() {
        let zero = DoubleQuaternion.zero
        let description = zero.description

        #expect(description.contains("0.0"))
        // Should contain four instances of "0.0"
        let zeroCount = description.components(separatedBy: "0.0").count - 1
        #expect(zeroCount == 4)
    }

    @Test("Negative values description")
    func negativeValuesDescription() {
        let quat = FloatQuaternion(x: -1.0, y: -2.0, z: 3.0, w: -4.0)
        let description = quat.description

        #expect(description.contains("-1.0"))
        #expect(description.contains("-2.0"))
        #expect(description.contains("3.0"))
        #expect(description.contains("-4.0"))
    }
}

// MARK: - Codable Tests Suite
@Suite("Quaternion Codable")
struct QuaternionCodableTests {

    @Test("JSON encoding - Float")
    func jsonEncodingFloat() throws {
        let quat = FloatQuaternion(x: 1.5, y: 2.5, z: 3.5, w: 4.5)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(quat)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"x\""))
        #expect(jsonString.contains("\"y\""))
        #expect(jsonString.contains("\"z\""))
        #expect(jsonString.contains("\"w\""))
        #expect(jsonString.contains("1.5"))
        #expect(jsonString.contains("2.5"))
        #expect(jsonString.contains("3.5"))
        #expect(jsonString.contains("4.5"))
    }

    @Test("JSON decoding - Float")
    func jsonDecodingFloat() throws {
        let jsonString = """
            {
                "x": 1.5,
                "y": 2.5,
                "z": 3.5,
                "w": 4.5
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let quat = try decoder.decode(FloatQuaternion.self, from: data)

        #expect(quat.x == 1.5)
        #expect(quat.y == 2.5)
        #expect(quat.z == 3.5)
        #expect(quat.w == 4.5)
    }

    @Test("JSON encoding - Double")
    func jsonEncodingDouble() throws {
        let quat = DoubleQuaternion(x: 0.1, y: 0.2, z: 0.3, w: 0.4)

        let encoder = JSONEncoder()
        let data = try encoder.encode(quat)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("0.1"))
        #expect(jsonString.contains("0.2"))
        #expect(jsonString.contains("0.3"))
        #expect(jsonString.contains("0.4"))
    }

    @Test("JSON decoding - Double")
    func jsonDecodingDouble() throws {
        let jsonString = """
            {
                "x": 0.123456789,
                "y": 0.987654321,
                "z": 0.555555555,
                "w": 0.777777777
            }
            """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let quat = try decoder.decode(DoubleQuaternion.self, from: data)

        #expect(abs(quat.x - 0.123456789) < 1e-15)
        #expect(abs(quat.y - 0.987654321) < 1e-15)
        #expect(abs(quat.z - 0.555555555) < 1e-15)
        #expect(abs(quat.w - 0.777777777) < 1e-15)
    }

    @Test("Round trip encoding/decoding - Float")
    func roundTripFloat() throws {
        let original = FloatQuaternion(x: 10.1, y: 20.2, z: 30.3, w: 40.4)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FloatQuaternion.self, from: data)

        #expect(decoded == original)
    }

    @Test("Round trip encoding/decoding - Double")
    func roundTripDouble() throws {
        let original = DoubleQuaternion(x: -5.5, y: 6.6, z: -7.7, w: 8.8)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DoubleQuaternion.self, from: data)

        #expect(decoded == original)
    }

    @Test("Identity quaternion encoding/decoding")
    func identityQuaternionCoding() throws {
        let identity = FloatQuaternion.identity

        let encoder = JSONEncoder()
        let data = try encoder.encode(identity)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FloatQuaternion.self, from: data)

        #expect(decoded == identity)
        #expect(decoded == FloatQuaternion.identity)
    }

    @Test("Zero quaternion encoding/decoding")
    func zeroQuaternionCoding() throws {
        let zero = DoubleQuaternion.zero

        let encoder = JSONEncoder()
        let data = try encoder.encode(zero)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DoubleQuaternion.self, from: data)

        #expect(decoded == zero)
        #expect(decoded == DoubleQuaternion.zero)
    }

    @Test("Malformed JSON decoding error")
    func malformedJsonDecoding() throws {
        let malformedJson = """
            {
                "x": 1.0,
                "y": 2.0,
                "z": "not_a_number"
            }
            """

        let data = malformedJson.data(using: .utf8)!
        let decoder = JSONDecoder()

        #expect(throws: Error.self) {
            try decoder.decode(FloatQuaternion.self, from: data)
        }
    }

    @Test("Missing field JSON decoding error")
    func missingFieldJsonDecoding() throws {
        let incompleteJson = """
            {
                "x": 1.0,
                "y": 2.0,
                "z": 3.0
            }
            """

        let data = incompleteJson.data(using: .utf8)!
        let decoder = JSONDecoder()

        #expect(throws: Error.self) {
            try decoder.decode(DoubleQuaternion.self, from: data)
        }
    }

    @Test("Extra fields JSON decoding")
    func extraFieldsJsonDecoding() throws {
        let jsonWithExtraFields = """
            {
                "x": 1.0,
                "y": 2.0,
                "z": 3.0,
                "w": 4.0,
                "extra_field": "ignored"
            }
            """

        let data = jsonWithExtraFields.data(using: .utf8)!
        let decoder = JSONDecoder()
        let quat = try decoder.decode(FloatQuaternion.self, from: data)

        #expect(quat.x == 1.0)
        #expect(quat.y == 2.0)
        #expect(quat.z == 3.0)
        #expect(quat.w == 4.0)
    }

    @Test("Extreme values encoding/decoding")
    func extremeValuesCoding() throws {
        let extreme = DoubleQuaternion(
            x: Double.greatestFiniteMagnitude,
            y: -Double.greatestFiniteMagnitude,
            z: Double.leastNormalMagnitude,
            w: -Double.leastNormalMagnitude
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(extreme)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DoubleQuaternion.self, from: data)

        #expect(decoded == extreme)
    }
}

// MARK: - Type Alias Tests Suite
@Suite("Quaternion Type Aliases")
struct QuaternionTypeAliasTests {

    @Test("FloatQuaternion type alias")
    func floatQuaternionTypeAlias() {
        let quat: FloatQuaternion = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let explicitType: Quaternion<Float> = Quaternion<Float>(x: 1.0, y: 2.0, z: 3.0, w: 4.0)

        #expect(quat == explicitType)
        #expect(type(of: quat) == type(of: explicitType))
    }

    @Test("DoubleQuaternion type alias")
    func doubleQuaternionTypeAlias() {
        let quat: DoubleQuaternion = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let explicitType: Quaternion<Double> = Quaternion<Double>(x: 1.0, y: 2.0, z: 3.0, w: 4.0)

        #expect(quat == explicitType)
        #expect(type(of: quat) == type(of: explicitType))
    }

    @Test("Type alias static properties")
    func typeAliasStaticProperties() {
        let floatIdentity = FloatQuaternion.identity
        let doubleIdentity = DoubleQuaternion.identity

        #expect(floatIdentity.w == 1.0)
        #expect(doubleIdentity.w == 1.0)

        let floatZero = FloatQuaternion.zero
        let doubleZero = DoubleQuaternion.zero

        #expect(floatZero.w == 0.0)
        #expect(doubleZero.w == 0.0)
    }
}

// MARK: - Edge Cases and Error Conditions Tests Suite
@Suite("Quaternion Edge Cases")
struct QuaternionEdgeCasesTests {

    @Test("Very small values")
    func verySmallValues() {
        let tiny = FloatQuaternion(
            x: Float.leastNormalMagnitude,
            y: -Float.leastNormalMagnitude,
            z: Float.leastNormalMagnitude * 2,
            w: Float.leastNormalMagnitude * 3
        )

        #expect(tiny.x == Float.leastNormalMagnitude)
        #expect(tiny.y == -Float.leastNormalMagnitude)
        #expect(tiny.z == Float.leastNormalMagnitude * 2)
        #expect(tiny.w == Float.leastNormalMagnitude * 3)
    }

    @Test("Very large values")
    func veryLargeValues() {
        let huge = DoubleQuaternion(
            x: Double.greatestFiniteMagnitude / 4,
            y: -Double.greatestFiniteMagnitude / 4,
            z: Double.greatestFiniteMagnitude / 8,
            w: Double.greatestFiniteMagnitude / 8
        )

        #expect(huge.x == Double.greatestFiniteMagnitude / 4)
        #expect(huge.y == -Double.greatestFiniteMagnitude / 4)
        #expect(huge.z == Double.greatestFiniteMagnitude / 8)
        #expect(huge.w == Double.greatestFiniteMagnitude / 8)
    }

    @Test("Zero axis normalization in axis-angle init")
    func zeroAxisNormalization() {
        // This tests the behavior when simd_normalize receives a zero vector
        // Note: simd_normalize of zero vector returns NaN components
        let zeroAxis = SIMD3<Float>(0.0, 0.0, 0.0)
        let quat = FloatQuaternion(axis: zeroAxis, angle: .pi / 4)

        // The resulting quaternion should have NaN in x, y, z components
        // but w should still be cos(angle/2)
        #expect(quat.x.isNaN)
        #expect(quat.y.isNaN)
        #expect(quat.z.isNaN)
        #expect(abs(quat.w - cos(.pi / 8)) < 1e-6)
    }

    @Test("Large angle in axis-angle initialization")
    func largeAngleAxisAngle() {
        let axis = SIMD3<Double>(0.0, 1.0, 0.0)
        let largeAngle = 4.0 * .pi  // 720 degrees
        let quat = DoubleQuaternion(axis: axis, angle: largeAngle)

        // Should still produce a valid quaternion
        let magnitude = sqrt(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w)
        #expect(abs(magnitude - 1.0) < 1e-15)
    }

    @Test("Large Euler angles")
    func largeEulerAngles() {
        let roll = 10.0 * .pi  // 1800 degrees
        let pitch = -5.0 * .pi  // -900 degrees
        let yaw = 3.0 * .pi  // 540 degrees

        let quat = FloatQuaternion(roll: Float(roll), pitch: Float(pitch), yaw: Float(yaw))

        // Should still produce a valid quaternion
        let magnitude = sqrt(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w)
        #expect(abs(magnitude - 1.0) < 1e-6)
    }

    @Test("Precision comparison between Float and Double")
    func precisionComparison() {
        let axis = SIMD3<Double>(1.0, 1.0, 1.0)
        let angle = Double.pi / 3

        let doubleQuat = DoubleQuaternion(axis: axis, angle: angle)
        let floatQuat = FloatQuaternion(
            axis: SIMD3<Float>(Float(axis.x), Float(axis.y), Float(axis.z)),
            angle: Float(angle)
        )

        // The values should be approximately equal but Double should be more precise
        #expect(abs(Double(floatQuat.x) - doubleQuat.x) < 1e-6)
        #expect(abs(Double(floatQuat.y) - doubleQuat.y) < 1e-6)
        #expect(abs(Double(floatQuat.z) - doubleQuat.z) < 1e-6)
        #expect(abs(Double(floatQuat.w) - doubleQuat.w) < 1e-6)
    }

    @Test("Sendable conformance")
    func sendableConformance() {
        // This test ensures quaternions can be passed across actor boundaries
        let quat = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)

        Task {
            let capturedQuat = quat  // Should compile without warnings
            #expect(capturedQuat.x == 1.0)
        }
    }

    @Test("Memory layout includes normalization flag")
    func memoryLayoutIncludesNormalizationFlag() {
        // The quaternion now has a SIMD4 vector plus a Bool flag
        // So it should be larger than just SIMD4<Double>
        #expect(MemoryLayout<DoubleQuaternion>.size > MemoryLayout<SIMD4<Double>>.size)

        // Alignment should still match SIMD4 for performance
        #expect(MemoryLayout<DoubleQuaternion>.alignment == MemoryLayout<SIMD4<Double>>.alignment)

        // Stride includes padding, should be at least as large as size
        #expect(MemoryLayout<DoubleQuaternion>.stride >= MemoryLayout<DoubleQuaternion>.size)
    }
}

// MARK: - Normalization Flag Tests Suite
@Suite("Quaternion Normalization Flag")
struct QuaternionNormalizationFlagTests {

    @Test("Flag defaults to false for basic initialization")
    func flagDefaultsFalse() {
        let quat = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        #expect(quat.isNormalized == false)
    }

    @Test("Flag can be set to true in basic initialization")
    func flagCanBeSetTrue() {
        let quat = DoubleQuaternion(x: 0.0, y: 0.0, z: 0.0, w: 1.0, isNormalized: true)
        #expect(quat.isNormalized == true)
    }

    @Test("Identity quaternion is marked as normalized")
    func identityIsNormalized() {
        let identity = FloatQuaternion.identity
        #expect(identity.isNormalized == true)
    }

    @Test("Zero quaternion is not marked as normalized")
    func zeroNotNormalized() {
        let zero = DoubleQuaternion.zero
        #expect(zero.isNormalized == false)
    }

    @Test("Axis-angle initialization is marked as normalized")
    func axisAngleIsNormalized() {
        let quat = FloatQuaternion(axis: SIMD3<Float>(0, 1, 0), angle: .pi / 4)
        #expect(quat.isNormalized == true)
    }

    @Test("Euler angles initialization is marked as normalized")
    func eulerAnglesIsNormalized() {
        let quat = DoubleQuaternion(roll: .pi / 6, pitch: .pi / 4, yaw: .pi / 3)
        #expect(quat.isNormalized == true)
    }

    @Test("Vector initialization respects isNormalized parameter")
    func vectorInitRespectsFlagParameter() {
        let normalizedVec = SIMD4<Float>(0, 0, 0, 1)
        let quat1 = FloatQuaternion(vector: normalizedVec, isNormalized: true)
        #expect(quat1.isNormalized == true)

        let quat2 = FloatQuaternion(vector: normalizedVec, isNormalized: false)
        #expect(quat2.isNormalized == false)
    }

    @Test("Imaginary/real initialization respects isNormalized parameter")
    func imaginaryRealInitRespectsFlagParameter() {
        let quat1 = DoubleQuaternion(imaginary: SIMD3<Double>(0, 0, 0), real: 1.0, isNormalized: true)
        #expect(quat1.isNormalized == true)

        let quat2 = DoubleQuaternion(imaginary: SIMD3<Double>(0, 0, 0), real: 1.0, isNormalized: false)
        #expect(quat2.isNormalized == false)
    }
}

// MARK: - Normalization Flag Invalidation Tests Suite
@Suite("Quaternion Normalization Flag Invalidation")
struct QuaternionNormalizationFlagInvalidationTests {

    @Test("Modifying x invalidates flag")
    func modifyingXInvalidatesFlag() {
        var quat = FloatQuaternion.identity
        #expect(quat.isNormalized == true)

        quat.x = 0.5
        #expect(quat.isNormalized == false)
    }

    @Test("Modifying y invalidates flag")
    func modifyingYInvalidatesFlag() {
        var quat = DoubleQuaternion(axis: SIMD3<Double>(0, 1, 0), angle: .pi / 4)
        #expect(quat.isNormalized == true)

        quat.y = 0.1
        #expect(quat.isNormalized == false)
    }

    @Test("Modifying z invalidates flag")
    func modifyingZInvalidatesFlag() {
        var quat = FloatQuaternion.identity
        #expect(quat.isNormalized == true)

        quat.z = 0.3
        #expect(quat.isNormalized == false)
    }

    @Test("Modifying w invalidates flag")
    func modifyingWInvalidatesFlag() {
        var quat = DoubleQuaternion.identity
        #expect(quat.isNormalized == true)

        quat.w = 0.9
        #expect(quat.isNormalized == false)
    }

    @Test("Modifying imaginary invalidates flag")
    func modifyingImaginaryInvalidatesFlag() {
        var quat = FloatQuaternion.identity
        #expect(quat.isNormalized == true)

        quat.imaginary = SIMD3<Float>(0.1, 0.2, 0.3)
        #expect(quat.isNormalized == false)
    }

    @Test("Modifying real invalidates flag")
    func modifyingRealInvalidatesFlag() {
        var quat = DoubleQuaternion.identity
        #expect(quat.isNormalized == true)

        quat.real = 0.5
        #expect(quat.isNormalized == false)
    }

    @Test("Modifying vector invalidates flag")
    func modifyingVectorInvalidatesFlag() {
        var quat = FloatQuaternion.identity
        #expect(quat.isNormalized == true)

        quat.vector = SIMD4<Float>(1, 2, 3, 4)
        #expect(quat.isNormalized == false)
    }

    @Test("Compound operator on x invalidates flag")
    func compoundOperatorOnXInvalidatesFlag() {
        var quat = DoubleQuaternion.identity
        #expect(quat.isNormalized == true)

        quat.x += 0.1
        #expect(quat.isNormalized == false)
    }

    @Test("Compound operator on w invalidates flag")
    func compoundOperatorOnWInvalidatesFlag() {
        var quat = FloatQuaternion(axis: SIMD3<Float>(1, 0, 0), angle: .pi / 2)
        #expect(quat.isNormalized == true)

        quat.w *= 0.5
        #expect(quat.isNormalized == false)
    }

    @Test("Setting to same value still invalidates flag")
    func settingToSameValueInvalidatesFlag() {
        var quat = DoubleQuaternion.identity
        #expect(quat.isNormalized == true)

        let originalX = quat.x
        quat.x = originalX  // Set to same value
        #expect(quat.isNormalized == false)
    }
}

// MARK: - Normalization Operations Tests Suite
@Suite("Quaternion Normalization Operations")
struct QuaternionNormalizationOperationsTests {

    @Test("normalize() mutates quaternion - Float")
    func normalizeMutatesFloat() {
        var quat = FloatQuaternion(x: 3.0, y: 4.0, z: 0.0, w: 0.0)
        #expect(quat.isNormalized == false)

        quat.normalize()

        let magnitude = sqrt(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w)
        #expect(abs(magnitude - 1.0) < 1e-6)
        #expect(quat.isNormalized == true)
    }

    @Test("normalize() mutates quaternion - Double")
    func normalizeMutatesDouble() {
        var quat = DoubleQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        #expect(quat.isNormalized == false)

        quat.normalize()

        let magnitude = sqrt(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w)
        #expect(abs(magnitude - 1.0) < 1e-15)
        #expect(quat.isNormalized == true)
    }

    @Test("normalize() on near-zero quaternion gives identity")
    func normalizeNearZeroGivesIdentity() {
        var quat = FloatQuaternion(x: 1e-10, y: 1e-10, z: 1e-10, w: 1e-10)
        quat.normalize()

        #expect(quat == FloatQuaternion.identity)
        #expect(quat.isNormalized == true)
    }

    @Test("normalized property returns new quaternion - Float")
    func normalizedReturnsNewFloat() {
        let original = FloatQuaternion(x: 2.0, y: 0.0, z: 0.0, w: 0.0)
        let normalized = original.normalized

        // Original should be unchanged
        #expect(original.x == 2.0)
        #expect(original.isNormalized == false)

        // Normalized should be unit length
        let magnitude = sqrt(
            normalized.x * normalized.x + normalized.y * normalized.y + normalized.z * normalized.z + normalized.w
                * normalized.w
        )
        #expect(abs(magnitude - 1.0) < 1e-6)
        #expect(normalized.isNormalized == true)
    }

    @Test("normalized property returns new quaternion - Double")
    func normalizedReturnsNewDouble() {
        let original = DoubleQuaternion(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
        let normalized = original.normalized

        // Original should be unchanged
        #expect(original.x == 1.0)
        #expect(original.isNormalized == false)

        // Normalized should be unit length
        let magnitude = sqrt(
            normalized.x * normalized.x + normalized.y * normalized.y + normalized.z * normalized.z + normalized.w
                * normalized.w
        )
        #expect(abs(magnitude - 1.0) < 1e-15)
        #expect(normalized.isNormalized == true)
    }

    @Test("normalized on near-zero quaternion returns identity")
    func normalizedNearZeroReturnsIdentity() {
        let quat = DoubleQuaternion(x: 1e-20, y: 1e-20, z: 1e-20, w: 1e-20)
        let normalized = quat.normalized

        #expect(normalized == DoubleQuaternion.identity)
        #expect(normalized.isNormalized == true)
    }

    @Test("normalize() sets flag correctly")
    func normalizeSetsFlagCorrectly() {
        var quat = FloatQuaternion(x: 1.0, y: 0.0, z: 0.0, w: 0.0)
        #expect(quat.isNormalized == false)

        quat.normalize()
        #expect(quat.isNormalized == true)
    }

    @Test("normalizing already normalized quaternion maintains flag")
    func normalizingNormalizedMaintainsFlag() {
        var quat = DoubleQuaternion.identity
        #expect(quat.isNormalized == true)

        quat.normalize()
        #expect(quat.isNormalized == true)
    }
}

// MARK: - Magnitude Tests Suite
@Suite("Quaternion Magnitude")
struct QuaternionMagnitudeTests {

    @Test("magnitude of unit quaternion - Float")
    func magnitudeOfUnitFloat() {
        let quat = FloatQuaternion.identity
        #expect(abs(quat.magnitude - 1.0) < 1e-6)
    }

    @Test("magnitude of unit quaternion - Double")
    func magnitudeOfUnitDouble() {
        let quat = DoubleQuaternion.identity
        #expect(abs(quat.magnitude - 1.0) < 1e-15)
    }

    @Test("magnitude calculation - Float")
    func magnitudeCalculationFloat() {
        let quat = FloatQuaternion(x: 3.0, y: 4.0, z: 0.0, w: 0.0)
        let expectedMagnitude: Float = 5.0  // sqrt(9 + 16) = 5
        #expect(abs(quat.magnitude - expectedMagnitude) < 1e-6)
    }

    @Test("magnitude calculation - Double")
    func magnitudeCalculationDouble() {
        let quat = DoubleQuaternion(x: 1.0, y: 2.0, z: 2.0, w: 0.0)
        let expectedMagnitude = sqrt(1.0 + 4.0 + 4.0)  // sqrt(9) = 3
        #expect(abs(quat.magnitude - expectedMagnitude) < 1e-15)
    }

    @Test("magnitudeSquared of unit quaternion")
    func magnitudeSquaredOfUnit() {
        let quat = FloatQuaternion.identity
        #expect(abs(quat.magnitudeSquared - 1.0) < 1e-6)
    }

    @Test("magnitudeSquared calculation")
    func magnitudeSquaredCalculation() {
        let quat = DoubleQuaternion(x: 2.0, y: 3.0, z: 4.0, w: 5.0)
        let expectedMagnitudeSquared = 4.0 + 9.0 + 16.0 + 25.0  // = 54
        #expect(abs(quat.magnitudeSquared - expectedMagnitudeSquared) < 1e-15)
    }

    @Test("magnitudeSquared is more efficient than magnitude squared")
    func magnitudeSquaredVsMagnitude() {
        let quat = FloatQuaternion(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        let magSquared = quat.magnitudeSquared
        let mag = quat.magnitude
        // Use 1e-5 tolerance for Float due to accumulated rounding errors
        #expect(abs(magSquared - (mag * mag)) < 1e-5)
    }

    @Test("magnitude of zero quaternion")
    func magnitudeOfZero() {
        let zero = DoubleQuaternion.zero
        #expect(zero.magnitude == 0.0)
        #expect(zero.magnitudeSquared == 0.0)
    }

    @Test("isUnit returns true for normalized quaternion")
    func isUnitForNormalized() {
        let quat = FloatQuaternion(axis: SIMD3<Float>(0, 1, 0), angle: .pi / 4)
        #expect(quat.isUnit == true)
    }

    @Test("isUnit returns false for unnormalized quaternion")
    func isUnitForUnnormalized() {
        let quat = DoubleQuaternion(x: 2.0, y: 3.0, z: 4.0, w: 5.0)
        #expect(quat.isUnit == false)
    }

    @Test("isUnit computes actual normalization status")
    func isUnitComputesActualStatus() {
        // Create a quaternion that's actually normalized but flag says otherwise
        let quat = FloatQuaternion(x: 0.0, y: 0.0, z: 0.0, w: 1.0, isNormalized: false)
        #expect(quat.isNormalized == false)  // Cached flag is false
        #expect(quat.isUnit == true)  // But it's actually a unit quaternion
    }
}

// MARK: - Rotation Matrix Elements Tests Suite
@Suite("Quaternion Rotation Matrix Elements")
struct QuaternionRotationMatrixElementsTests {

    @Test("Identity quaternion matrix elements")
    func identityMatrixElements() {
        let identity = FloatQuaternion.identity

        // Identity rotation matrix should have 1s on diagonal, 0s elsewhere (upper triangle)
        #expect(abs(identity.xx - 1.0) < 1e-6)
        #expect(abs(identity.yy - 1.0) < 1e-6)
        #expect(abs(identity.zz - 1.0) < 1e-6)
        #expect(abs(identity.xy) < 1e-6)
        #expect(abs(identity.xz) < 1e-6)
        #expect(abs(identity.yz) < 1e-6)
    }

    @Test("Matrix element properties exist - Float")
    func matrixElementPropertiesFloat() {
        let quat = FloatQuaternion(axis: SIMD3<Float>(1, 1, 1), angle: .pi / 3)

        // Verify all properties are accessible and return finite values
        #expect(quat.xy.isFinite)
        #expect(quat.xz.isFinite)
        #expect(quat.yz.isFinite)
        #expect(quat.xx.isFinite)
        #expect(quat.yy.isFinite)
        #expect(quat.zz.isFinite)
    }

    @Test("Matrix element properties exist - Double")
    func matrixElementPropertiesDouble() {
        let quat = DoubleQuaternion(roll: .pi / 6, pitch: .pi / 4, yaw: .pi / 3)

        // Verify all properties are accessible and return finite values
        #expect(quat.xy.isFinite)
        #expect(quat.xz.isFinite)
        #expect(quat.yz.isFinite)
        #expect(quat.xx.isFinite)
        #expect(quat.yy.isFinite)
        #expect(quat.zz.isFinite)
    }

    @Test("90-degree Y-axis rotation matrix elements")
    func ninetyDegreeYRotation() {
        // 90-degree rotation around Y-axis
        let quat = DoubleQuaternion(axis: SIMD3<Double>(0, 1, 0), angle: .pi / 2)

        // For 90° Y rotation: xx≈0, yy≈1, zz≈0, xy≈0, xz≈-1, yz≈0
        #expect(abs(quat.yy - 1.0) < 1e-15)
        #expect(abs(quat.xy) < 1e-15)
        #expect(abs(quat.yz) < 1e-15)
    }

    @Test("Diagonal elements for normalized quaternion")
    func diagonalElementsNormalized() {
        let quat = FloatQuaternion(axis: SIMD3<Float>(1, 0, 0), angle: .pi / 4)

        // For normalized quaternion, diagonal elements should be in [-1, 1]
        #expect(quat.xx >= -1.0 && quat.xx <= 1.0)
        #expect(quat.yy >= -1.0 && quat.yy <= 1.0)
        #expect(quat.zz >= -1.0 && quat.zz <= 1.0)
    }

    @Test("Matrix elements for known quaternion values")
    func matrixElementsForKnownValues() {
        // Quaternion (0, 0, 0, 1) = identity
        let quat = DoubleQuaternion(x: 0.0, y: 0.0, z: 0.0, w: 1.0)

        #expect(abs(quat.xx - 1.0) < 1e-15)
        #expect(abs(quat.yy - 1.0) < 1e-15)
        #expect(abs(quat.zz - 1.0) < 1e-15)
        #expect(abs(quat.xy) < 1e-15)
        #expect(abs(quat.xz) < 1e-15)
        #expect(abs(quat.yz) < 1e-15)
    }

    @Test("Matrix elements are consistent across calls")
    func matrixElementsConsistentAcrossCalls() {
        let quat = FloatQuaternion(x: 0.5, y: 0.5, z: 0.5, w: 0.5)

        // Read each element twice and verify consistency
        #expect(quat.xy == quat.xy)
        #expect(quat.xz == quat.xz)
        #expect(quat.yz == quat.yz)
        #expect(quat.xx == quat.xx)
        #expect(quat.yy == quat.yy)
        #expect(quat.zz == quat.zz)
    }

    @Test("Off-diagonal elements for pure rotation")
    func offDiagonalElementsPureRotation() {
        // A pure 180° rotation around X-axis
        let quat = FloatQuaternion(axis: SIMD3<Float>(1, 0, 0), angle: .pi)

        // For 180° X rotation: xx=1, yy=-1, zz=-1, xy≈0, xz≈0, yz≈0
        #expect(abs(quat.xx - 1.0) < 1e-6)
        #expect(abs(quat.yy - (-1.0)) < 1e-6)
        #expect(abs(quat.zz - (-1.0)) < 1e-6)
    }

    @Test("Matrix elements for unnormalized quaternion")
    func matrixElementsForUnnormalized() {
        // Matrix elements should still be computable for unnormalized quaternions
        let quat = DoubleQuaternion(x: 2.0, y: 3.0, z: 4.0, w: 5.0)

        // Should return values without crashing
        #expect(quat.xy.isFinite)
        #expect(quat.xz.isFinite)
        #expect(quat.yz.isFinite)
        #expect(quat.xx.isFinite)
        #expect(quat.yy.isFinite)
        #expect(quat.zz.isFinite)
    }
}
