enum TimestampError: Error {
    case incompatibleTimeScale
    case incompatibleReferenceFrame
    case overlappingUncertainty
}