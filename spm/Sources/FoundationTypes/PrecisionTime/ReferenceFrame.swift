/// Spatial reference frame for precision timestamps (accounting for relativistic effects).
///
/// Recommended default: `.earthCenter` (geocentric)
public enum ReferenceFrame: String, Codable, Sendable, Hashable {
    /// Geocentric - Earth's center of mass
    case earthCenter = "EarthCenter"

    /// Solar system barycenter - center of mass of the solar system
    case solarSystemBarycenter = "SolarSystemBarycenter"

    /// Topocentric - observer's location on Earth's surface
    case topocentric = "Topocentric"

    /// Heliocentric - Sun's center of mass
    case heliocentric = "Heliocentric"

    /// Lunar center - Moon's center of mass
    case lunarCenter = "LunarCenter"
}
