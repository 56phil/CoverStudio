import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Materializes a front-cover image copy fitted to the current front-panel dimensions.
///
/// The copy lives next to the source image and is named `<base>-fitted.png`, so the
/// original base art is never modified. Auto mode cover-fits when the source aspect is
/// close to the panel, stretches otherwise, matching how the renderer draws the image.
enum FrontImageFitter {

    /// The path a fitted copy would have, without creating it.
    static func fittedPath(for sourceURL: URL) -> URL {
        sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent(sourceURL.deletingPathExtension().lastPathComponent + "-fitted.png")
    }

    /// The project-relative path to the fitted copy for `imagePath`, if one exists.
    static func relativeFittedPath(for imagePath: String, relativeTo sourceURL: URL?) -> String? {
        let resolved = ProjectManager.resolveImagePath(imagePath, relativeTo: sourceURL)
        let fitted = fittedPath(for: URL(fileURLWithPath: resolved))
        guard FileManager.default.fileExists(atPath: fitted.path) else { return nil }
        return ProjectManager.makeRelativePath(fitted, relativeTo: sourceURL)
    }

    /// True when the fitted copy was written at or after the source's last modification.
    private static func fittedModified(after fitted: URL, source: String) -> Bool {
        guard let fittedAttrs = try? FileManager.default.attributesOfItem(atPath: fitted.path),
              let sourceAttrs = try? FileManager.default.attributesOfItem(atPath: source),
              let fittedDate = (fittedAttrs[.creationDate] as? Date) ?? (fittedAttrs[.modificationDate] as? Date),
              let sourceDate = sourceAttrs[.modificationDate] as? Date else {
            return false
        }
        return fittedDate >= sourceDate
    }

    /// (Re)generate the fitted copy when the front-panel dimensions have changed since it
    /// was last created. Returns the fitted path, or nil when there is no source image.
    ///
    /// The panel is the full-height front side the renderer draws: front width plus bleed
    /// (outer cover edge to spine) by total cover height. Pixels at the geometry DPI.
    @discardableResult
    static func updateFittedImage(
        sourcePath: String,
        fit: FrontImageFit,
        panelWidth: Int,
        panelHeight: Int,
        dpi: Int = 300,
        relativeTo sourceURL: URL?
    ) -> String? {
        guard !sourcePath.isEmpty else { return nil }
        let resolved = ProjectManager.resolveImagePath(sourcePath, relativeTo: sourceURL)
        guard FileManager.default.fileExists(atPath: resolved) else { return nil }
        let source = URL(fileURLWithPath: resolved)
        let fitted = fittedPath(for: source)

        if FileManager.default.fileExists(atPath: fitted.path),
           let fittedImage = NSImage(contentsOfFile: fitted.path)?.cgImage(forProposedRect: nil, context: nil, hints: nil),
           fittedImage.width == panelWidth,
           fittedImage.height == panelHeight,
           fittedModified(after: fitted, source: resolved) {
            // Current when the pixels match the panel and the source has not changed since.
            return fitted.path
        }

        guard let imageData = try? Data(contentsOf: source),
              let image = NSImage(data: imageData),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let mode = fit.resolved(
            sourceWidth: cg.width, sourceHeight: cg.height,
            panelWidth: panelWidth, panelHeight: panelHeight
        )

        let ctx = CGContext(
            data: nil, width: panelWidth, height: panelHeight,
            bitsPerComponent: 8, bytesPerRow: panelWidth * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let ctx else { return nil }

        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: panelWidth, height: panelHeight))

        if mode == .stretch {
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        } else {
            let scale = max(CGFloat(panelWidth) / CGFloat(cg.width), CGFloat(panelHeight) / CGFloat(cg.height))
            let sw = CGFloat(cg.width) * scale, sh = CGFloat(cg.height) * scale
            ctx.draw(cg, in: CGRect(x: (CGFloat(panelWidth) - sw) / 2, y: (CGFloat(panelHeight) - sh) / 2, width: sw, height: sh))
        }

        guard let fittedImage = ctx.makeImage() else { return nil }
        guard let dest = CGImageDestinationCreateWithURL(fitted as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        let properties: [CFString: Any] = [
            kCGImagePropertyDPIWidth: dpi,
            kCGImagePropertyDPIHeight: dpi,
        ]
        CGImageDestinationAddImage(dest, fittedImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return fitted.path
    }
}
