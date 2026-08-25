import CoreGraphics
import CoreImage
import AppKit

struct CoverRenderer {

    let data: CoverData
    let geometry: CoverGeometry
    let sourceURL: URL?

    private static let fallbackSpineColor = NSColor(red: 18/255, green: 43/255, blue: 34/255, alpha: 1)

    init(data: CoverData, geometry: CoverGeometry, sourceURL: URL? = nil) {
        self.data = data
        self.geometry = geometry
        self.sourceURL = sourceURL
    }

    // ── Spine Color Derivation ──────────────────────

    func deriveSpineColor(from imagePath: String) -> NSColor {
        guard let image = NSImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return Self.fallbackSpineColor
        }
        let thumbSize = 40
        guard let thumbCtx = CGContext(
            data: nil, width: thumbSize, height: thumbSize,
            bitsPerComponent: 8, bytesPerRow: thumbSize * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return Self.fallbackSpineColor }
        thumbCtx.draw(cgImage, in: CGRect(x: 0, y: 0, width: thumbSize, height: thumbSize))
        guard let thumbData = thumbCtx.data else { return Self.fallbackSpineColor }
        let pixels = thumbData.bindMemory(to: UInt8.self, capacity: thumbSize * thumbSize * 4)
        var seen: [String: (count: Int, color: (Int, Int, Int))] = [:]
        for i in stride(from: 0, to: thumbSize * thumbSize * 4, by: 4) {
            let r = Int(pixels[i]), g = Int(pixels[i+1]), b = Int(pixels[i+2])
            let key = "\(r/8),\(g/8),\(b/8)"
            if let existing = seen[key] { seen[key] = (existing.count + 1, existing.color) }
            else { seen[key] = (1, (r, g, b)) }
        }
        struct Scored { let r: Int, g: Int, b: Int, score: Double }
        var scored: [Scored] = []
        for (_, entry) in seen {
            let (r, g, b) = entry.color
            let brightness = Double(r + g + b) / 3
            let saturation = Double(max(r, g, b) - min(r, g, b))
            let score = Double(entry.count) * (1 + saturation / 255) * (1.35 - abs(brightness - 95) / 255)
            scored.append(Scored(r: r, g: g, b: b, score: score))
        }
        scored.sort { $0.score > $1.score }
        let winner = scored.first ?? Scored(r: 18, g: 43, b: 34, score: 0)
        let dr = max(8, min(90, Int(Double(winner.r) * 0.45)))
        let dg = max(8, min(90, Int(Double(winner.g) * 0.45)))
        let db = max(8, min(90, Int(Double(winner.b) * 0.45)))
        return NSColor(red: CGFloat(dr)/255, green: CGFloat(dg)/255, blue: CGFloat(db)/255, alpha: 1)
    }

    func resolveSpineColor() -> NSColor {
        let v = data.spineColor.trimmingCharacters(in: .whitespaces)
        if v.isEmpty || v.lowercased() == "auto" {
            if data.frontCoverImage.isEmpty { return Self.fallbackSpineColor }
            return deriveSpineColor(from: resolvedAssetPath(data.frontCoverImage))
        }
        return NSColor(hex: v)
    }

    private func resolvedAssetPath(_ path: String) -> String {
        ProjectManager.resolveImagePath(path, relativeTo: sourceURL)
    }

    // ── Master Render ──────────────────────────────────

    func renderFullCover(includeGuides: Bool = true) -> CGImage? {
        let totalW = geometry.totalWidth, totalH = geometry.totalHeight
        guard let ctx = CGContext(
            data: nil, width: totalW, height: totalH, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Fill background (CoreGraphics bottom-left origin, y=0 is bottom)
        ctx.setFillColor(NSColor(red: 24/255, green: 31/255, blue: 29/255, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: totalW, height: totalH))

        let spineColor = resolveSpineColor()
        drawBack(ctx: ctx, spineColor: spineColor)
        drawFront(ctx: ctx)
        drawSpine(ctx: ctx, spineColor: spineColor)
        if includeGuides { drawGuides(ctx: ctx) }
        return ctx.makeImage()
    }

    // Convert Pillow-style top-down y to CoreGraphics bottom-up y
    private func cgY(_ pillowY: Int) -> CGFloat {
        CGFloat(geometry.totalHeight - pillowY)
    }
    private func cgYf(_ pillowY: CGFloat) -> CGFloat {
        CGFloat(geometry.totalHeight) - pillowY
    }

    // ── Back Cover ─────────────────────────────────────

    private func drawBack(ctx: CGContext, spineColor: NSColor) {
        let g = geometry
        let totalH = CGFloat(g.totalHeight)

        let backBox: CGRect = g.effectiveBackLeft < g.spineLeft
            ? CGRect(x: 0, y: 0, width: CGFloat(g.spineLeft), height: totalH)
            : CGRect(x: CGFloat(g.spineRight), y: 0, width: CGFloat(g.totalWidth - g.spineRight), height: totalH)
        ctx.setFillColor(spineColor.cgColor)
        ctx.fill(backBox)

        let safeX = CGFloat(g.effectiveBackLeft + g.safe)
        let maxW = CGFloat(g.frontWidth - g.safe * 2)

        // Blurb — starts at top of safe area, flows down (Pillow y increases downward, CG y decreases upward)
        let blurb = data.blurb.trimmingCharacters(in: .whitespaces)
        var blurbPillowBottom = CGFloat(g.trimTop) + CGFloat(CoverGeometry.px(CoverLayoutDefaults.backBlurbTopInches))
        if !blurb.isEmpty {
            let bx = safeX + CGFloat(data.blurbOffsetXInches) * CGFloat(geometry.dpi)
            let byPillow = CGFloat(g.trimTop) + CGFloat(CoverGeometry.px(CoverLayoutDefaults.backBlurbTopInches)) + CGFloat(data.blurbOffsetYInches) * CGFloat(geometry.dpi)
            let maxYPillow = CGFloat(g.trimBottom - g.safe) - 80
            let blurbMaxWidth = data.blurbWidthInches > 0
                ? CGFloat(CoverGeometry.px(data.blurbWidthInches))
                : maxW
            blurbPillowBottom = drawWrappedTextBlock(ctx: ctx, text: blurb, x: bx,
                pillowTop: byPillow, font: CTFontCreateWithName("Arial" as CFString, 43, nil),
                color: NSColor(hex: data.colorBody), maxWidth: min(maxW, blurbMaxWidth),
                lineSpacing: 6, paragraphSpacing: 20, maxPillowBottom: maxYPillow)
        }

        // Quote — centered below blurb
        let quote = data.quote.trimmingCharacters(in: .whitespaces)
        if !quote.isEmpty {
            let qcx = CGFloat(g.effectiveBackLeft) + CGFloat(g.frontWidth) / 2 + CGFloat(data.quoteOffsetXInches) * CGFloat(geometry.dpi)
            let font = CTFontCreateWithName("Arial" as CFString,
                fitFontSize(text: "\u{201C}\(quote)\u{201D}", maxWidth: maxW, maxSize: 38, minSize: 14, fontName: "Arial"), nil)
            let color = NSColor(hex: data.colorAccent)
            let quotePillowY = blurbPillowBottom + CGFloat(CoverGeometry.px(CoverLayoutDefaults.backQuoteGapInches)) + CGFloat(data.quoteOffsetYInches) * CGFloat(geometry.dpi)
            _ = drawCenteredText(ctx: ctx, text: "\u{201C}\(quote)\u{201D}", font: font, color: color, centerX: qcx, y: cgYf(quotePillowY), shadow: false)

            let attr = data.quoteAttribution.trimmingCharacters(in: .whitespaces)
            if !attr.isEmpty {
                let afont = CTFontCreateWithName("Arial" as CFString, 30, nil)
                let acolor = NSColor(hex: data.colorSoft)
                let atext = attr.hasPrefix("-") ? attr : "- \(attr)"
                let ax = qcx + CGFloat(data.quoteAttributionOffsetXInches) * CGFloat(geometry.dpi)
                let attributionPillowY = quotePillowY + CGFloat(CoverGeometry.px(CoverLayoutDefaults.backQuoteAttributionGapInches)) + CGFloat(data.quoteAttributionOffsetYInches) * CGFloat(geometry.dpi)
                _ = drawCenteredText(ctx: ctx, text: atext, font: afont, color: acolor, centerX: ax, y: cgYf(attributionPillowY), shadow: false)
            }
        }

        // Author photo — bottom aligned with the barcode zone baseline
        let photoSize = CGFloat(CoverGeometry.px(data.authorPhotoScaleInches))
        let photoGap: CGFloat = 72
        let photoPath = data.authorPhoto.trimmingCharacters(in: .whitespaces)
        let photoPillowY = CGFloat(g.backBarcodeZoneBottom) - photoSize + CGFloat(data.authorPhotoOffsetYInches) * CGFloat(geometry.dpi)

        if !photoPath.isEmpty, let photo = NSImage(contentsOfFile: resolvedAssetPath(photoPath)) {
            let ppx = safeX + CGFloat(data.authorPhotoOffsetXInches) * CGFloat(geometry.dpi)
            let photoCGY = cgYf(photoPillowY)
            let rect = CGRect(x: ppx, y: photoCGY, width: photoSize, height: photoSize)
            if let cg = photo.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                switch data.authorPhotoShape {
                case .circle, .square:
                    let sz = min(cg.width, cg.height)
                    let maxShiftX = CGFloat(cg.width - sz) / 2
                    let maxShiftY = CGFloat(cg.height - sz) / 2
                    let sx = min(max(maxShiftX * (1 + CGFloat(data.authorPhotoCropOffsetX)), 0), maxShiftX * 2)
                    let sy = min(max(maxShiftY * (1 + CGFloat(data.authorPhotoCropOffsetY)), 0), maxShiftY * 2)
                    if let cropped = cg.cropping(to: CGRect(x: sx, y: sy, width: CGFloat(sz), height: CGFloat(sz))) {
                        ctx.saveGState()
                        if data.authorPhotoShape == .circle {
                            let clip = CGPath(roundedRect: rect, cornerWidth: photoSize/2, cornerHeight: photoSize/2, transform: nil)
                            ctx.addPath(clip); ctx.clip()
                        }
                        ctx.draw(cropped, in: rect)
                        ctx.restoreGState()
                    }
                case .raw:
                    let aspect = CGFloat(cg.width) / CGFloat(cg.height)
                    let rawRect: CGRect
                    if aspect >= 1 {
                        let height = photoSize / aspect
                        rawRect = CGRect(x: rect.minX, y: rect.midY - height / 2, width: photoSize, height: height)
                    } else {
                        let width = photoSize * aspect
                        rawRect = CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: photoSize)
                    }
                    ctx.draw(cg, in: rawRect)
                }
            }
        }

        // Author bio
        let bio = data.authorBio.trimmingCharacters(in: .whitespaces)
        if !bio.isEmpty {
            let bfont = CTFontCreateWithName("Arial" as CFString, 32, nil)
            let bcolor = NSColor(hex: data.colorSoft)
            let bx = safeX + CGFloat(data.authorBioOffsetXInches) * CGFloat(geometry.dpi)

            // bioStartPillow = trimBottom - 2.5in + offsetY, flows down
            let bioStartPillow = CGFloat(g.trimBottom) - CGFloat(CoverGeometry.px(CoverLayoutDefaults.backAuthorBioBottomInches)) + CGFloat(data.authorBioOffsetYInches) * CGFloat(geometry.dpi)
            // maxYPillow = trimBottom - safe (unless photo blocks it)
            let bioBasePillow = CGFloat(g.trimBottom - g.safe)
            let bioMaxPillow = photoPath.isEmpty
                ? bioBasePillow
                : photoPillowY - photoGap
            let bioMaxWidth = data.authorBioWidthInches > 0
                ? CGFloat(CoverGeometry.px(data.authorBioWidthInches))
                : maxW

            _ = drawWrappedTextBlock(ctx: ctx, text: bio, x: bx,
                pillowTop: bioStartPillow,
                font: bfont, color: bcolor, maxWidth: min(maxW, bioMaxWidth),
                lineSpacing: 5, paragraphSpacing: data.authorBioParagraphGapPoints,
                maxPillowBottom: bioMaxPillow)
        }
    }

    // ── Front Cover ────────────────────────────────────

    private func drawFront(ctx: CGContext) {
        let g = geometry
        if !data.frontCoverImage.isEmpty { drawFrontImage(ctx: ctx) }
        guard data.frontText else { return }

        let maxW = CGFloat(g.frontWidth - g.safe * 2)
        let centerX = CGFloat(g.effectiveFrontLeft) + CGFloat(g.frontWidth) / 2
        let centerPillowY = CGFloat(g.trimTop) + CGFloat(g.frontHeight) / 2
        let gold = NSColor(hex: data.colorTitle)
        let frontTextRect = CGRect(
            x: CGFloat(g.effectiveFrontLeft),
            y: cgYf(CGFloat(g.trimBottom)),
            width: CGFloat(g.frontWidth),
            height: CGFloat(g.frontHeight)
        )

        ctx.saveGState()
        ctx.clip(to: frontTextRect)
        // Title — Pillow: y = trimTop + 0.72in + offsetY
        let titleText = data.title.uppercased()
        if !titleText.isEmpty {
            let fontName = data.fontTitle.isEmpty ? "Arial Black" : data.fontTitle
            let scale = data.resolvedTitleScale()
            let fontSize = fitFontSize(text: titleText, maxWidth: maxW,
                                       maxSize: Int(178 * scale), minSize: 14, fontName: fontName)
            let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
            let tx = data.resolvedTitleCenterX()
                ? centerX
                : centerX + CGFloat(data.resolvedOffsetX()) * CGFloat(geometry.dpi)
            let tyPillow = data.resolvedTitleCenterY()
                ? centerPillowY
                : CGFloat(g.trimTop) + CGFloat(CoverGeometry.px(CoverLayoutDefaults.frontTitleTopInches)) + CGFloat(data.resolvedOffsetY()) * CGFloat(geometry.dpi)
            _ = drawCenteredText(ctx: ctx, text: titleText, font: font, color: gold, centerX: tx, y: cgYf(tyPillow), shadow: true)

            // Subtitle — below title
            let subtitle = data.subtitle.trimmingCharacters(in: .whitespaces)
            if !subtitle.isEmpty {
                let subtitleScale = data.resolvedSubtitleScale()
                let maxSubtitleSize = max(10, Int(42 * subtitleScale))
                let sfont = CTFontCreateWithName("Arial" as CFString,
                    fitFontSize(text: subtitle, maxWidth: maxW, maxSize: maxSubtitleSize, minSize: 10, fontName: "Arial"), nil)
                let scolor = NSColor(hex: data.colorAccent)
                let sx = data.resolvedSubtitleCenterX()
                    ? centerX
                    : centerX + CGFloat(data.resolvedSubtitleOffsetX()) * CGFloat(geometry.dpi)
                let syPillow = data.resolvedSubtitleCenterY()
                    ? centerPillowY
                    : tyPillow + CGFloat(CoverGeometry.px(CoverLayoutDefaults.frontSubtitleGapInches)) + CGFloat(data.resolvedSubtitleOffsetY()) * CGFloat(geometry.dpi)
                _ = drawCenteredText(ctx: ctx, text: subtitle, font: sfont, color: scolor, centerX: sx, y: cgYf(syPillow), shadow: false)
            }
        }

        // Author — Pillow: y = trimBottom - 0.57in + offsetY
        let authorText = data.authorName.uppercased()
        if !authorText.isEmpty {
            let fontName = data.fontBold.isEmpty ? "Arial" : data.fontBold
            let scale = data.resolvedAuthorScale()
            let fontSize = fitFontSize(text: authorText, maxWidth: maxW,
                                       maxSize: Int(48 * scale), minSize: 12, fontName: fontName)
            let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
            let ax = data.resolvedAuthorCenterX()
                ? centerX
                : centerX + CGFloat(data.resolvedAuthorOffsetX()) * CGFloat(geometry.dpi)
            let ayPillow = data.resolvedAuthorCenterY()
                ? centerPillowY
                : CGFloat(g.trimBottom) - CGFloat(CoverGeometry.px(CoverLayoutDefaults.frontAuthorBottomInches)) + CGFloat(data.resolvedAuthorOffsetY()) * CGFloat(geometry.dpi)
            _ = drawCenteredText(ctx: ctx, text: authorText, font: font, color: gold, centerX: ax, y: cgYf(ayPillow), shadow: false)
        }
        ctx.restoreGState()
    }

    private func drawFrontImage(ctx: CGContext) {
        let assetPath = resolvedAssetPath(data.frontCoverImage)
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: assetPath)),
              let image = NSImage(data: imageData),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let g = geometry
        let imageRect = CGRect(
            x: CGFloat(g.frontImageLeft),
            y: 0,
            width: CGFloat(g.frontImageWidth),
            height: CGFloat(g.totalHeight)
        )

        ctx.saveGState(); ctx.clip(to: imageRect)
        let fit = data.frontImageFit.resolved(
            sourceWidth: cg.width, sourceHeight: cg.height,
            panelWidth: Int(imageRect.width), panelHeight: Int(imageRect.height)
        )
        if fit == .stretch {
            ctx.draw(cg, in: imageRect)
        } else {
            let scale = max(imageRect.width / CGFloat(cg.width), imageRect.height / CGFloat(cg.height))
            let sw = CGFloat(cg.width) * scale, sh = CGFloat(cg.height) * scale
            let ox = data.frontCoverImageCentered ? (sw - imageRect.width)/2
                    : (sw - imageRect.width)/2 + CGFloat(data.resolvedImageOffsetX()) * CGFloat(geometry.dpi)
            let oy = data.frontCoverImageCentered ? (sh - imageRect.height)/2
                    : (sh - imageRect.height)/2 + CGFloat(data.resolvedImageOffsetY()) * CGFloat(geometry.dpi)
            ctx.draw(cg, in: CGRect(x: imageRect.minX - ox, y: imageRect.minY - oy, width: sw, height: sh))
        }
        ctx.restoreGState()
    }

    // ── Spine ──────────────────────────────────────────

    private func drawSpine(ctx: CGContext, spineColor: NSColor) {
        let g = geometry
        let sc = spineColor
        let ext = CGFloat(data.spineColorExtensionInches) * CGFloat(geometry.dpi)
        let totalH = CGFloat(g.totalHeight)
        ctx.setFillColor(sc.cgColor)
        ctx.fill(CGRect(x: CGFloat(g.spineLeft), y: 0,
                         width: min(CGFloat(g.totalWidth) - CGFloat(g.spineLeft), CGFloat(g.spineWidth) + ext),
                         height: totalH))
        guard data.spineText else { return }

        let center = CGFloat(g.spineLeft) + CGFloat(g.spineWidth)/2 + CGFloat(data.spineTextOffsetInches) * CGFloat(geometry.dpi)
        let gold = NSColor(hex: data.colorTitle)

        let st = data.title.uppercased()
        if !st.isEmpty {
            let font = CTFontCreateWithName((data.fontBold.isEmpty ? "Arial" : data.fontBold) as CFString, 42, nil)
            let tyPillow = CGFloat(g.trimTop) + CGFloat(CoverGeometry.px(CoverLayoutDefaults.spineTitleTopInches)) + CGFloat(data.spineTitleOffsetYInches) * CGFloat(geometry.dpi)
            drawRotatedText(ctx: ctx, text: st, font: font, color: gold,
                            centerX: center + CGFloat(data.spineTitleOffsetXInches) * CGFloat(geometry.dpi),
                            y: cgYf(tyPillow), degrees: -90)
        }
        let sa = data.authorName.uppercased()
        if !sa.isEmpty {
            let font = CTFontCreateWithName((data.fontRegular.isEmpty ? "Arial" : data.fontRegular) as CFString, 28, nil)
            let ayPillow = CGFloat(g.trimBottom) - CGFloat(CoverGeometry.px(CoverLayoutDefaults.spineAuthorBottomInches)) + CGFloat(data.spineAuthorOffsetYInches) * CGFloat(geometry.dpi)
            drawRotatedText(ctx: ctx, text: sa, font: font, color: gold,
                            centerX: center + CGFloat(data.spineAuthorOffsetXInches) * CGFloat(geometry.dpi),
                            y: cgYf(ayPillow), degrees: -90)
        }
    }

    // ── Guides ─────────────────────────────────────────

    private func drawGuides(ctx: CGContext) {
        let g = geometry
        let totalH = CGFloat(g.totalHeight)
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1)); ctx.setLineWidth(2)
        let xo = CGFloat(data.guideXOffsetInches) * CGFloat(geometry.dpi)
        for x in [CGFloat(g.effectiveBackLeft), CGFloat(g.effectiveBackRight),
                  CGFloat(g.spineLeft), CGFloat(g.spineRight),
                  CGFloat(g.effectiveFrontLeft), CGFloat(g.effectiveFrontRight)] {
            let xp = min(max(x + xo, 0), CGFloat(g.totalWidth))
            ctx.move(to: CGPoint(x: xp, y: 0)); ctx.addLine(to: CGPoint(x: xp, y: totalH))
        }
        // Horizontal: Pillow trimTop → CG y = totalH - trimTop
        let trimTopCG = cgY(g.trimTop)
        let trimBottomCG = cgY(g.trimBottom)
        ctx.move(to: CGPoint(x: 0, y: trimTopCG)); ctx.addLine(to: CGPoint(x: CGFloat(g.totalWidth), y: trimTopCG))
        ctx.move(to: CGPoint(x: 0, y: trimBottomCG)); ctx.addLine(to: CGPoint(x: CGFloat(g.totalWidth), y: trimBottomCG))
        ctx.strokePath()
    }

    // ── Drawing Primitives ─────────────────────────────

    func drawCenteredText(ctx: CGContext, text: String, font: CTFont, color: NSColor,
                           centerX: CGFloat, y: CGFloat, shadow: Bool) -> CGFloat {
        let attr = attributedText(text, font: font, color: color)
        let size = attr.size()
        let x = centerX - size.width / 2
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        if shadow {
            let shadowAttr = attributedText(text, font: font, color: .black.withAlphaComponent(0.45))
            shadowAttr.draw(at: CGPoint(x: x + 5, y: y - 5))
        }
        attr.draw(at: CGPoint(x: x, y: y))
        NSGraphicsContext.restoreGraphicsState()
        return y + size.height
    }

    private func drawRotatedText(ctx: CGContext, text: String, font: CTFont, color: NSColor,
                                  centerX: CGFloat, y: CGFloat, degrees: CGFloat) {
        let attr = attributedText(text, font: font, color: color)
        let size = attr.size()
        ctx.saveGState()
        ctx.translateBy(x: centerX, y: y); ctx.rotate(by: degrees * .pi / 180)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        attr.draw(at: CGPoint(x: -size.width / 2, y: -size.height / 2))
        NSGraphicsContext.restoreGraphicsState()
        ctx.restoreGState()
    }

    private func attributedText(_ text: String, font: CTFont, color: NSColor) -> NSAttributedString {
        let fontName = CTFontCopyPostScriptName(font) as String
        let fontSize = CTFontGetSize(font)
        let nsFont = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        return NSAttributedString(string: text, attributes: [.font: nsFont, .foregroundColor: color])
    }

    private func attributedParagraphText(
        _ text: String,
        font: CTFont,
        color: NSColor,
        lineSpacing: CGFloat,
        paragraphSpacing: CGFloat
    ) -> NSAttributedString {
        let fontName = CTFontCopyPostScriptName(font) as String
        let fontSize = CTFontGetSize(font)
        let nsFont = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        return NSAttributedString(
            string: text,
            attributes: [.font: nsFont, .foregroundColor: color, .paragraphStyle: style]
        )
    }

    private func drawWrappedTextBlock(
        ctx: CGContext,
        text: String,
        x: CGFloat,
        pillowTop: CGFloat,
        font: CTFont,
        color: NSColor,
        maxWidth: CGFloat,
        lineSpacing: CGFloat,
        paragraphSpacing: CGFloat,
        maxPillowBottom: CGFloat
    ) -> CGFloat {
        let attr = attributedParagraphText(
            text,
            font: font,
            color: color,
            lineSpacing: lineSpacing,
            paragraphSpacing: paragraphSpacing
        )
        let availableHeight = max(0, maxPillowBottom - pillowTop)
        let measureRect = CGRect(x: 0, y: 0, width: maxWidth, height: availableHeight)
        let measured = attr.boundingRect(
            with: measureRect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).integral
        let drawHeight = min(availableHeight, measured.height)
        let pillowRect = CGRect(x: x, y: pillowTop, width: maxWidth, height: drawHeight)

        ctx.saveGState()
        ctx.translateBy(x: 0, y: CGFloat(geometry.totalHeight))
        ctx.scaleBy(x: 1, y: -1)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        attr.draw(with: pillowRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        NSGraphicsContext.restoreGraphicsState()
        ctx.restoreGState()

        return pillowTop + drawHeight
    }

    private func fitFontSize(text: String, maxWidth: CGFloat, maxSize: Int, minSize: Int, fontName: String) -> CGFloat {
        for s in stride(from: maxSize, through: minSize, by: -2) {
            let f = CTFontCreateWithName(fontName as CFString, CGFloat(s), nil)
            if attributedText(text, font: f, color: .black).size().width <= maxWidth { return CGFloat(s) }
        }
        return CGFloat(minSize)
    }

    // ── Front Crop ─────────────────────────────────────

    func renderFrontCrop() -> CGImage? {
        guard let full = renderFullCover(includeGuides: false) else { return nil }
        let g = geometry
        let cropX: CGFloat
        let cropWidth: CGFloat
        if g.bindingType == .hc {
            if g.readingDirection == .rtl {
                cropX = 0
                cropWidth = CGFloat(g.spineLeft)
            } else {
                cropX = CGFloat(g.spineRight)
                cropWidth = CGFloat(g.totalWidth - g.spineRight)
            }
        } else {
            cropX = CGFloat(g.effectiveFrontLeft)
            cropWidth = CGFloat(g.frontWidth)
        }
        let frontHeight = CGFloat(g.trimBottom - g.trimTop)
        let cropRect = CGRect(
            x: cropX,
            y: CGFloat(g.trimTop),
            width: cropWidth,
            height: frontHeight
        )
        let imageRect = CGRect(x: 0, y: 0, width: full.width, height: full.height)
        return full.cropping(to: cropRect.intersection(imageRect))
    }
}
