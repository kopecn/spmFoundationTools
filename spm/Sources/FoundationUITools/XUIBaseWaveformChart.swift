import DefaultBackend
import Foundation
import FoundationTypes
import SwiftCrossUI

// Simple point structure for SwiftCrossUI compatibility
private struct Point {
    let x: Double
    let y: Double
}

public struct XUIBaseWaveformChart: View {
    // Waveform data
    private let waveforms: [DoubleWaveform1D]
    private let colors: [Color]
    private let labels: [String]

    // Axis labels
    private let xAxisLabel: String
    private let yAxisLabel: String

    // Chart state
    @State private var zoomScale: Double = 1.0
    @State private var panOffset: Double = 0.0

    // Cursor state
    private let showCursor: Bool
    @State private var cursorPosition: Double = 0.5  // 0.0 to 1.0, normalized position

    // Chart dimensions (margins only, actual size from GeometryReader)
    private let margin: Double = 40

    // Stride factor to reduce rendering complexity
    private let maxPointsToRender: Int = 1000

    // Default colors for waveforms (SwiftCrossUI compatible)
    private static let defaultColors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .cyan, .yellow,
    ]

    public init(
        waveforms: [DoubleWaveform1D],
        labels: [String]? = nil,
        colors: [Color]? = nil,
        xAxisLabel: String = "Time",
        yAxisLabel: String = "Amplitude",
        showCursor: Bool = false
    ) {
        self.waveforms = waveforms
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
        self.showCursor = showCursor

        // Ensure labels array matches waveforms count
        if let providedLabels = labels {
            if providedLabels.count >= waveforms.count {
                self.labels = Array(providedLabels.prefix(waveforms.count))
            } else {
                let additionalLabels = (providedLabels.count..<waveforms.count).map { "Waveform \($0 + 1)" }
                self.labels = providedLabels + additionalLabels
            }
        } else {
            self.labels = Array(0..<waveforms.count).map { "Waveform \($0 + 1)" }
        }

        // Ensure colors array matches waveforms count
        if let providedColors = colors {
            if providedColors.count >= waveforms.count {
                self.colors = Array(providedColors.prefix(waveforms.count))
            } else {
                self.colors = Array(0..<waveforms.count).map { index in
                    if index < providedColors.count {
                        return providedColors[index]
                    } else {
                        return Self.defaultColors[index % Self.defaultColors.count]
                    }
                }
            }
        } else {
            self.colors = Array(0..<waveforms.count).map { index in
                Self.defaultColors[index % Self.defaultColors.count]
            }
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title and legend
            HStack {
                Text("Waveform Chart")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // Legend
                HStack(spacing: 15) {
                    legendItems
                }
            }
            .padding(.horizontal, Int(margin))

            // Chart with axis labels and tick labels
            HStack(spacing: 5) {
                // Y-axis numeric labels and axis label
                VStack(spacing: 2) {

                    Text(yAxisLabel)
                        .font(.caption)
                        .frame(height: 20)
                }
                .frame(width: 60)

                // Chart area with GeometryReader and X-axis labels
                VStack(spacing: 2) {
                    GeometryReader { geometry in
                        chartArea(
                            chartWidth: Double(geometry.size.x),
                            chartHeight: Double(geometry.size.y)
                        )
                    }
                    xAxisLabels

                    // Cursor value display (if cursor enabled)
                    if showCursor {
                        HStack(alignment: .center) {
                            Text(xAxisLabel)
                                .font(.caption)
                                .frame(height: 15)
                            Spacer()
                                .frame(width: 20)
                            cursorValueDisplay
                                .frame(height: 20)
                        }
                    } else {
                        Text(xAxisLabel)
                            .font(.caption)
                            .frame(height: 15)
                    }

                    // X-axis label

                    // Slider (if cursor enabled)
                    if showCursor {
                        Slider($cursorPosition, minimum: 0.0, maximum: 1.0)
                            .frame(height: 14)
                    }
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func chartArea(chartWidth: Double, chartHeight: Double) -> some View {
        ZStack(alignment: .topLeading) {
            // Background using a shape
            BackgroundShape(chartWidth: chartWidth, chartHeight: chartHeight)
                .fill(.gray.opacity(0.1))
                .frame(width: Int(chartWidth), height: Int(chartHeight))

            // Chart content
            chartContent(chartWidth: chartWidth, chartHeight: chartHeight)

            // Vertical cursor line (if cursor enabled)
            if showCursor {
                cursorLine(chartWidth: chartWidth, chartHeight: chartHeight)
            }
        }
        .frame(width: Int(chartWidth), height: Int(chartHeight))
    }

    @ViewBuilder
    private var legendItems: some View {
        // SwiftCrossUI's ForEach is limited, so build views manually
        let maxCount = min(waveforms.count, colors.count, labels.count)
        ForEach(0..<maxCount) { index in
            HStack(spacing: 5) {
                Rectangle()
                    .fill(colors[index])
                    .frame(width: 8, height: 8)
                Text(labels[index])
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func chartContent(chartWidth: Double, chartHeight: Double) -> some View {
        ZStack(alignment: .topLeading) {
            // Grid lines
            gridLines(chartWidth: chartWidth, chartHeight: chartHeight)

            // Axis tick marks only (no labels here)
            axisTickMarks(chartWidth: chartWidth, chartHeight: chartHeight)

            // Waveforms - overlay in Z
            waveformViews(chartWidth: chartWidth, chartHeight: chartHeight)

            yAxisViews(chartWidth: chartWidth, chartHeight: chartHeight)
        }
        .frame(width: Int(chartWidth), height: Int(chartHeight))
    }

    // MARK: - Axis Views
    @ViewBuilder
    private func yAxisViews(chartWidth: Double, chartHeight: Double) -> some View {
        VStack(alignment: .leading) {
            let allValues = waveforms.flatMap { $0.values }
            if let minValue = allValues.min(), let maxValue = allValues.max() {
                let tickCount = 6
                let range = maxValue - minValue

                let verticalPadding = chartHeight * 0.1

                Spacer()
                    .frame(height: Int(verticalPadding) - 14)

                ForEach(Array(0..<tickCount)) { i in
                    let normalizedY = Double(i) / Double(tickCount - 1)
                    let value = maxValue - (normalizedY * range)

                    Text(String(format: "%.2f", value))
                        .font(.caption2)
                        .frame(height: 14)
                    if i != tickCount - 1 {
                        Spacer()
                    } else {
                        Spacer()
                            .frame(height: Int(verticalPadding) - 14)
                    }
                }
            }
        }
    }
    @ViewBuilder
    private var xAxisLabels: some View {
        // Calculate time range for X-axis labels
        let maxTime = waveforms.map { Double($0.values.count - 1) * $0.dt }.max() ?? 1.0
        let tickCount = 5  // Fewer labels to avoid crowding

        HStack(spacing: 0) {
            ForEach(0..<tickCount) { i in
                let normalizedX = Double(i) / Double(tickCount - 1)
                let time = normalizedX * maxTime

                if i == 0 {
                    Text(String(format: "%.1f", time))
                        .font(.caption2)
                        .frame(width: 40)
                } else if i == tickCount - 1 {
                    Spacer()
                    Text(String(format: "%.1f", time))
                        .font(.caption2)
                        .frame(width: 40)
                } else {
                    Spacer()
                    Text(String(format: "%.1f", time))
                        .font(.caption2)
                        .frame(width: 40)
                }
            }
        }
        .frame(height: 15)
    }

    // MARK: - Waveform Views
    @ViewBuilder
    private func waveformViews(chartWidth: Double, chartHeight: Double) -> some View {
        // Manually build waveform overlays to avoid ForEach stacking issues
        let count = min(waveforms.count, colors.count)

        if count > 0 {
            ZStack(alignment: .topLeading) {
                // ForEach has a bug in it for ZStack rendering these as a VStack, doing this manually with a limit of 7 waveforms
                // ForEach(0..<count) { i in
                //     waveformPath(for: waveforms[i], color: colors[i], chartWidth: chartWidth, chartHeight: chartHeight)
                // }
                if count >= 1 {
                    waveformPath(for: waveforms[0], color: colors[0], chartWidth: chartWidth, chartHeight: chartHeight)
                }
                if count >= 2 {
                    waveformPath(for: waveforms[1], color: colors[1], chartWidth: chartWidth, chartHeight: chartHeight)
                }
                if count >= 3 {
                    waveformPath(for: waveforms[2], color: colors[2], chartWidth: chartWidth, chartHeight: chartHeight)
                }
                if count >= 4 {
                    waveformPath(for: waveforms[3], color: colors[3], chartWidth: chartWidth, chartHeight: chartHeight)
                }
                if count >= 5 {
                    waveformPath(for: waveforms[4], color: colors[4], chartWidth: chartWidth, chartHeight: chartHeight)
                }
                if count >= 6 {
                    waveformPath(for: waveforms[5], color: colors[5], chartWidth: chartWidth, chartHeight: chartHeight)
                }
                if count >= 7 {
                    waveformPath(for: waveforms[6], color: colors[6], chartWidth: chartWidth, chartHeight: chartHeight)
                }
                if count >= 8 {
                    waveformPath(for: waveforms[7], color: colors[7], chartWidth: chartWidth, chartHeight: chartHeight)
                }
            }
            .frame(width: Int(chartWidth), height: Int(chartHeight))
        }
    }

    @ViewBuilder
    private func gridLines(chartWidth: Double, chartHeight: Double) -> some View {
        GridLinesShape(chartWidth: chartWidth, chartHeight: chartHeight)
            .stroke(.gray.opacity(0.3), style: StrokeStyle(width: 0.5))
            .frame(width: Int(chartWidth), height: Int(chartHeight))
    }

    @ViewBuilder
    private func axisTickMarks(chartWidth: Double, chartHeight: Double) -> some View {
        ZStack(alignment: .topLeading) {
            // Y-axis tick marks
            AxisTicksShape(
                chartWidth: chartWidth,
                chartHeight: chartHeight,
                tickCount: 6,
                isVertical: true
            )
            .stroke(.black, style: StrokeStyle(width: 1.0))

            // X-axis tick marks
            AxisTicksShape(
                chartWidth: chartWidth,
                chartHeight: chartHeight,
                tickCount: 11,
                isVertical: false
            )
            .stroke(.black, style: StrokeStyle(width: 1.0))
        }
        .frame(width: Int(chartWidth), height: Int(chartHeight))
    }

    @ViewBuilder
    private func waveformPath(
        for waveform: DoubleWaveform1D,
        color: Color,
        chartWidth: Double,
        chartHeight: Double
    ) -> some View {
        let points = getWaveformPoints(for: waveform, chartWidth: chartWidth, chartHeight: chartHeight)
        WaveformShape(points: points, chartWidth: chartWidth, chartHeight: chartHeight)
            .stroke(color, style: StrokeStyle(width: 1.5))
    }

    private func getWaveformPoints(for waveform: DoubleWaveform1D, chartWidth: Double, chartHeight: Double) -> [Point] {
        guard !waveform.values.isEmpty else { return [] }

        // Calculate stride to limit rendering points
        let strideValue = max(1, waveform.values.count / maxPointsToRender)
        let stridedIndices = Swift.stride(from: 0, to: waveform.values.count, by: strideValue)

        // Find min/max for normalization
        let allValues = waveforms.flatMap { $0.values }
        guard let minValue = allValues.min(),
            let maxValue = allValues.max(),
            maxValue != minValue
        else { return [] }

        // Calculate time range
        let maxTime = waveforms.map { Double($0.values.count - 1) * $0.dt }.max() ?? 1.0

        // Apply zoom and pan transforms
        let visibleStartTime = max(0, (-panOffset / zoomScale) * maxTime)
        let visibleEndTime = min(maxTime, visibleStartTime + (maxTime / zoomScale))

        // Add padding to prevent clipping at edges
        let verticalPadding = chartHeight * 0.1
        let availableHeight = chartHeight - (2 * verticalPadding)

        var points: [Point] = []

        for dataIndex in stridedIndices {
            let time = Double(dataIndex) * waveform.dt

            // Skip points outside visible range
            guard time >= visibleStartTime && time <= visibleEndTime else { continue }

            let normalizedTime = (time - visibleStartTime) / (visibleEndTime - visibleStartTime)
            let x = min(max(0, normalizedTime * chartWidth), chartWidth)

            // Normalize value to 0...1 range, then invert for screen coordinates (0 at top)
            let normalizedValue = (waveform.values[dataIndex] - minValue) / (maxValue - minValue)
            let y = verticalPadding + ((1.0 - normalizedValue) * availableHeight)

            // Clamp y to chart bounds
            let clampedY = min(max(0, y), chartHeight)

            points.append(Point(x: x, y: clampedY))
        }

        return points
    }

    // MARK: - Cursor Views
    @ViewBuilder
    private func cursorLine(chartWidth: Double, chartHeight: Double) -> some View {
        let x = cursorPosition * chartWidth
        CursorLineShape(x: x, chartHeight: chartHeight)
            .stroke(.orange, style: StrokeStyle(width: 2.0))
            .frame(width: Int(chartWidth), height: Int(chartHeight))
    }

    @ViewBuilder
    private var cursorValueDisplay: some View {
        let maxTime = waveforms.map { Double($0.values.count - 1) * $0.dt }.max() ?? 1.0
        let timeAtCursor = cursorPosition * maxTime
        let yValues = getYValuesAtCursor(time: timeAtCursor)

        HStack(spacing: 10) {
            Text("t=\(String(format: "%.2f", timeAtCursor))")
                .font(.caption)
                .fontWeight(.semibold)

            // Manually build value labels to avoid ForEach limitations, limiting to 8 waveforms
            let count = min(yValues.count, colors.count, labels.count)
            if count >= 1 {
                Text("\(labels[0]): \(String(format: "%.2f", yValues[0]))")
                    .font(.caption2)
                    .foregroundColor(colors[0])
            }
            if count >= 2 {
                Text("\(labels[1]): \(String(format: "%.2f", yValues[1]))")
                    .font(.caption2)
                    .foregroundColor(colors[1])
            }
            if count >= 3 {
                Text("\(labels[2]): \(String(format: "%.2f", yValues[2]))")
                    .font(.caption2)
                    .foregroundColor(colors[2])
            }
            if count >= 4 {
                Text("\(labels[3]): \(String(format: "%.2f", yValues[3]))")
                    .font(.caption2)
                    .foregroundColor(colors[3])
            }
            if count >= 5 {
                Text("\(labels[4]): \(String(format: "%.2f", yValues[4]))")
                    .font(.caption2)
                    .foregroundColor(colors[4])
            }
            if count >= 6 {
                Text("\(labels[5]): \(String(format: "%.2f", yValues[5]))")
                    .font(.caption2)
                    .foregroundColor(colors[5])
            }
            if count >= 7 {
                Text("\(labels[6]): \(String(format: "%.2f", yValues[6]))")
                    .font(.caption2)
                    .foregroundColor(colors[6])
            }
            if count >= 8 {
                Text("\(labels[7]): \(String(format: "%.2f", yValues[7]))")
                    .font(.caption2)
                    .foregroundColor(colors[7])
            }
        }
    }

    private func getYValuesAtCursor(time: Double) -> [Double] {
        waveforms.map { waveform in
            let index = Int(time / waveform.dt)
            let clampedIndex = min(max(0, index), waveform.values.count - 1)
            return waveform.values[clampedIndex]
        }
    }
}

// Shape for drawing the cursor line
private struct CursorLineShape: Shape {
    let x: Double
    let chartHeight: Double

    nonisolated func path(in bounds: Path.Rect) -> Path {
        Path()
            .move(to: SIMD2(x: x, y: 0))
            .addLine(to: SIMD2(x: x, y: chartHeight))
    }
}

// Shape for drawing the chart background
private struct BackgroundShape: Shape {
    let chartWidth: Double
    let chartHeight: Double

    nonisolated func path(in bounds: Path.Rect) -> Path {
        Path()
            .addRectangle(Path.Rect(x: 0, y: 0, width: chartWidth, height: chartHeight))
    }
}

// Shape for drawing axis tick marks
private struct AxisTicksShape: Shape {
    let chartWidth: Double
    let chartHeight: Double
    let tickCount: Int
    let isVertical: Bool
    let tickLength: Double = 5.0

    nonisolated func path(in bounds: Path.Rect) -> Path {
        var path = Path()

        if isVertical {
            // Y-axis ticks on the left edge - account for vertical padding
            let verticalPadding = chartHeight * 0.1
            let availableHeight = chartHeight - (2 * verticalPadding)

            for i in 0..<tickCount {
                // Labels go from top to bottom: maxValue (i=0) to minValue (i=tickCount-1)
                // We want: i=0 → y=verticalPadding (top), i=tickCount-1 → y=verticalPadding+availableHeight (bottom)
                // Simple linear interpolation from top to bottom
                let t = Double(i) / Double(tickCount - 1)  // 0.0 to 1.0
                let y = verticalPadding + (t * availableHeight)
                path =
                    path
                    .move(to: SIMD2(x: 0, y: y))
                    .addLine(to: SIMD2(x: tickLength, y: y))
            }
        } else {
            // X-axis ticks should align with actual time values (0 to maxTime)
            // Ticks at the data range, not evenly across the chart
            for i in 0..<tickCount {
                let x = Double(i) * chartWidth / Double(tickCount - 1)
                path =
                    path
                    .move(to: SIMD2(x: x, y: chartHeight - tickLength))
                    .addLine(to: SIMD2(x: x, y: chartHeight))
            }
        }

        return path
    }
}

// Shape for drawing all grid lines in a single path
private struct GridLinesShape: Shape {
    let chartWidth: Double
    let chartHeight: Double

    nonisolated func path(in bounds: Path.Rect) -> Path {
        var path = Path()

        // Horizontal grid lines (6 lines) - account for vertical padding
        let verticalPadding = chartHeight * 0.1
        let availableHeight = chartHeight - (2 * verticalPadding)

        for i in 0..<6 {
            let t = Double(i) / 5.0
            let y = verticalPadding + (t * availableHeight)
            path =
                path
                .move(to: SIMD2(x: 0, y: y))
                .addLine(to: SIMD2(x: chartWidth, y: y))
        }

        // Vertical grid lines (11 lines)
        for i in 0..<11 {
            let x = Double(i) * chartWidth / 10
            path =
                path
                .move(to: SIMD2(x: x, y: 0))
                .addLine(to: SIMD2(x: x, y: chartHeight))
        }

        return path
    }
}

// Helper shape for drawing a continuous waveform using SwiftCrossUI's Path
private struct WaveformShape: Shape {
    let points: [Point]
    let chartWidth: Double
    let chartHeight: Double

    nonisolated func path(in bounds: Path.Rect) -> Path {
        guard !points.isEmpty else { return Path() }

        var path = Path()

        // Start at the first point
        path = path.move(to: SIMD2(x: points[0].x, y: points[0].y))

        // Draw lines to each subsequent point
        for i in 1..<points.count {
            path = path.addLine(to: SIMD2(x: points[i].x, y: points[i].y))
        }

        return path
    }

    nonisolated func size(fitting proposal: SIMD2<Int>) -> ViewSize {
        ViewSize(
            size: SIMD2(x: Int(chartWidth), y: Int(chartHeight)),
            idealSize: SIMD2(x: Int(chartWidth), y: Int(chartHeight)),
            minimumWidth: 0,
            minimumHeight: 0,
            maximumWidth: nil,
            maximumHeight: nil
        )
    }
}
