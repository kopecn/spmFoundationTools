#if os(macOS)

import SwiftUI
import FoundationTypes

public struct BaseWaveformChart: View {
    // Waveform data
    private let waveforms: [DoubleWaveform1D]
    private let colors: [Color]
    private let labels: [String]

    // Axis labels
    private let xAxisLabel: String
    private let yAxisLabel: String

    // Chart state
    @State private var cursorPosition: CGFloat = 0.5
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGFloat = 0.0

    // Chart dimensions
    private let chartHeight: CGFloat = 300
    private let chartWidth: CGFloat = 400
    private let margin: CGFloat = 40

    // Stride factor to reduce rendering complexity
    private let maxPointsToRender: Int = 1000

    // Default colors for waveforms
    private static let defaultColors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .cyan, .yellow,
    ]

    public init(
        waveforms: [DoubleWaveform1D],
        labels: [String]? = nil,
        colors: [Color]? = nil,
        xAxisLabel: String = "Time",
        yAxisLabel: String = "Amplitude"
    ) {
        self.waveforms = waveforms
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel

        // Ensure labels array matches waveforms count
        if let providedLabels = labels {
            if providedLabels.count >= waveforms.count {
                // If we have enough or more labels, just take what we need
                self.labels = Array(providedLabels.prefix(waveforms.count))
            } else {
                // Pad with default labels if not enough provided
                let additionalLabels = (providedLabels.count..<waveforms.count).map { "Waveform \($0 + 1)" }
                self.labels = providedLabels + additionalLabels
            }
        } else {
            self.labels = Array(0..<waveforms.count).map { "Waveform \($0 + 1)" }
        }

        // Ensure colors array matches waveforms count
        if let providedColors = colors {
            if providedColors.count >= waveforms.count {
                // If we have enough or more colors, just take what we need
                self.colors = Array(providedColors.prefix(waveforms.count))
            } else {
                // Pad with default colors if not enough provided, or cycle through provided colors
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

                // Legend - add bounds checking as extra safety
                HStack(spacing: 15) {
                    ForEach(Array(waveforms.enumerated()), id: \.offset) { index, _ in
                        if index < colors.count && index < labels.count {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(colors[index])
                                    .frame(width: 8, height: 8)
                                Text(labels[index])
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, margin)

            // Chart container
            ZStack {
                // Background
                Rectangle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .border(Color.gray, width: 1)

                // Chart content
                chartContent

                // Vertical cursor
                verticalCursor
            }
            .frame(width: chartWidth, height: chartHeight)
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Update cursor position
                        cursorPosition = max(0, min(1, value.location.x / chartWidth))
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = max(0.5, min(5.0, value))
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if abs(value.translation.height) < abs(value.translation.width) {
                            panOffset += value.translation.width * 0.01
                        }
                    }
            )

            // Axis labels
            HStack {
                Text(yAxisLabel)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 20)

                Spacer()

                VStack {
                    Spacer()
                    Text(xAxisLabel)
                        .frame(height: 20)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }

    private var chartContent: some View {
        ZStack {
            // Grid lines
            gridLines

            // Waveforms - add bounds checking
            ForEach(Array(waveforms.enumerated()), id: \.offset) { index, waveform in
                if index < colors.count {
                    waveformPath(for: waveform)
                        .stroke(colors[index], lineWidth: 1.5)
                }
            }
        }
    }

    private var gridLines: some View {
        ZStack {
            // Horizontal grid lines
            ForEach(0..<6) { i in
                Path { path in
                    let y = CGFloat(i) * chartHeight / 5
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: chartWidth, y: y))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            }

            // Vertical grid lines
            ForEach(0..<11) { i in
                Path { path in
                    let x = CGFloat(i) * chartWidth / 10
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: chartHeight))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            }
        }
    }

    private var verticalCursor: some View {
        Path { path in
            let x = cursorPosition * chartWidth
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: chartHeight))
        }
        .stroke(Color.red, lineWidth: 2)
        .opacity(0.8)
    }

    private func waveformPath(for waveform: DoubleWaveform1D) -> Path {
        Path { path in
            guard !waveform.values.isEmpty else { return }

            // Calculate stride to limit rendering points
            let strideValue = max(1, waveform.values.count / maxPointsToRender)
            let stridedIndices = Swift.stride(from: 0, to: waveform.values.count, by: strideValue)

            // Find min/max for normalization
            let allValues = waveforms.flatMap { $0.values }
            guard let minValue = allValues.min(),
                let maxValue = allValues.max(),
                maxValue != minValue
            else { return }

            // Calculate time range
            let maxTime = waveforms.map { Double($0.values.count - 1) * $0.dt }.max() ?? 1.0

            // Apply zoom and pan transforms
            let visibleStartTime = max(0, (-panOffset / zoomScale) * maxTime)
            let visibleEndTime = min(maxTime, visibleStartTime + (maxTime / zoomScale))

            var isFirstPoint = true
            for dataIndex in stridedIndices {
                let time = Double(dataIndex) * waveform.dt

                // Skip points outside visible range
                guard time >= visibleStartTime && time <= visibleEndTime else { continue }

                let normalizedTime = (time - visibleStartTime) / (visibleEndTime - visibleStartTime)
                let x = normalizedTime * chartWidth

                let normalizedValue = (waveform.values[dataIndex] - minValue) / (maxValue - minValue)
                let y = chartHeight - (normalizedValue * chartHeight)

                let point = CGPoint(x: x, y: y)

                if isFirstPoint {
                    path.move(to: point)
                    isFirstPoint = false
                } else {
                    path.addLine(to: point)
                }
            }
        }
    }
}

// Preview for testing
#Preview {
    // Sample waveform data using Waveform1D
    let sampleWaveform1 = DoubleWaveform1D(
        values: (0..<1000).map { sin(Double($0) * 0.1) },
        dt: 0.001
    )

    let sampleWaveform2 = DoubleWaveform1D(
        values: (0..<800).map { cos(Double($0) * 0.15) * 0.7 },
        dt: 0.0012
    )

    return BaseWaveformChart(
        waveforms: [sampleWaveform1, sampleWaveform2],
        labels: ["Sine Wave", "Cosine Wave"],
        colors: [.blue, .red],
        xAxisLabel: "Time (s)",
        yAxisLabel: "Voltage (V)"
    )
}

#endif
