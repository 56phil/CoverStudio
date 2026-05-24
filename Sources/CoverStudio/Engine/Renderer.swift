import CoreGraphics
import CoreImage
import AppKit

struct CoverRenderer {

    let data: CoverData
    let geometry: CoverGeometry
    let sourceURL: URL?

    init(data: CoverData, geometry: CoverGeometry, sourceURL: URL? = nil) {
        self.data = data
        self.geometry = geometry
        self.sourceURL = sourceURL
    }

    // ── Spine Color Derivation ──────────────────────

    func deriveSpineColor(from imagePath: String) -> NSColor {
        guard let image = NSImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return NSColor(red: 18/255, green: 43/255, blue: 34/255, alpha: 1)
        }
        let thumbSize = 40
        guard let thumbCtx = CGContext(
            data: nil, width: thumbSize, height: thumbSize,
            bitsPerComponent: 8, bytesPerRow: thumbSize * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return NSColor(red: 18/255, green: 43/255, blue: 34/255, alpha: 1) }
        thumbCtx.draw(cgImage, in: CGRect(x: 0, y: 0, width: thumbSize, height: thumbSize))
        guard let thumbData = thumbCtx.data else { return NSColor(red: 18/255, green: 43/255, blue: 34/255, alpha: 1) }
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
            if data.frontCoverImage.isEmpty { return NSColor(red: 18/255, green: 43/255, blue: 34/255, alpha: 1) }
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

        drawBack(ctx: ctx)
        drawFront(ctx: ctx)
        drawSpine(ctx: ctx)
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

    private func drawBack(ctx: CGContext) {
        let g = geometry
        let spineColor = resolveSpineColor()
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
        var blurbPillowBottom: CGFloat = CGFloat(g.trimTop) + CGFloat(CoverGeometry.px(0.5))
        if !blurb.isEmpty {
            let bx = safeX + CGFloat(data.blurbOffsetXInches) * 300
            let byPillow = CGFloat(g.trimTop) + CGFloat(CoverGeometry.px(0.5)) + CGFloat(data.blurbOffsetYInches) * 300
            let maxYPillow = CGFloat(g.trimBottom - g.safe) - 80
            blurbPillowBottom = drawWrappedLines(ctx: ctx, text: blurb, x: bx,
                yStart: cgYf(byPillow), font: CTFontCreateWithName("Arial" as CFString, 43, nil),
                color: NSColor(hex: data.colorBody), maxWidth: maxW,
                leading: 55, paragraphGap: 34, maxY: cgYf(maxYPillow))
        }

        // Quote — centered below blurb
        let quote = data.quote.trimmingCharacters(in: .whitespaces)
        if !quote.isEmpty {
            let qcx = CGFloat(g.effectiveBackLeft) + CGFloat(g.frontWidth) / 2 + CGFloat(data.quoteOffsetXInches) * 300
            let font = CTFontCreateWithName("Arial" as CFString,
                fitFontSize(text: "\u{201C}\(quote)\u{201D}", maxWidth: maxW, maxSize: 38, minSize: 14, fontName: "Arial"), nil)
            let color = NSColor(hex: data.colorAccent)
            let qyCG = blurbPillowBottom + 42 + CGFloat(data.quoteOffsetYInches) * 300
            _ = drawCenteredText(ctx: ctx, text: "\u{201C}\(quote)\u{201D}", font: font, color: color, centerX: qcx, y: cgYf(qyCG), shadow: false)

            let attr = data.quoteAttribution.trimmingCharacters(in: .whitespaces)
            if !attr.isEmpty {
                let afont = CTFontCreateWithName("Arial" as CFString, 30, nil)
                let acolor = NSColor(hex: data.colorSoft)
                let atext = attr.hasPrefix("-") ? attr : "- \(attr)"
                let ax = qcx + CGFloat(data.quoteAttributionOffsetXInches) * 300
                let ayCG = qyCG + 60 + CGFloat(data.quoteAttributionOffsetYInches) * 300
                _ = drawCenteredText(ctx: ctx, text: atext, font: afont, color: acolor, centerX: ax, y: cgYf(ayCG), shadow: false)
            }
        }

        // Author photo — at bottom of safe area
        let photoSize = CGFloat(CoverGeometry.px(data.authorPhotoScaleInches))
        let photoGap: CGFloat = 72
        let photoPath = data.authorPhoto.trimmingCharacters(in: .whitespaces)

        if !photoPath.isEmpty, let photo = NSImage(contentsOfFile: resolvedAssetPath(photoPath)) {
            let ppx = safeX + CGFloat(data.authorPhotoOffsetXInches) * 300
            // In Pillow: photoPillowY = trimBottom - safe - photoSize + offsetY
            // In CG: y = totalH - photoPillowY - photoSize
            let photoPillowY = CGFloat(g.trimBottom - g.safe) - photoSize + CGFloat(data.authorPhotoOffsetYInches) * 300
            let photoCGY = cgYf(photoPillowY)
            let rect = CGRect(x: ppx, y: photoCGY, width: photoSize, height: photoSize)
            if let cg = photo.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                let sz = min(cg.width, cg.height)
                let sx = (cg.width - sz)/2, sy = (cg.height - sz)/2
                if let cropped = cg.cropping(to: CGRect(x: sx, y: sy, width: sz, height: sz)) {
                    ctx.saveGState()
                    let clip = CGPath(roundedRect: rect, cornerWidth: photoSize/2, cornerHeight: photoSize/2, transform: nil)
                    ctx.addPath(clip); ctx.clip()
                    ctx.draw(cropped, in: rect)
                    ctx.restoreGState()
                }
            }
        }

