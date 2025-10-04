import SwiftCrossUI
import FoundationUITools
import FoundationTypes
import Foundation

struct FoundationUIDemoRootViewL: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("SwiftCrossUI Demo")
                .font(.title)

            HStack(spacing: 10) {
                Button("-") { count -= 1 }
                Text("Count: \(count)")
                Button("+") { count += 1 }
            }

            // Example waveform chart
            XUIBaseWaveformChart(
                waveforms: createSampleWaveforms(),
                labels: ["Sine", "Cosine"],
                colors: [.blue, .red]
            )
        }
        .padding()
    }

    private func createSampleWaveforms() -> [DoubleWaveform1D] {
        let sampleCount = 100
        let dt = 0.1

        // Sine wave
        let sineValues = (0..<sampleCount).map { i in
            Darwin.sin(Double(i) * dt)
        }
        let sineWaveform = DoubleWaveform1D(values: sineValues, dt: dt)

        // Cosine wave
        let cosineValues = (0..<sampleCount).map { i in
            Darwin.cos(Double(i) * dt)
        }
        let cosineWaveform = DoubleWaveform1D(values: cosineValues, dt: dt)

        return [sineWaveform, cosineWaveform]
    }
}
