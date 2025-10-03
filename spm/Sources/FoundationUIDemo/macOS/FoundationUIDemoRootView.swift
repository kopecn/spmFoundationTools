#if os(macOS)

import SwiftUI
import FoundationTypes
import FoundationTools
import UniformTypeIdentifiers

struct FoundationUIDemoRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Welcome Tab
            WelcomeView()
                .tabItem {
                    Label("Welcome", systemImage: "house")
                }
                .tag(0)

            // Waveform Chart Tab
            WaveformChartDemoView()
                .tabItem {
                    Label("Waveform Chart", systemImage: "waveform")
                }
                .tag(1)

            // Data Types Tab
            DataTypesDemoView()
                .tabItem {
                    Label("Data Types", systemImage: "doc.text")
                }
                .tag(2)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Foundation Tools Demo")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Welcome to the Foundation Tools package demo!")
                .font(.title2)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("This demo showcases:")
                    .font(.headline)

                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.blue)
                    Text("Interactive waveform charting with zoom and pan")
                }

                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.green)
                    Text("Waveform1D data types with JSON serialization")
                }

                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.orange)
                    Text("Foundation utilities and common tools")
                }
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Waveform Chart Demo View
struct WaveformChartDemoView: View {
    @State private var waveforms: [DoubleWaveform1D] = []
    @State private var selectedWaveformType = 0

    let waveformTypes = ["Sine & Cosine", "Noise", "Square Wave", "Sawtooth", "Mixed Signals"]

