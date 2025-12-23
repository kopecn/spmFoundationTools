
/// Time scale specification for precision timestamps.
///
/// Recommended default: `.tai` (International Atomic Time)
public enum Timescale: String, Codable, Sendable, Hashable {
    /// International Atomic Time - continuous atomic time scale
    case tai = "TAI"

    /// Terrestrial Time - theoretical ideal time scale at Earth's surface
    case tt = "TT"

    /// Barycentric Coordinate Time - coordinate time at solar system barycenter
    case tcb = "TCB"

    /// Barycentric Dynamical Time - time scale for solar system dynamics
    case tdb = "TDB"

    /// Coordinated Universal Time - civil time standard with leap seconds
    case utc = "UTC"

    /// GPS Time - continuous time scale used by GPS satellites
    case gps = "GPS"

    /// Universal Time - based on Earth's rotation
    case ut1 = "UT1"

    /// Geocentric Coordinate Time - coordinate time in geocentric frame
    case tcg = "TCG"
}