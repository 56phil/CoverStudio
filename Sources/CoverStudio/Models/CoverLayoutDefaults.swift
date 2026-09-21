import Foundation

enum CoverLayoutDefaults {
    // Front cover anchors. Positive offset values still move from these anchors.
    static let frontTitleTopInches = 0.72
    static let frontSubtitleGapInches = 0.42 + (80.0 / 300.0)
    static let frontAuthorBottomInches = 0.57

    // Spine anchors.
    static let spineTitleTopInches = 0.9
    static let spineAuthorBottomInches = 0.85
    static let spineColorExtensionInches = 0.25

    // Back cover anchors.
    static let backBlurbTopInches = 0.5
    static let backQuoteGapInches = 42.0 / 300.0
    static let backQuoteAttributionGapInches = 60.0 / 300.0
    static let backAuthorBioBottomInches = 2.5
    static let backAuthorBioParagraphGapPoints = 8.0
    static let backAuthorPhotoSizeInches = 1.18
    static let backBarcodeBottomMarginInches = 0.25

    // Back cover text sizes, in points at the render DPI (300). The renderer
    // converts with px(), so 1pt here is 1px on the cover rather than a
    // typographic point. These are the sizes the renderer hardcoded before the
    // size became configurable, so an unset field reproduces the old output
    // exactly.
    static let backBlurbFontSizePoints = 43.0
    static let backQuoteFontSizePoints = 38.0
    static let backAuthorBioFontSizePoints = 32.0

    /// The quote is scaled down to fit the panel when it is too wide. These bound
    /// that reduction so a long quote shrinks rather than overflowing.
    static let backQuoteMinFontSizePoints = 14.0
    static let backQuoteAttributionFontSizePoints = 30.0
}
