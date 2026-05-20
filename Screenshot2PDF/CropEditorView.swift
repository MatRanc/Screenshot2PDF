import SwiftUI
import AppKit
import ImageIO

struct CropEditorView: View {
    let imageURL: URL
    @Binding var rect: CropProcessor.CropRect

    @State private var image: NSImage?
    @State private var pixelSize: CGSize = .zero
    @State private var loadError: String?
    @State private var dragStartRect: CropProcessor.CropRect?

    var body: some View {
        Group {
            if let image, pixelSize.width > 0 {
                editor(image: image)
            } else if let loadError {
                Text(loadError).foregroundStyle(.red).padding()
            } else {
                ProgressView().padding()
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: imageURL) { _, _ in loadImage() }
    }

    @ViewBuilder
    private func editor(image: NSImage) -> some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / pixelSize.width,
                proxy.size.height / pixelSize.height
            )
            let renderW = pixelSize.width * scale
            let renderH = pixelSize.height * scale
            let originX = (proxy.size.width - renderW) / 2
            let originY = (proxy.size.height - renderH) / 2
            let displayRect = CGRect(
                x: originX + CGFloat(rect.x) * scale,
                y: originY + CGFloat(rect.y) * scale,
                width: CGFloat(rect.width) * scale,
                height: CGFloat(rect.height) * scale
            )

            ZStack(alignment: .topLeading) {
                Color(NSColor.windowBackgroundColor)

                Image(nsImage: image)
                    .resizable()
                    .interpolation(.medium)
                    .frame(width: renderW, height: renderH)
                    .offset(x: originX, y: originY)

                OutsideMask(rect: displayRect)
                    .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true))
                    .allowsHitTesting(false)

                Rectangle()
                    .stroke(Color.yellow, lineWidth: 1.5)
                    .frame(width: max(displayRect.width, 0), height: max(displayRect.height, 0))
                    .offset(x: displayRect.minX, y: displayRect.minY)
                    .contentShape(Rectangle())
                    .gesture(moveGesture(scale: scale))

                ForEach(Corner.allCases, id: \.self) { corner in
                    let p = corner.point(in: displayRect)
                    Circle()
                        .fill(Color.yellow)
                        .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1))
                        .frame(width: 14, height: 14)
                        .offset(x: p.x - 7, y: p.y - 7)
                        .gesture(resizeGesture(corner: corner, scale: scale))
                }
            }
        }
        .frame(minHeight: 300)
    }

    private func loadImage() {
        image = nil
        pixelSize = .zero
        loadError = nil
        guard let src = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            loadError = "Cannot read \(imageURL.lastPathComponent)"
            return
        }
        pixelSize = CGSize(width: cg.width, height: cg.height)
        image = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    private func moveGesture(scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if dragStartRect == nil { dragStartRect = rect }
                let start = dragStartRect!
                let dx = Int((value.translation.width / scale).rounded())
                let dy = Int((value.translation.height / scale).rounded())
                let maxX = Int(pixelSize.width) - start.width
                let maxY = Int(pixelSize.height) - start.height
                var r = start
                r.x = max(0, min(max(0, maxX), start.x + dx))
                r.y = max(0, min(max(0, maxY), start.y + dy))
                rect = r
            }
            .onEnded { _ in dragStartRect = nil }
    }

    private func resizeGesture(corner: Corner, scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStartRect == nil { dragStartRect = rect }
                let start = dragStartRect!
                let dx = Int((value.translation.width / scale).rounded())
                let dy = Int((value.translation.height / scale).rounded())

                var x = start.x, y = start.y, w = start.width, h = start.height

                switch corner {
                case .topLeft:
                    x = start.x + dx; y = start.y + dy
                    w = start.width - dx; h = start.height - dy
                case .topRight:
                    y = start.y + dy
                    w = start.width + dx; h = start.height - dy
                case .bottomLeft:
                    x = start.x + dx
                    w = start.width - dx; h = start.height + dy
                case .bottomRight:
                    w = start.width + dx; h = start.height + dy
                }

                let minSize = 10
                if w < minSize {
                    if corner == .topLeft || corner == .bottomLeft {
                        x = start.x + start.width - minSize
                    }
                    w = minSize
                }
                if h < minSize {
                    if corner == .topLeft || corner == .topRight {
                        y = start.y + start.height - minSize
                    }
                    h = minSize
                }
                x = max(0, x)
                y = max(0, y)
                if x + w > Int(pixelSize.width) { w = max(minSize, Int(pixelSize.width) - x) }
                if y + h > Int(pixelSize.height) { h = max(minSize, Int(pixelSize.height) - y) }
                rect = .init(x: x, y: y, width: w, height: h)
            }
            .onEnded { _ in dragStartRect = nil }
    }

    enum Corner: CaseIterable, Hashable {
        case topLeft, topRight, bottomLeft, bottomRight
        func point(in r: CGRect) -> CGPoint {
            switch self {
            case .topLeft: return CGPoint(x: r.minX, y: r.minY)
            case .topRight: return CGPoint(x: r.maxX, y: r.minY)
            case .bottomLeft: return CGPoint(x: r.minX, y: r.maxY)
            case .bottomRight: return CGPoint(x: r.maxX, y: r.maxY)
            }
        }
    }
}

