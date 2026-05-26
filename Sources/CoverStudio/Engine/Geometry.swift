import Foundation

/// Spine multipliers: (interior, paper) → inches per page
let spineMultipliers: [InteriorType: [PaperType: Double]] = [
    .blackWhite: [.white: 0.002252, .cream: 0.0025],
    .standardColor: [.white: 0.002252],
    .premiumColor: [.white: 0.002347],
]

/// All computed layout coordinates in pixels (at 300 DPI)
struct CoverGeometry {
    let bindingType: BindingType
    let readingDirection: ReadingDirection
    let totalWidth: Int       // pixels
    let totalHeight: Int      // pixels
    let frontWidth: Int       // pixels
    let frontHeight: Int      // pixels
    let spineWidth: Int       // pixels
    let bleed: Int            // pixels
    let hinge: Int            // pixels
    let wrap: Int             // pixels
    let safe: Int             // pixels
    let dpi: Int = 300

    // Raw inch values (for PDF export)
    let totalWidthInches: Double
    let totalHeightInches: Double
    let frontWidthInches: Double
    let frontHeightInches: Double
    let spineInches: Double
    let bleedInches: Double
    let hingeInches: Double
    let wrapInches: Double
    let safeInches: Double

    // Computed pixel positions
    var trimTop: Int { bindingType == .pb ? bleed : max(0, (totalHeight - frontHeight) / 2) }
    var trimBottom: Int { trimTop + frontHeight }
    var backLeft: Int { bindingType == .pb ? bleed : wrap }
    var backRight: Int { backLeft + frontWidth }
    var spineLeft: Int { bindingType == .pb ? backRight : backRight + hinge }
    var spineRight: Int { spineLeft + spineWidth }
    var frontLeft: Int { bindingType == .pb ? spineRight : spineRight + hinge }
    var frontRight: Int { frontLeft + frontWidth }

    // RTL swap
    var effectiveBackLeft: Int { readingDirection == .rtl ? frontLeft : backLeft }
    var effectiveBackRight: Int { readingDirection == .rtl ? frontRight : backRight }
    var effectiveFrontLeft: Int { readingDirection == .rtl ? backLeft : frontLeft }
    var effectiveFrontRight: Int { readingDirection == .rtl ? backRight : frontRight }

    init(data: CoverData, totalWidthInches: Double, totalHeightInches: Double, frontWidthInches: Double, frontHeightInches: Double, spineInches: Double, bleedInches: Double, hingeInches: Double, wrapInches: Double, safeInches: Double) {
        self.bindingType = data.bindingType
        self.readingDirection = data.readingDirection
        self.totalWidthInches = totalWidthInches
        self.totalHeightInches = totalHeightInches
        self.frontWidthInches = frontWidthInches
        self.frontHeightInches = frontHeightInches
        self.spineInches = spineInches
        self.bleedInches = bleedInches
        self.hingeInches = hingeInches
        self.wrapInches = wrapInches
        self.safeInches = safeInches
        self.totalWidth = Self.px(totalWidthInches)
        self.totalHeight = Self.px(totalHeightInches)
        self.frontWidth = Self.px(frontWidthInches)
        self.frontHeight = Self.px(frontHeightInches)
        self.spineWidth = Self.px(spineInches)
        self.bleed = Self.px(bleedInches)
        self.hinge = Self.px(hingeInches)
        self.wrap = Self.px(wrapInches)
        self.safe = Self.px(safeInches)
    }

    static func px(_ inches: Double) -> Int {
        Int((inches * 300).rounded())
    }
}

func computeGeometry(from data: CoverData) throws -> CoverGeometry {
    let trimPreset = data.trimSize

    let (trimW, trimH): (Double, Double)
    if trimPreset == .custom {
        guard data.customTrimWidthInches > 0, data.customTrimHeightInches > 0 else {
            throw GeometryError.customTrimMustBePositive
        }
        trimW = data.customTrimWidthInches
        trimH = data.customTrimHeightInches
    } else {
        (trimW, trimH) = trimPreset.dimensions
    }

    if data.bindingType == .pb {
        let interior = data.interiorType
        let paper = data.paperType
        guard let multiplier = spineMultipliers[interior]?[paper] else {
            throw GeometryError.noSpineMultiplier(interior: interior, paper: paper)
        }

        let customSpine = data.customSpineWidthInches
        let spine = customSpine > 0 ? customSpine : Double(data.resolvedPageCount()) * multiplier
        let bleed = data.customBleedInches > 0 ? data.customBleedInches : 0.125
        let safe = data.customSafeMarginInches > 0 ? data.customSafeMarginInches : 0.375
        let totalW = bleed + trimW + spine + trimW + bleed
        let totalH = bleed + trimH + bleed

        return CoverGeometry(
            data: data,
            totalWidthInches: totalW,
            totalHeightInches: totalH,
            frontWidthInches: trimW,
            frontHeightInches: trimH,
            spineInches: spine,
            bleedInches: bleed,
            hingeInches: 0,
            wrapInches: bleed,
            safeInches: safe
        )
    } else {
        // Hardcover
        guard let tfw = data.templateFullCoverWidth,
              let tfh = data.templateFullCoverHeight,
              let fcw = data.templateFrontCoverWidth,
              let fch = data.templateFrontCoverHeight,
              let tsw = data.templateSpineWidth,
              let thw = data.templateHingeWidth,
              let tww = data.templateWrapWidth else {
            throw GeometryError.hardcoverMissingTemplate
        }

        return CoverGeometry(
            data: data,
            totalWidthInches: tfw,
            totalHeightInches: tfh,
            frontWidthInches: fcw,
            frontHeightInches: fch,
            spineInches: tsw,
            bleedInches: 0,
            hingeInches: thw,
            wrapInches: tww,
            safeInches: 0.635
        )
    }
}

enum GeometryError: LocalizedError {
    case customTrimMustBePositive
    case noSpineMultiplier(interior: InteriorType, paper: PaperType)
    case hardcoverMissingTemplate

    var errorDescription: String? {
        switch self {
        case .customTrimMustBePositive:
            "Custom trim width and height must be greater than zero."
        case .noSpineMultiplier(let interior, let paper):
            "No paperback spine multiplier for \(interior.rawValue)/\(paper.rawValue)"
        case .hardcoverMissingTemplate:
            "Hardcover requires exact printer template dimensions."
        }
    }
}
