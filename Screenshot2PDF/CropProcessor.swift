import Foundation
import CoreGraphics
import ImageIO
import PDFKit
import AppKit

struct CropProcessor {
    struct CropRect {
        var x: Int
        var y: Int
        var width: Int
        var height: Int
    }

    enum ProcessorError: LocalizedError {
        case noImages
        case cannotReadImage(String)
        case cropOutOfBounds(name: String, imageSize: CGSize)
        case pdfWriteFailed(URL)

        var errorDescription: String? {
            switch self {
            case .noImages: return "No PNG or JPEG images found in the selected folder."
            case .cannotReadImage(let name): return "Could not read image: \(name)"
            case .cropOutOfBounds(let name, let size):
                return "Crop is outside image bounds for \(name) (\(Int(size.width))×\(Int(size.height)))."
            case .pdfWriteFailed(let url): return "Failed to write PDF to \(url.path)."
            }
        }
    }

    private static let supportedExtensions: Set<String> = ["png", "jpg", "jpeg"]

    func process(
        folder: URL,
        cropRect: CropRect,
        onProgress: @escaping (String, Double) -> Void
    ) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            try Self.run(folder: folder, cropRect: cropRect, onProgress: onProgress)
        }.value
    }

    private static func run(
        folder: URL,
        cropRect: CropRect,
        onProgress: @escaping (String, Double) -> Void
    ) throws -> URL {
        let fm = FileManager.default
        let resourceKeys: [URLResourceKey] = [.creationDateKey, .isRegularFileKey]
        let items = try fm.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )

        let images = items
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            .map { url -> (URL, Date) in
                let values = try? url.resourceValues(forKeys: Set(resourceKeys))
                let created = values?.creationDate ?? .distantFuture
                return (url, created)
            }
            .sorted { a, b in
                if a.1 == b.1 { return a.0.lastPathComponent < b.0.lastPathComponent }
                return a.1 < b.1
            }

        guard !images.isEmpty else { throw ProcessorError.noImages }

        let pdf = PDFDocument()
        let total = images.count

        for (idx, entry) in images.enumerated() {
            let (url, _) = entry
            let name = url.lastPathComponent

            guard
                let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                let cg = CGImageSourceCreateImageAtIndex(src, 0, nil)
            else {
                throw ProcessorError.cannotReadImage(name)
            }

            let imgW = cg.width
            let imgH = cg.height

            if cropRect.x < 0 || cropRect.y < 0 ||
                cropRect.x + cropRect.width > imgW ||
                cropRect.y + cropRect.height > imgH {
                throw ProcessorError.cropOutOfBounds(
                    name: name,
                    imageSize: CGSize(width: imgW, height: imgH)
                )
            }

            // CGImage origin is top-left for cropping with CGImageSourceCreateThumbnail,
            // but cropping(to:) uses image coordinate system (origin at top-left for
            // bitmap images coming from PNG/JPEG decode). We use the requested top-left.
            let rect = CGRect(
                x: cropRect.x,
                y: cropRect.y,
                width: cropRect.width,
                height: cropRect.height
            )

            guard let cropped = cg.cropping(to: rect) else {
                throw ProcessorError.cannotReadImage(name)
            }

            let nsImage = NSImage(
                cgImage: cropped,
                size: NSSize(width: cropRect.width, height: cropRect.height)
            )

            guard let page = PDFPage(image: nsImage) else {
                throw ProcessorError.cannotReadImage(name)
            }

            pdf.insert(page, at: pdf.pageCount)

            let progress = Double(idx + 1) / Double(total)
            onProgress("[\(idx + 1)/\(total)] \(name)", progress)
        }

        let outURL = folder.appendingPathComponent("CroppedOutput.pdf")
        guard pdf.write(to: outURL) else {
            throw ProcessorError.pdfWriteFailed(outURL)
        }
        return outURL
    }
}