private struct OutsideMask: Shape {
    let rect: CGRect
    func path(in bounds: CGRect) -> Path {
        var p = Path()
        p.addRect(bounds)
        p.addRect(rect)
        return p
    }
}

struct CropFields: View {
    @Binding var rect: CropProcessor.CropRect
    var body: some View {
        HStack(spacing: 6) {
            Text("X").foregroundStyle(.secondary)
            TextField("", value: $rect.x, format: .number).frame(width: 70)
            Text("Y").foregroundStyle(.secondary)
            TextField("", value: $rect.y, format: .number).frame(width: 70)
            Text("W").foregroundStyle(.secondary)
            TextField("", value: $rect.width, format: .number).frame(width: 70)
            Text("H").foregroundStyle(.secondary)
            TextField("", value: $rect.height, format: .number).frame(width: 70)
        }
        .textFieldStyle(.roundedBorder)
    }
}

struct SampleEditorSheet: View {
    let imageURL: URL
    @Binding var defaultCrop: CropProcessor.CropRect
    @Environment(\.dismiss) private var dismiss
    @State private var working: CropProcessor.CropRect

    init(imageURL: URL, defaultCrop: Binding<CropProcessor.CropRect>) {
        self.imageURL = imageURL
        _defaultCrop = defaultCrop
        _working = State(initialValue: defaultCrop.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Sample: \(imageURL.lastPathComponent)")
                    .font(.headline)
                    .lineLimit(1).truncationMode(.middle)
                Spacer()
            }
            .padding(.horizontal).padding(.top, 12)

            CropEditorView(imageURL: imageURL, rect: $working)
                .padding()

            Divider()

            HStack {
                CropFields(rect: $working)
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Apply to All") {
                    defaultCrop = working
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 760, minHeight: 560)
    }
}

struct PreviewSheet: View {
    let imageURLs: [URL]
    @Binding var defaultCrop: CropProcessor.CropRect
    @Binding var overrides: [String: CropProcessor.CropRect]

    @Environment(\.dismiss) private var dismiss
    @State private var index: Int = 0
    @State private var workingRect: CropProcessor.CropRect = .init(x: 0, y: 0, width: 0, height: 0)
    @State private var suppressSync = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { move(by: -1) } label: { Image(systemName: "chevron.left") }
                    .disabled(index == 0)
                    .keyboardShortcut(.leftArrow, modifiers: [.command])

                Spacer()

                VStack(spacing: 2) {
                    if !imageURLs.isEmpty {
                        Text("\(index + 1) / \(imageURLs.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(imageURLs[index].lastPathComponent)
                            .font(.headline)
                            .lineLimit(1).truncationMode(.middle)
                    }
                }

                Spacer()

                Button { move(by: 1) } label: { Image(systemName: "chevron.right") }
                    .disabled(index >= imageURLs.count - 1)
                    .keyboardShortcut(.rightArrow, modifiers: [.command])
            }
            .padding()

            if !imageURLs.isEmpty {
                CropEditorView(imageURL: imageURLs[index], rect: $workingRect)
                    .padding(.horizontal)
            }

            Divider().padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    CropFields(rect: $workingRect)
                    if isOverridden {
                        Text("override")
                            .font(.caption)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }

                HStack {
                    Button("Apply as default for all") {
                        defaultCrop = workingRect
                        overrides.removeAll()
                    }

                    Button("Reset overrides") {
                        overrides.removeAll()
                        suppressSync = true
                        workingRect = defaultCrop
                    }
                    .disabled(overrides.isEmpty)

                    Spacer()

                    Button("Done") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .frame(minWidth: 820, minHeight: 640)
        .onAppear { loadCurrent() }
        .onChange(of: workingRect) { _, newValue in
            if suppressSync { suppressSync = false; return }
            guard !imageURLs.isEmpty else { return }
            let name = imageURLs[index].lastPathComponent
            if newValue == defaultCrop {
                overrides.removeValue(forKey: name)
            } else {
                overrides[name] = newValue
            }
        }
    }

    private var isOverridden: Bool {
        guard !imageURLs.isEmpty else { return false }
        return overrides[imageURLs[index].lastPathComponent] != nil
    }

    private func move(by delta: Int) {
        let newIndex = max(0, min(imageURLs.count - 1, index + delta))
        if newIndex == index { return }
        index = newIndex
        loadCurrent()
    }

    private func loadCurrent() {
        guard !imageURLs.isEmpty else { return }
        let name = imageURLs[index].lastPathComponent
        let target = overrides[name] ?? defaultCrop
        suppressSync = true
        workingRect = target
    }
}