    var body: some View {
        VStack(spacing: 20) {
            // Controls
            HStack {
                Text("Waveform Type:")
                    .font(.headline)

                Picker("Waveform Type", selection: $selectedWaveformType) {
                    ForEach(0..<waveformTypes.count, id: \.self) { index in
                        Text(waveformTypes[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedWaveformType) { _, _ in
                    generateWaveforms()
                }

                Spacer()

                Button("Regenerate") {
                    generateWaveforms()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            // Chart
            if !waveforms.isEmpty {
                BaseWaveformChart(
                    waveforms: waveforms,
                    labels: getLabelsForCurrentType(),
                    colors: getColorsForCurrentType(),
                    xAxisLabel: "Time (s)",
                    yAxisLabel: "Amplitude (V)"
                )
                .padding()
            } else {
                Text("No waveforms to display")
                    .foregroundColor(.secondary)
                    .frame(height: 300)
            }

            // Info panel
            WaveformInfoPanel(waveforms: waveforms)

            Spacer()
        }
        .onAppear {
            generateWaveforms()
        }
    }

    private func generateWaveforms() {
        switch selectedWaveformType {
        case 0:  // Sine & Cosine
            waveforms = generateSineAndCosine()
        case 1:  // Noise
            waveforms = generateNoise()
        case 2:  // Square Wave
            waveforms = generateSquareWave()
        case 3:  // Sawtooth
            waveforms = generateSawtooth()
        case 4:  // Mixed Signals
            waveforms = generateMixedSignals()
        default:
            waveforms = generateSineAndCosine()
        }
    }

    private func getLabelsForCurrentType() -> [String] {
        switch selectedWaveformType {
        case 0: return ["Sine Wave", "Cosine Wave"]
        case 1: return ["White Noise", "Filtered Noise"]
        case 2: return ["Square Wave (1Hz)", "Square Wave (2Hz)"]
        case 3: return ["Sawtooth (1Hz)", "Inverted Sawtooth"]
        case 4: return ["Signal A", "Signal B", "Signal C"]
        default: return ["Waveform 1", "Waveform 2"]
        }
    }

    private func getColorsForCurrentType() -> [Color] {
        switch selectedWaveformType {
        case 0: return [.blue, .red]
        case 1: return [.purple, .orange]
        case 2: return [.green, .cyan]
        case 3: return [.pink, .yellow]
        case 4: return [.blue, .red, .green]
        default: return [.blue, .red]
        }
    }

    // MARK: - Waveform Generators

    private func generateSineAndCosine() -> [DoubleWaveform1D] {
        let sampleRate = 1000.0  // Hz
        let dt = 1.0 / sampleRate
        let duration = 2.0  // seconds
        let samples = Int(duration * sampleRate)

        let frequency = 5.0  // Hz

        let sineValues = (0..<samples).map { i in
            sin(2.0 * .pi * frequency * Double(i) * dt)
        }

        let cosineValues = (0..<samples).map { i in
            cos(2.0 * .pi * frequency * Double(i) * dt) * 0.7
        }

        return [
            DoubleWaveform1D(values: sineValues, dt: dt),
            DoubleWaveform1D(values: cosineValues, dt: dt),
        ]
    }

    private func generateNoise() -> [DoubleWaveform1D] {
        let sampleRate = 1000.0
        let dt = 1.0 / sampleRate
        let samples = 2000

        let whiteNoise = (0..<samples).map { _ in
            Double.random(in: -1.0...1.0)
        }

        // Simple low-pass filter for filtered noise
        var filteredNoise = whiteNoise
        let alpha = 0.1
        for i in 1..<filteredNoise.count {
            filteredNoise[i] = alpha * whiteNoise[i] + (1 - alpha) * filteredNoise[i - 1]
        }

        return [
            DoubleWaveform1D(values: whiteNoise, dt: dt),
            DoubleWaveform1D(values: filteredNoise, dt: dt),
        ]
    }

    private func generateSquareWave() -> [DoubleWaveform1D] {
        let sampleRate = 1000.0
        let dt = 1.0 / sampleRate
        let samples = 2000

        let freq1 = 1.0
        let freq2 = 2.0

        let square1 = (0..<samples).map { i in
            sin(2.0 * .pi * freq1 * Double(i) * dt) > 0 ? 1.0 : -1.0
        }

        let square2 = (0..<samples).map { i in
            sin(2.0 * .pi * freq2 * Double(i) * dt) > 0 ? 0.8 : -0.8
        }

        return [
            DoubleWaveform1D(values: square1, dt: dt),
            DoubleWaveform1D(values: square2, dt: dt),
        ]
    }

    private func generateSawtooth() -> [DoubleWaveform1D] {
        let sampleRate = 1000.0
        let dt = 1.0 / sampleRate
        let samples = 2000
        let frequency = 1.0

        let sawtooth = (0..<samples).map { i in
            let phase = (frequency * Double(i) * dt).truncatingRemainder(dividingBy: 1.0)
            return 2.0 * phase - 1.0
        }

        let invertedSawtooth = sawtooth.map { -$0 * 0.7 }

        return [
            DoubleWaveform1D(values: sawtooth, dt: dt),
            DoubleWaveform1D(values: invertedSawtooth, dt: dt),
        ]
    }

    private func generateMixedSignals() -> [DoubleWaveform1D] {
        let sampleRate = 1000.0
        let dt = 1.0 / sampleRate
        let samples = 2000

        // Complex signal: sine + harmonics + noise
        let signalA = (0..<samples).map { i in
            let t = Double(i) * dt
            return sin(2.0 * .pi * 3.0 * t) + 0.3 * sin(2.0 * .pi * 9.0 * t) + 0.1 * Double.random(in: -1...1)
        }

        // Amplitude modulated signal
        let signalB = (0..<samples).map { i in
            let t = Double(i) * dt
            let carrier = sin(2.0 * .pi * 10.0 * t)
            let modulator = 0.5 * (1 + sin(2.0 * .pi * 1.0 * t))
            return carrier * modulator
        }

        // Chirp signal (frequency sweep)
        let signalC = (0..<samples).map { i in
            let t = Double(i) * dt
            let f0 = 1.0
            let f1 = 10.0
            let duration = Double(samples) * dt
            let instantFreq = f0 + (f1 - f0) * t / duration
            return 0.8 * sin(2.0 * .pi * instantFreq * t * t / (2.0 * duration))
        }

        return [
            DoubleWaveform1D(values: signalA, dt: dt),
            DoubleWaveform1D(values: signalB, dt: dt),
            DoubleWaveform1D(values: signalC, dt: dt),
        ]
    }
}

// MARK: - Waveform Info Panel
struct WaveformInfoPanel: View {
    let waveforms: [DoubleWaveform1D]

    var body: some View {
        if !waveforms.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Waveform Statistics")
                    .font(.headline)

                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(Array(waveforms.enumerated()), id: \.offset) { index, waveform in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Waveform \(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Samples: \(waveform.sampleCount)")
                                Text("Duration: \(String(format: "%.3f", waveform.duration))s")
                                Text("Sample Rate: \(String(format: "%.0f", waveform.samplingFrequency))Hz")
                                Text("Mean: \(String(format: "%.3f", waveform.mean))")
                                Text("RMS: \(String(format: "%.3f", waveform.rms))")
                                if let min = waveform.minimum, let max = waveform.maximum {
                                    Text("Range: \(String(format: "%.3f", min)) to \(String(format: "%.3f", max))")
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
}

// MARK: - Data Types Demo View
struct DataTypesDemoView: View {
    @State private var sampleWaveform: DoubleWaveform1D?
    @State private var jsonString: String = ""
    @State private var showingSaveDialog = false
    @State private var showingLoadDialog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Waveform1D Data Types")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Demonstrates Waveform1D creation, serialization, and file operations")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Create sample waveform
            VStack(alignment: .leading, spacing: 10) {
                Text("1. Create Sample Waveform")
                    .font(.headline)

                Button("Generate Sample Waveform") {
                    generateSampleWaveform()
                }
                .buttonStyle(.bordered)

                if let waveform = sampleWaveform {
                    Text("Created waveform with \(waveform.sampleCount) samples")
                        .foregroundColor(.green)
                }
            }

            // JSON serialization
            VStack(alignment: .leading, spacing: 10) {
                Text("2. JSON Serialization")
                    .font(.headline)

                HStack {
                    Button("Convert to JSON") {
                        convertToJSON()
                    }
                    .disabled(sampleWaveform == nil)
                    .buttonStyle(.bordered)

                    Button("Parse from JSON") {
                        parseFromJSON()
                    }
                    .disabled(jsonString.isEmpty)
                    .buttonStyle(.bordered)
                }

                if !jsonString.isEmpty {
                    ScrollView {
                        Text(jsonString)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(height: 200)
                }
            }

            // File operations
            VStack(alignment: .leading, spacing: 10) {
                Text("3. File Operations")
                    .font(.headline)

                HStack {
                    Button("Save to File") {
                        showingSaveDialog = true
                    }
                    .disabled(sampleWaveform == nil)
                    .buttonStyle(.bordered)

                    Button("Load from File") {
                        showingLoadDialog = true
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding(40)
        .fileExporter(
            isPresented: $showingSaveDialog,
            document: WaveformDocument(waveform: sampleWaveform),
            contentType: .json,
            defaultFilename: "waveform"
        ) { result in
            // Handle save result
        }
        .fileImporter(
            isPresented: $showingLoadDialog,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                loadWaveformFromFile(url: url)
            case .failure(let error):
                print("File import failed: \(error)")
            }
        }
    }

    private func generateSampleWaveform() {
        let samples = (0..<500).map { i in
            sin(Double(i) * 0.1) + 0.3 * sin(Double(i) * 0.3)
        }
        sampleWaveform = DoubleWaveform1D(values: samples, dt: 0.001, t0: Date())
    }

    private func convertToJSON() {
        guard let waveform = sampleWaveform else { return }

        do {
            jsonString = try waveform.toJSONString()
        } catch {
            jsonString = "Error: \(error.localizedDescription)"
        }
    }

    private func parseFromJSON() {
        guard !jsonString.isEmpty,
            let data = jsonString.data(using: .utf8)
        else { return }

        do {
            sampleWaveform = try DoubleWaveform1D.from(jsonData: data)
        } catch {
            print("JSON parsing failed: \(error)")
        }
    }

    private func loadWaveformFromFile(url: URL) {
        do {
            let _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            sampleWaveform = try DoubleWaveform1D.load(from: url)
            convertToJSON()  // Update JSON display
        } catch {
            print("File loading failed: \(error)")
        }
    }
}

// MARK: - Document for file export
struct WaveformDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let waveform: DoubleWaveform1D?

    init(waveform: DoubleWaveform1D?) {
        self.waveform = waveform
    }

    init(configuration: ReadConfiguration) throws {
        // Not implemented for this demo
        self.waveform = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let waveform = waveform else {
            throw CocoaError(.fileWriteUnknown)
        }

        let data = try waveform.toJSONData()
        return FileWrapper(regularFileWithContents: data)
    }
}

#endif
