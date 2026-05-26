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
        var pageRect = CGRect(x: 0, y: 0, width: widthInches * 72.0, height: heightInches * 72.0)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let ctx = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
            throw ExportError.cannotWritePDF
        }

        ctx.beginPDFPage(nil)
        ctx.draw(image, in: pageRect)
        ctx.endPDFPage()
        ctx.closePDF()
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
