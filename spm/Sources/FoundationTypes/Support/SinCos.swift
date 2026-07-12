import Foundation

#if canImport(Darwin)
import Darwin
#endif

/// Computes sine and cosine of `x` in a single call.
///
/// On Darwin platforms this routes through `__sincos`, the combined libm
/// entry point. On other platforms (Linux) it falls back to separate
/// `sin`/`cos` calls — modern compilers commonly fuse the pair anyway, and
/// no combined entry point is portably available outside Darwin's libm.
@usableFromInline
internal func sincos(_ x: Double) -> (sin: Double, cos: Double) {
    #if canImport(Darwin)
    var s = 0.0
    var c = 0.0
    __sincos(x, &s, &c)
    return (s, c)
    #else
    return (Foundation.sin(x), Foundation.cos(x))
    #endif
}

/// Computes sine and cosine of `x` in a single call (`Float` overload).
///
/// See the `Double` overload above for the platform rationale.
@usableFromInline
internal func sincos(_ x: Float) -> (sin: Float, cos: Float) {
    #if canImport(Darwin)
    var s: Float = 0
    var c: Float = 0
    __sincosf(x, &s, &c)
    return (s, c)
    #else
    return (Foundation.sinf(x), Foundation.cosf(x))
    #endif
}
