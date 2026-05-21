import SwiftUI
import UniformTypeIdentifiers

private struct PresentedSample: Identifiable {
    let id = UUID()
    let url: URL
}

enum ImageSortOrder: String, CaseIterable, Identifiable {
    case creationDate
    case name
    var id: String { rawValue }
    var label: String {
        switch self {
        case .creationDate: return "Creation Date"
        case .name: return "Name"
        }
    }
}

struct ContentView: View {
    @State private var folderURL: URL? = nil
    @State private var folderImageURLs: [URL] = []
    @State private var sortOrder: ImageSortOrder = .creationDate
    @State private var defaultCrop = CropProcessor.CropRect(x: 1015, y: 300, width: 1305, height: 1670)
    @State private var cropOverrides: [String: CropProcessor.CropRect] = [:]

    @State private var isRunning = false
    @State private var progress: Double = 0
    @State private var statusLines: [String] = []
    @State private var outputURL: URL? = nil
    @State private var errorMessage: String? = nil

    @State private var presentedSample: PresentedSample? = nil
    @State private var showingPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Screenshot2PDF")
                .font(.title2).bold()

            GroupBox("Folder") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(folderURL?.path ?? "No folder selected")
                            .lineLimit(1).truncationMode(.middle)
                            .foregroundStyle(folderURL == nil ? .secondary : .primary)
                        Spacer()
                        Button("Choose…") { chooseFolder() }
                    }

                    if !folderImageURLs.isEmpty {
                        HStack {
                            Text("\(folderImageURLs.count) image\(folderImageURLs.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("Sort by", selection: $sortOrder) {
                                ForEach(ImageSortOrder.allCases) { order in
                                    Text(order.label).tag(order)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 260)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Crop") {
                VStack(alignment: .leading, spacing: 10) {
                    CropFields(rect: $defaultCrop)

                    HStack(spacing: 12) {
                        Button { pickSample() } label: {
                            Label("Set from Sample…", systemImage: "rectangle.dashed")
                        }

                        Button { showingPreview = true } label: {
                            Label("Preview & Adjust…", systemImage: "rectangle.stack")
                        }
                        .disabled(folderImageURLs.isEmpty)

                        if !cropOverrides.isEmpty {
                            Text("\(cropOverrides.count) per-image override\(cropOverrides.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
                    ProgressView(value: progress).frame(maxWidth: .infinity)
                }

                if let outputURL {
                    Button("Reveal PDF") {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.callout)
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
        .sheet(item: $presentedSample) { sample in
            SampleEditorSheet(imageURL: sample.url, defaultCrop: $defaultCrop)
        }
        .sheet(isPresented: $showingPreview) {
            PreviewSheet(
                imageURLs: $folderImageURLs,
                defaultCrop: $defaultCrop,
                overrides: $cropOverrides
            )
        }
        .onChange(of: sortOrder) { _, _ in
            sortFolderImages()
        }
    }

    private var inputsValid: Bool {
        defaultCrop.width > 0 && defaultCrop.height > 0
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
            cropOverrides.removeAll()
            loadFolderImages()
        }
    }

    private func loadFolderImages() {
        guard let folderURL else { folderImageURLs = []; return }
        let fm = FileManager.default
        let supported: Set<String> = ["png", "jpg", "jpeg"]
        let resourceKeys: [URLResourceKey] = [.creationDateKey]
        let items = (try? fm.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )) ?? []
        folderImageURLs = items.filter { supported.contains($0.pathExtension.lowercased()) }
        sortFolderImages()
    }

    private func sortFolderImages() {
        switch sortOrder {
        case .creationDate:
            folderImageURLs.sort { a, b in
                let av = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantFuture
                let bv = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantFuture
                if av == bv { return a.lastPathComponent < b.lastPathComponent }
                return av < bv
            }
        case .name:
            folderImageURLs.sort { a, b in
                a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
            }
        }
    }

    private func pickSample() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg]
        panel.prompt = "Choose Sample"
        if panel.runModal() == .OK, let url = panel.url {
            presentedSample = PresentedSample(url: url)
        }
    }

    @MainActor
    private func runProcess() async {
        guard let folderURL else { return }
        isRunning = true
        progress = 0
        statusLines.removeAll()
        outputURL = nil
        errorMessage = nil

        let processor = CropProcessor()
        do {
            let pdf = try await processor.process(
                folder: folderURL,
                imageURLs: folderImageURLs,
                defaultCropRect: defaultCrop,
                cropOverrides: cropOverrides,
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