        // Author bio
        let bio = data.authorBio.trimmingCharacters(in: .whitespaces)
        if !bio.isEmpty {
            let bfont = CTFontCreateWithName("Arial" as CFString, 32, nil)
            let bcolor = NSColor(hex: data.colorSoft)
            let bx = safeX + CGFloat(data.authorBioOffsetXInches) * 300

            // bioStartPillow = trimBottom - 2.5in + offsetY, flows down
            let bioStartPillow = CGFloat(g.trimBottom) - CGFloat(CoverGeometry.px(2.5)) + CGFloat(data.authorBioOffsetYInches) * 300
            // maxYPillow = trimBottom - safe (unless photo blocks it)
            let bioBasePillow = CGFloat(g.trimBottom - g.safe)
            let bioMaxPillow: CGFloat = photoPath.isEmpty ? bioBasePillow : cgYf(photoSize) - photoGap

            _ = drawWrappedLines(ctx: ctx, text: bio, x: bx,
                yStart: cgYf(bioStartPillow),
                font: bfont, color: bcolor, maxWidth: maxW,
                leading: 43, paragraphGap: CoverGeometry.px(data.authorBioParagraphGapPoints / 72.0),
                maxY: cgYf(bioMaxPillow))
        }
    }

    // ── Front Cover ────────────────────────────────────

    private func drawFront(ctx: CGContext) {
        let g = geometry
        if !data.frontCoverImage.isEmpty { drawFrontImage(ctx: ctx) }

        let maxW = CGFloat(g.frontWidth - g.safe * 2)
        let centerX = CGFloat(g.effectiveFrontLeft) + CGFloat(g.frontWidth) / 2
        let gold = NSColor(hex: data.colorTitle)

        // Title — Pillow: y = trimTop + 0.72in + offsetY
        let titleText = data.title.uppercased()
        if !titleText.isEmpty {
            let fontName = data.fontTitle.isEmpty ? "Arial Black" : data.fontTitle
            let scale = data.resolvedTitleScale()
            let fontSize = fitFontSize(text: titleText, maxWidth: maxW,
                                       maxSize: Int(178 * scale), minSize: 14, fontName: fontName)
            let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
            let tx = centerX + CGFloat(data.resolvedOffsetX()) * 300
            let tyPillow = CGFloat(g.trimTop) + CGFloat(CoverGeometry.px(0.72)) + CGFloat(data.resolvedOffsetY()) * 300
            _ = drawCenteredText(ctx: ctx, text: titleText, font: font, color: gold, centerX: tx, y: cgYf(tyPillow), shadow: true)

            // Subtitle — below title
            let subtitle = data.subtitle.trimmingCharacters(in: .whitespaces)
            if !subtitle.isEmpty {
                let sfont = CTFontCreateWithName("Arial" as CFString,
                    fitFontSize(text: subtitle, maxWidth: maxW, maxSize: 42, minSize: 10, fontName: "Arial"), nil)
                let scolor = NSColor(hex: data.colorAccent)
                let sx = centerX + CGFloat(data.frontSubtitleOffsetXInches) * 300
                let syPillow = tyPillow + CGFloat(CoverGeometry.px(0.42)) + 80 + CGFloat(data.frontSubtitleOffsetYInches) * 300
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
            let ax = centerX + CGFloat(data.resolvedAuthorOffsetX()) * 300
            let ayPillow = CGFloat(g.trimBottom) - CGFloat(CoverGeometry.px(0.57)) + CGFloat(data.resolvedAuthorOffsetY()) * 300
            _ = drawCenteredText(ctx: ctx, text: authorText, font: font, color: gold, centerX: ax, y: cgYf(ayPillow), shadow: false)
        }
    }

    private func drawFrontImage(ctx: CGContext) {
        guard let image = NSImage(contentsOf: URL(fileURLWithPath: resolvedAssetPath(data.frontCoverImage))),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let g = geometry
        // Front panel in Pillow coords: x = frontLeft, y = 0 (top), covers full height
        // In CG: x = frontLeft, y = 0 (bottom), height = totalHeight
        let totalH = CGFloat(g.totalHeight)
        let frontRect = CGRect(x: CGFloat(g.effectiveFrontLeft), y: 0,
                               width: CGFloat(g.frontWidth), height: totalH)

        ctx.saveGState(); ctx.clip(to: frontRect)
        let scale = max(frontRect.width / CGFloat(cg.width), frontRect.height / CGFloat(cg.height))
        let sw = CGFloat(cg.width) * scale, sh = CGFloat(cg.height) * scale
        let ox = data.frontCoverImageCentered ? (sw - frontRect.width)/2
                : (sw - frontRect.width)/2 + CGFloat(data.frontCoverImageOffsetXInches) * 300
        let oy = data.frontCoverImageCentered ? (sh - totalH)/2
                : (sh - totalH)/2 + CGFloat(data.frontCoverImageOffsetYInches) * 300
        ctx.draw(cg, in: CGRect(x: frontRect.minX - ox, y: frontRect.minY - oy, width: sw, height: sh))
        drawVerticalGradient(ctx: ctx, in: frontRect, topAlpha: 175, bottomAlpha: 205)
        ctx.restoreGState()
    }

    // ── Spine ──────────────────────────────────────────

    private func drawSpine(ctx: CGContext) {
        let g = geometry
        let sc = resolveSpineColor()
        let ext = CGFloat(data.spineColorExtensionInches) * 300
        let totalH = CGFloat(g.totalHeight)
        ctx.setFillColor(sc.cgColor)
        ctx.fill(CGRect(x: max(0, CGFloat(g.spineLeft) - ext), y: 0,
                         width: min(CGFloat(g.totalWidth), CGFloat(g.spineRight) + ext) - max(0, CGFloat(g.spineLeft) - ext),
                         height: totalH))
        guard data.spineText else { return }

        let center = CGFloat(g.spineLeft) + CGFloat(g.spineWidth)/2 + CGFloat(data.spineTextOffsetInches) * 300
        let gold = NSColor(hex: data.colorTitle)

        let st = data.title.uppercased()
        if !st.isEmpty {
            let font = CTFontCreateWithName((data.fontBold.isEmpty ? "Arial" : data.fontBold) as CFString, 42, nil)
            let tyPillow = CGFloat(g.trimTop) + CGFloat(CoverGeometry.px(0.9)) + CGFloat(data.spineTitleOffsetYInches) * 300
            drawRotatedText(ctx: ctx, text: st, font: font, color: gold,
                            centerX: center + CGFloat(data.spineTitleOffsetXInches) * 300,
                            y: cgYf(tyPillow), degrees: -90)
        }
        let sa = data.authorName.uppercased()
        if !sa.isEmpty {
            let font = CTFontCreateWithName((data.fontRegular.isEmpty ? "Arial" : data.fontRegular) as CFString, 28, nil)
            let ayPillow = CGFloat(g.trimBottom) - CGFloat(CoverGeometry.px(0.85)) + CGFloat(data.spineAuthorOffsetYInches) * 300
            drawRotatedText(ctx: ctx, text: sa, font: font, color: gold,
                            centerX: center + CGFloat(data.spineAuthorOffsetXInches) * 300,
                            y: cgYf(ayPillow), degrees: -90)
        }
    }

    // ── Guides ─────────────────────────────────────────

    private func drawGuides(ctx: CGContext) {
        let g = geometry
        let totalH = CGFloat(g.totalHeight)
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1)); ctx.setLineWidth(2)
        let xo = CGFloat(data.guideXOffsetInches) * 300
        for x in [CGFloat(g.effectiveBackLeft), CGFloat(g.effectiveBackRight),
                  CGFloat(g.spineLeft), CGFloat(g.spineRight),
                  CGFloat(g.effectiveFrontLeft), CGFloat(g.effectiveFrontRight)] {
            let xp = x + xo
            if xp >= 0 && xp <= CGFloat(g.totalWidth) {
                ctx.move(to: CGPoint(x: xp, y: 0)); ctx.addLine(to: CGPoint(x: xp, y: totalH))
            }
        }
        // Horizontal: Pillow trimTop → CG y = totalH - trimTop
        let trimTopCG = cgY(g.trimTop)
        let trimBottomCG = cgY(g.trimBottom)
        ctx.move(to: CGPoint(x: 0, y: trimTopCG)); ctx.addLine(to: CGPoint(x: CGFloat(g.totalWidth), y: trimTopCG))
        ctx.move(to: CGPoint(x: 0, y: trimBottomCG)); ctx.addLine(to: CGPoint(x: CGFloat(g.totalWidth), y: trimBottomCG))
        ctx.strokePath()
    }

    // ── Drawing Primitives ─────────────────────────────

    private func drawVerticalGradient(ctx: CGContext, in rect: CGRect, topAlpha: Int, bottomAlpha: Int) {
        let h = Int(rect.height)
        let maskCtx = CGContext(data: nil, width: 1, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.linearGray)!,
                                bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)!
        let d = maskCtx.data!.bindMemory(to: UInt8.self, capacity: h)
        for y in 0..<h {
            let r = Double(y) / max(1, Double(h) - 1)
            d[y] = UInt8(Double(topAlpha) * max(1 - r*2, 0) + Double(bottomAlpha) * max(r*2 - 1, 0))
        }
        let mask = maskCtx.makeImage()!
        ctx.saveGState(); ctx.clip(to: rect, mask: mask)
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1)); ctx.fill(rect)
        ctx.restoreGState()
    }

    func drawCenteredText(ctx: CGContext, text: String, font: CTFont, color: NSColor,
                           centerX: CGFloat, y: CGFloat, shadow: Bool) -> CGFloat {
        let attr = NSAttributedString(string: text, attributes: [.font: font as Any, .foregroundColor: color])
        let line = CTLineCreateWithAttributedString(attr)
        let box = CTLineGetImageBounds(line, ctx)
        let x = centerX - box.width / 2
        if shadow {
            let sa = NSAttributedString(string: text, attributes: [.font: font as Any, .foregroundColor: NSColor.black])
            let sl = CTLineCreateWithAttributedString(sa)
            ctx.textPosition = CGPoint(x: x + 5, y: y - 5); CTLineDraw(sl, ctx)
        }
        ctx.textPosition = CGPoint(x: x, y: y); ctx.textMatrix = .identity; CTLineDraw(line, ctx)
        return y + box.height
    }

    private func drawRotatedText(ctx: CGContext, text: String, font: CTFont, color: NSColor,
                                  centerX: CGFloat, y: CGFloat, degrees: CGFloat) {
        let attr = NSAttributedString(string: text, attributes: [.font: font as Any, .foregroundColor: color])
        let line = CTLineCreateWithAttributedString(attr)
        let box = CTLineGetImageBounds(line, ctx)
        let pad: CGFloat = 17
        let iw = Int(ceil(box.width + pad*2)), ih = Int(ceil(box.height + pad*2))
        guard let tc = CGContext(data: nil, width: iw, height: ih, bitsPerComponent: 8, bytesPerRow: iw*4,
                                 space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        tc.textPosition = CGPoint(x: pad, y: pad); tc.textMatrix = .identity; CTLineDraw(line, tc)
        guard let ti = tc.makeImage() else { return }
        ctx.saveGState()
        ctx.translateBy(x: centerX, y: y); ctx.rotate(by: degrees * .pi / 180)
        ctx.draw(ti, in: CGRect(x: -CGFloat(iw)/2, y: -CGFloat(ih)/2, width: CGFloat(iw), height: CGFloat(ih)))
        ctx.restoreGState()
    }

    /// Word-wraps text manually. CG y-coordinate: yStart is baseline, lines go upward (y decreases).
    /// maxY is the bottom boundary (lines must stay above maxY in CG coords).
    private func drawWrappedLines(ctx: CGContext, text: String, x: CGFloat, yStart: CGFloat,
                                   font: CTFont, color: NSColor, maxWidth: CGFloat,
                                   leading: CGFloat, paragraphGap: Int, maxY: CGFloat) -> CGFloat {
        var y = yStart
        for paragraph in text.components(separatedBy: "\n\n") {
            let words = paragraph.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            var line = ""
            for word in words {
                let trial = line.isEmpty ? word : "\(line) \(word)"
                let trialAttr = NSAttributedString(string: trial, attributes: [.font: font as Any])
                let trialLine = CTLineCreateWithAttributedString(trialAttr)
                let trialBox = CTLineGetImageBounds(trialLine, ctx)
                if trialBox.width <= maxWidth {
                    line = trial
                    continue
                }
                if !line.isEmpty {
                    if y < maxY { return y }
                    let la = NSAttributedString(string: line, attributes: [.font: font as Any, .foregroundColor: color])
                    let ll = CTLineCreateWithAttributedString(la)
                    ctx.textPosition = CGPoint(x: x, y: y); ctx.textMatrix = .identity; CTLineDraw(ll, ctx)
                    y -= leading
                }
                line = word
            }
            if !line.isEmpty {
                if y - leading < maxY { return y }
                let la = NSAttributedString(string: line, attributes: [.font: font as Any, .foregroundColor: color])
                let ll = CTLineCreateWithAttributedString(la)
                ctx.textPosition = CGPoint(x: x, y: y); ctx.textMatrix = .identity; CTLineDraw(ll, ctx)
                y -= leading
            }
            y -= CGFloat(paragraphGap)
        }
        return y
    }

    private func fitFontSize(text: String, maxWidth: CGFloat, maxSize: Int, minSize: Int, fontName: String) -> CGFloat {
        for s in stride(from: maxSize, through: minSize, by: -2) {
            let f = CTFontCreateWithName(fontName as CFString, CGFloat(s), nil)
            let a = NSAttributedString(string: text, attributes: [.font: f as Any])
            let l = CTLineCreateWithAttributedString(a)
            if CTLineGetImageBounds(l, nil).width <= maxWidth { return CGFloat(s) }
        }
        return CGFloat(minSize)
    }

    // ── Front Crop ─────────────────────────────────────

    func renderFrontCrop() -> CGImage? {
        guard let full = renderFullCover(includeGuides: false) else { return nil }
        let g = geometry
        // CG uses bottom-left origin: front panel starts at frontLeft, trimTop from bottom
        let frontTopCG = cgY(g.trimTop)
        let frontHeight = CGFloat(g.trimBottom - g.trimTop)
        return full.cropping(to: CGRect(x: CGFloat(g.effectiveFrontLeft), y: frontTopCG,
                                         width: CGFloat(g.frontWidth), height: frontHeight))
    }
}
