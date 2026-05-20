import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var folderURL: URL? = nil
    @State private var leftText = "1015"
    @State private var topText = "300"
    @State private var widthText = "1305"
    @State private var heightText = "1670"

    @State private var isRunning = false
    @State private var progress: Double = 0
    @State private var statusLines: [String] = []
    @State private var outputURL: URL? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Crop & PDF")
                .font(.title2).bold()

            GroupBox("Folder") {
                HStack {
                    Text(folderURL?.path ?? "No folder selected")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(folderURL == nil ? .secondary : .primary)
                    Spacer()
                    Button("Choose…") { chooseFolder() }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Crop") {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("Left (X)")
                        TextField("1015", text: $leftText)
                        Text("Top (Y)")
                        TextField("300", text: $topText)
                    }
                    GridRow {
                        Text("Width")
                        TextField("1305", text: $widthText)
                        Text("Height")
                        TextField("1670", text: $heightText)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 4)
            }

            HStack {
                Button {
                    Task { await runProcess() }
                } label: {
                    Label("Generate PDF", systemImage: "doc.fill.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(folderURL == nil || isRunning || !inputsValid)

                if isRunning {
                    ProgressView(value: progress)
                        .frame(maxWidth: .infinity)
                }

                if let outputURL {
                    Button("Reveal PDF") {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            GroupBox("Log") {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(statusLines.enumerated()), id: \.offset) { idx, line in
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .id(idx)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                    }
                    .frame(minHeight: 140)
                    .onChange(of: statusLines.count) { _, newValue in
                        if newValue > 0 {
                            proxy.scrollTo(newValue - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(20)
    }

    private var inputsValid: Bool {
        [leftText, topText, widthText, heightText].allSatisfy { Int($0) != nil }
        && (Int(widthText) ?? 0) > 0
        && (Int(heightText) ?? 0) > 0
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        if panel.runModal() == .OK {
            folderURL = panel.url
            outputURL = nil
            errorMessage = nil
            statusLines.removeAll()
        }
    }

    @MainActor
    private func runProcess() async {
        guard let folderURL else { return }
        guard let left = Int(leftText),
              let top = Int(topText),
              let w = Int(widthText),
              let h = Int(heightText) else { return }

        isRunning = true
        progress = 0
        statusLines.removeAll()
        outputURL = nil
        errorMessage = nil

        let cropRect = CropProcessor.CropRect(x: left, y: top, width: w, height: h)
        let processor = CropProcessor()

        do {
            let pdf = try await processor.process(
                folder: folderURL,
                cropRect: cropRect,
                onProgress: { line, p in
                    Task { @MainActor in
                        statusLines.append(line)
                        progress = p
                    }
                }
            )
            outputURL = pdf
            statusLines.append("Done: \(pdf.lastPathComponent)")
        } catch {
            errorMessage = error.localizedDescription
            statusLines.append("Error: \(error.localizedDescription)")
        }

        isRunning = false
    }
}

#Preview {
    ContentView()
}
