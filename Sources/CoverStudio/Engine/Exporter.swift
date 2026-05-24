import CoreGraphics
import AppKit
import PDFKit
import ImageIO
import UniformTypeIdentifiers

struct CoverExporter {

    /// Export the full wraparound cover as PNG.
    static func exportPNG(image: CGImage, dpi: Int = 300, to url: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw ExportError.cannotCreateDestination
        }
        let properties: [CFString: Any] = [
            kCGImagePropertyDPIWidth: dpi,
            kCGImagePropertyDPIHeight: dpi,
        ]
        CGImageDestinationAddImage(dest, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw ExportError.cannotFinalize
        }
    }

    /// Export a cropped region as JPEG.
    static func exportJPG(image: CGImage, dpi: Int = 300, quality: CGFloat = 0.95, to url: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ExportError.cannotCreateDestination
        }
        let properties: [CFString: Any] = [
            kCGImagePropertyDPIWidth: dpi,
            kCGImagePropertyDPIHeight: dpi,
            kCGImageDestinationLossyCompressionQuality: quality,
        ]
        CGImageDestinationAddImage(dest, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw ExportError.cannotFinalize
        }
    }

    /// Export a CGImage as a PDF with exact physical dimensions.
    static func exportPDF(image: CGImage, widthInches: Double, heightInches: Double, to url: URL) throws {
        let pdfWidth = widthInches * 72.0
        let pdfHeight = heightInches * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pdfWidth, height: pdfHeight)

        // For PDFKit page, use NSImage as an intermediary
        let nsImage = NSImage(cgImage: image, size: NSSize(width: CGFloat(image.width), height: CGFloat(image.height)))
        let page = PDFPage(image: nsImage)!
        page.setBounds(pageRect, for: .mediaBox)

        let document = PDFDocument()
        document.insert(page, at: 0)
        guard document.write(to: url) else {
            throw ExportError.cannotWritePDF
        }
    }

    /// Convenience: export all three formats for a cover.
    /// Returns a dictionary mapping format labels to URLs.
    static func exportAll(
        fullImage: CGImage,
        frontCropImage: CGImage,
        baseName: String,
        widthInches: Double,
        heightInches: Double,
        to directory: URL
    ) throws -> [String: URL] {
        let pngURL = directory.appendingPathComponent("\(baseName)-cover.png")
        let pdfURL = directory.appendingPathComponent("\(baseName)-cover.pdf")
        let jpgURL = directory.appendingPathComponent("\(baseName)-front.jpg")

        try exportPNG(image: fullImage, to: pngURL)
        try exportPDF(image: fullImage, widthInches: widthInches, heightInches: heightInches, to: pdfURL)
        try exportJPG(image: frontCropImage, to: jpgURL)

        return [
            "png": pngURL,
            "pdf": pdfURL,
            "jpg": jpgURL,
        ]
    }
}

enum ExportError: LocalizedError {
    case cannotCreateDestination
    case cannotFinalize
    case cannotWritePDF

    var errorDescription: String? {
        switch self {
        case .cannotCreateDestination: "Failed to create image destination for export."
        case .cannotFinalize: "Failed to finalize image export."
        case .cannotWritePDF: "Failed to write PDF document."
        }
    }
}
