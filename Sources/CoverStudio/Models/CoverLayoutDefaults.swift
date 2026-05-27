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
}
