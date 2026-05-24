import Foundation
import Yams

struct CoverData: Codable, Equatable {
    var schemaVersion: Int = 1

    // Binding
    var bindingType: BindingType = .pb
    var interiorType: InteriorType = .blackWhite
    var paperType: PaperType = .white
    var readingDirection: ReadingDirection = .ltr

    // Trim
    var platformPreset: Bool = true
    var trimSize: TrimPreset = .sixX9
    var customTrimWidthInches: Double = 6.0
    var customTrimHeightInches: Double = 9.0
    var customSpineWidthInches: Double = 0.0
    var customBleedInches: Double = 0.125
    var customSafeMarginInches: Double = 0.375

    // Page
    var pageCount: Int = 200

    // UI
    var uiUnits: Units = .inches
    var guideXOffsetInches: Double = 0.0

    // Front cover — image
    var frontCoverImage: String = ""
    var frontCoverImageCentered: Bool = false
    var frontCoverImageOffsetXInches: Double = 0.0
    var frontCoverImageOffsetYInches: Double = 0.0

    // Front cover — text
    var frontText: Bool = true
    var title: String = ""
    var subtitle: String = ""
    var authorName: String = ""
    var frontTitleOffsetXInches: Double = 0.0
    var frontTitleOffsetYInches: Double = 0.0
    var frontTitleScale: Double = 1.0
    var frontSubtitleOffsetXInches: Double = 0.0
    var frontSubtitleOffsetYInches: Double = 0.0
    var frontAuthorOffsetXInches: Double = 0.0
    var frontAuthorOffsetYInches: Double = 0.0
    var frontAuthorScale: Double = 1.0

    // Binding-specific overrides (hc_ prefixed keys in legacy cover.md)
    var hcFrontImageOffsetXInches: Double = 0.0
    var hcFrontImageOffsetYInches: Double = 0.0
    var hcFrontTitleOffsetXInches: Double = 0.0
    var hcFrontTitleOffsetYInches: Double = 0.0
    var hcFrontSubtitleOffsetXInches: Double = 0.0
    var hcFrontSubtitleOffsetYInches: Double = 0.0
    var hcFrontAuthorOffsetXInches: Double = 0.0
    var hcFrontAuthorOffsetYInches: Double = 0.0
    var hcFrontTitleScale: Double = 1.0
    var hcFrontAuthorScale: Double = 1.0

    // Resolve offset based on current binding type (hc uses binding-specific overrides)
    func resolvedOffsetX() -> Double {
        if bindingType == .hc { return hcFrontTitleOffsetXInches }
        return frontTitleOffsetXInches
    }
    func resolvedOffsetY() -> Double {
        if bindingType == .hc { return hcFrontTitleOffsetYInches }
        return frontTitleOffsetYInches
    }
    func resolvedTitleScale() -> Double {
        if bindingType == .hc { return hcFrontTitleScale }
        return frontTitleScale
    }
    func resolvedAuthorOffsetX() -> Double {
        if bindingType == .hc { return hcFrontAuthorOffsetXInches }
        return frontAuthorOffsetXInches
    }
    func resolvedAuthorOffsetY() -> Double {
        if bindingType == .hc { return hcFrontAuthorOffsetYInches }
        return frontAuthorOffsetYInches
    }
    func resolvedAuthorScale() -> Double {
        if bindingType == .hc { return hcFrontAuthorScale }
        return frontAuthorScale
    }
    func resolvedImageOffsetX() -> Double {
        if bindingType == .hc { return hcFrontImageOffsetXInches }
        return frontCoverImageOffsetXInches
    }
    func resolvedImageOffsetY() -> Double {
        if bindingType == .hc { return hcFrontImageOffsetYInches }
        return frontCoverImageOffsetYInches
    }

    // Spine
    var spineText: Bool = true
    var spineColor: String = "auto"
    var spineTextOffsetInches: Double = 0.0
    var spineColorExtensionInches: Double = 0.25
    var spineTitleOffsetXInches: Double = 0.0
    var spineTitleOffsetYInches: Double = 0.0
    var spineAuthorOffsetXInches: Double = 0.0
    var spineAuthorOffsetYInches: Double = 0.0

    // Back cover — text
    var blurb: String = ""
    var blurbOffsetXInches: Double = 0.0
    var blurbOffsetYInches: Double = 0.0
    var quote: String = ""
    var quoteAttribution: String = ""
    var quoteOffsetXInches: Double = 0.0
    var quoteOffsetYInches: Double = 0.0
    var quoteAttributionOffsetXInches: Double = 0.0
    var quoteAttributionOffsetYInches: Double = 0.0
    var authorBio: String = ""
    var authorBioOffsetXInches: Double = 0.0
    var authorBioOffsetYInches: Double = 0.0
    var authorBioParagraphGapPoints: Double = 8.0

    // Back cover — image
    var authorPhoto: String = ""
    var authorPhotoScaleInches: Double = 1.18
    var authorPhotoOffsetXInches: Double = 0.0
    var authorPhotoOffsetYInches: Double = 0.0

    // Colors
    var colorTitle: String = "#daa520"
    var colorAccent: String = "#eec448"
    var colorBody: String = "#efe6d4"
    var colorSoft: String = "#c6bca9"

    // Fonts
    var fontTitle: String = ""
    var fontBold: String = ""
    var fontRegular: String = ""
    var fontItalic: String = ""

    // Hardcover template
    var templateFullCoverWidth: Double?
    var templateFullCoverHeight: Double?
    var templateFrontCoverWidth: Double?
    var templateFrontCoverHeight: Double?
    var templateSpineWidth: Double?
    var templateHingeWidth: Double?
    var templateWrapWidth: Double?

    // Default init (required since custom init(from:) removes the auto-generated one)
    init() {}

    // ── Coding Keys — bridge snake_case (legacy Python) and camelCase (Swift) ──

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"

        case bindingType = "binding_type"
        case interiorType = "interior_type"
        case paperType = "paper_type"
        case readingDirection = "reading_direction"

        case platformPreset = "platform_preset"
        case trimSize = "trim_size"
        case customTrimWidthInches = "custom_trim_width_inches"
        case customTrimHeightInches = "custom_trim_height_inches"
        case customSpineWidthInches = "custom_spine_width_inches"
        case customBleedInches = "custom_bleed_inches"
        case customSafeMarginInches = "custom_safe_margin_inches"

        case pageCount = "page_count"

        case uiUnits = "ui_units"
        case guideXOffsetInches = "guide_x_offset_inches"

        case frontCoverImage = "front_cover_image"
        case frontCoverImageCentered = "front_cover_image_centered"
        case frontCoverImageOffsetXInches = "front_cover_image_offset_x_inches"
        case frontCoverImageOffsetYInches = "front_cover_image_offset_y_inches"

        case title, subtitle
        case frontText = "front_text"
        case authorName = "author_name"
        case frontTitleOffsetXInches = "front_title_offset_x_inches"
        case frontTitleOffsetYInches = "front_title_offset_y_inches"
        case frontTitleScale = "front_title_scale"
        case frontSubtitleOffsetXInches = "front_subtitle_offset_x_inches"
        case frontSubtitleOffsetYInches = "front_subtitle_offset_y_inches"
        case frontAuthorOffsetXInches = "front_author_offset_x_inches"
        case frontAuthorOffsetYInches = "front_author_offset_y_inches"
        case frontAuthorScale = "front_author_scale"

        // Binding-specific CodingKeys for legacy hc_ prefixed fields
        case hcFrontImageOffsetXInches = "hc_front_image_offset_x_inches"
        case hcFrontImageOffsetYInches = "hc_front_image_offset_y_inches"
        case hcFrontTitleOffsetXInches = "hc_front_title_offset_x_inches"
        case hcFrontTitleOffsetYInches = "hc_front_title_offset_y_inches"
        case hcFrontSubtitleOffsetXInches = "hc_front_subtitle_offset_x_inches"
        case hcFrontSubtitleOffsetYInches = "hc_front_subtitle_offset_y_inches"
        case hcFrontAuthorOffsetXInches = "hc_front_author_offset_x_inches"
        case hcFrontAuthorOffsetYInches = "hc_front_author_offset_y_inches"
        case hcFrontTitleScale = "hc_front_title_scale"
        case hcFrontAuthorScale = "hc_front_author_scale"
        case pbSpineTitleOffsetXInches = "pb_spine_title_offset_x_inches"
        case pbSpineTitleOffsetYInches = "pb_spine_title_offset_y_inches"
        case pbSpineAuthorOffsetXInches = "pb_spine_author_offset_x_inches"
        case pbSpineAuthorOffsetYInches = "pb_spine_author_offset_y_inches"
        case hcSpineTitleOffsetXInches = "hc_spine_title_offset_x_inches"
        case hcSpineTitleOffsetYInches = "hc_spine_title_offset_y_inches"
        case hcSpineAuthorOffsetXInches = "hc_spine_author_offset_x_inches"
        case hcSpineAuthorOffsetYInches = "hc_spine_author_offset_y_inches"
        case pbBackBlurbOffsetXInches = "pb_back_blurb_offset_x_inches"
        case pbBackBlurbOffsetYInches = "pb_back_blurb_offset_y_inches"
        case hcBackBlurbOffsetXInches = "hc_back_blurb_offset_x_inches"
        case hcBackBlurbOffsetYInches = "hc_back_blurb_offset_y_inches"
        case pbBackQuoteOffsetXInches = "pb_back_quote_offset_x_inches"
        case pbBackQuoteOffsetYInches = "pb_back_quote_offset_y_inches"
        case hcBackQuoteOffsetXInches = "hc_back_quote_offset_x_inches"
        case hcBackQuoteOffsetYInches = "hc_back_quote_offset_y_inches"
        case pbBackAuthorBioOffsetXInches = "pb_back_author_bio_offset_x_inches"
        case pbBackAuthorBioOffsetYInches = "pb_back_author_bio_offset_y_inches"
        case hcBackAuthorBioOffsetXInches = "hc_back_author_bio_offset_x_inches"
        case hcBackAuthorBioOffsetYInches = "hc_back_author_bio_offset_y_inches"
        case backAuthorBioOffsetYInches = "back_author_bio_offset_y_inches"
        case pbBackAuthorImageOffsetXInches = "pb_back_author_image_offset_x_inches"
        case pbBackAuthorImageOffsetYInches = "pb_back_author_image_offset_y_inches"
        case hcBackAuthorImageOffsetXInches = "hc_back_author_image_offset_x_inches"
        case hcBackAuthorImageOffsetYInches = "hc_back_author_image_offset_y_inches"
        case backAuthorImageOffsetXInches = "back_author_image_offset_x_inches"
        case backAuthorImageOffsetYInches = "back_author_image_offset_y_inches"

        case spineText = "spine_text"
        case spineColor = "spine_color"
        case spineTextOffsetInches = "spine_text_offset_inches"
        case spineColorExtensionInches = "spine_color_extension_inches"
        case spineTitleOffsetXInches = "spine_title_offset_x_inches"
        case spineTitleOffsetYInches = "spine_title_offset_y_inches"
        case spineAuthorOffsetXInches = "spine_author_offset_x_inches"
        case spineAuthorOffsetYInches = "spine_author_offset_y_inches"

        case blurb
        case blurbOffsetXInches = "blurb_offset_x_inches"
        case blurbOffsetYInches = "blurb_offset_y_inches"
        case quote
        case quoteAttribution = "quote_attribution"
        case quoteOffsetXInches = "quote_offset_x_inches"
        case quoteOffsetYInches = "quote_offset_y_inches"
        case quoteAttributionOffsetXInches = "quote_attribution_offset_x_inches"
        case quoteAttributionOffsetYInches = "quote_attribution_offset_y_inches"
        case authorBio = "author_bio"
        case authorBioOffsetXInches = "author_bio_offset_x_inches"
        case authorBioOffsetYInches = "author_bio_offset_y_inches"
        case authorBioParagraphGapPoints = "author_bio_paragraph_gap_points"

        case authorPhoto = "author_photo"
        case authorPhotoScaleInches = "author_photo_scale_inches"
        case authorPhotoOffsetXInches = "author_photo_offset_x_inches"
        case authorPhotoOffsetYInches = "author_photo_offset_y_inches"

        case colorTitle = "color_title"
        case colorAccent = "color_accent"
        case colorBody = "color_body"
        case colorSoft = "color_soft"

        case fontTitle = "font_title"
        case fontBold = "font_bold"
        case fontRegular = "font_regular"
        case fontItalic = "font_italic"

        case templateFullCoverWidth = "template_full_cover_width"
        case templateFullCoverHeight = "template_full_cover_height"
        case templateFrontCoverWidth = "template_front_cover_width"
        case templateFrontCoverHeight = "template_front_cover_height"
        case templateSpineWidth = "template_spine_width"
        case templateHingeWidth = "template_hinge_width"
        case templateWrapWidth = "template_wrap_width"
    }

    // ── Custom Decoding: handle trimSize enum, binding-specific overrides ──

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1

        bindingType = try container.decodeIfPresent(BindingType.self, forKey: .bindingType) ?? .pb
        interiorType = try container.decodeIfPresent(InteriorType.self, forKey: .interiorType) ?? .blackWhite
        paperType = try container.decodeIfPresent(PaperType.self, forKey: .paperType) ?? .white
        readingDirection = try container.decodeIfPresent(ReadingDirection.self, forKey: .readingDirection) ?? .ltr

        platformPreset = try container.decodeIfPresent(Bool.self, forKey: .platformPreset) ?? true
        trimSize = try container.decodeTrimPreset(forKey: .trimSize) ?? .sixX9
        customTrimWidthInches = container.doubleOrZero(.customTrimWidthInches)
        customTrimHeightInches = container.doubleOrZero(.customTrimHeightInches)
        customSpineWidthInches = container.doubleOrZero(.customSpineWidthInches)
        customBleedInches = container.doubleOrZero(.customBleedInches)
        customSafeMarginInches = container.doubleOrZero(.customSafeMarginInches)

        pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount) ?? 200

        uiUnits = try container.decodeIfPresent(Units.self, forKey: .uiUnits) ?? .inches
        guideXOffsetInches = container.doubleOrZero(.guideXOffsetInches)

        frontCoverImage = container.stringOrEmpty(.frontCoverImage)
        frontCoverImageCentered = container.boolOrFalse(.frontCoverImageCentered)
        frontCoverImageOffsetXInches = container.doubleOrZero(.frontCoverImageOffsetXInches)
        frontCoverImageOffsetYInches = container.doubleOrZero(.frontCoverImageOffsetYInches)

        frontText = container.boolOrTrue(.frontText)
        title = container.stringOrEmpty(.title)
        subtitle = container.stringOrEmpty(.subtitle)
        authorName = container.stringOrEmpty(.authorName)
        frontTitleOffsetXInches = container.doubleOrZero(.frontTitleOffsetXInches)
        frontTitleOffsetYInches = container.doubleOrZero(.frontTitleOffsetYInches)
        frontTitleScale = container.doubleOrOne(.frontTitleScale)
        frontSubtitleOffsetXInches = container.doubleOrZero(.frontSubtitleOffsetXInches)
        frontSubtitleOffsetYInches = container.doubleOrZero(.frontSubtitleOffsetYInches)
        frontAuthorOffsetXInches = container.doubleOrZero(.frontAuthorOffsetXInches)
        frontAuthorOffsetYInches = container.doubleOrZero(.frontAuthorOffsetYInches)
        frontAuthorScale = container.doubleOrOne(.frontAuthorScale)

        hcFrontImageOffsetXInches = container.doubleOrZero(.hcFrontImageOffsetXInches)
        hcFrontImageOffsetYInches = container.doubleOrZero(.hcFrontImageOffsetYInches)
        hcFrontTitleOffsetXInches = container.doubleOrZero(.hcFrontTitleOffsetXInches)
        hcFrontTitleOffsetYInches = container.doubleOrZero(.hcFrontTitleOffsetYInches)
        hcFrontSubtitleOffsetXInches = container.doubleOrZero(.hcFrontSubtitleOffsetXInches)
        hcFrontSubtitleOffsetYInches = container.doubleOrZero(.hcFrontSubtitleOffsetYInches)
        hcFrontAuthorOffsetXInches = container.doubleOrZero(.hcFrontAuthorOffsetXInches)
        hcFrontAuthorOffsetYInches = container.doubleOrZero(.hcFrontAuthorOffsetYInches)
        hcFrontTitleScale = container.doubleOrOne(.hcFrontTitleScale)
        hcFrontAuthorScale = container.doubleOrOne(.hcFrontAuthorScale)

        spineText = container.boolOrTrue(.spineText)
        spineColor = container.stringOrAuto(.spineColor)
        spineTextOffsetInches = container.doubleOrZero(.spineTextOffsetInches)
        spineColorExtensionInches = container.doubleOrZero(.spineColorExtensionInches)
        spineTitleOffsetXInches = container.bindingDouble(
            canonical: .spineTitleOffsetXInches,
            paperback: .pbSpineTitleOffsetXInches,
            hardcover: .hcSpineTitleOffsetXInches,
            bindingType: bindingType
        )
        spineTitleOffsetYInches = container.bindingDouble(
            canonical: .spineTitleOffsetYInches,
            paperback: .pbSpineTitleOffsetYInches,
            hardcover: .hcSpineTitleOffsetYInches,
            bindingType: bindingType
        )
        spineAuthorOffsetXInches = container.bindingDouble(
            canonical: .spineAuthorOffsetXInches,
            paperback: .pbSpineAuthorOffsetXInches,
            hardcover: .hcSpineAuthorOffsetXInches,
            bindingType: bindingType
        )
        spineAuthorOffsetYInches = container.bindingDouble(
            canonical: .spineAuthorOffsetYInches,
            paperback: .pbSpineAuthorOffsetYInches,
            hardcover: .hcSpineAuthorOffsetYInches,
            bindingType: bindingType
        )

        blurb = container.stringOrEmpty(.blurb)
        blurbOffsetXInches = container.bindingDouble(
            canonical: .blurbOffsetXInches,
            paperback: .pbBackBlurbOffsetXInches,
            hardcover: .hcBackBlurbOffsetXInches,
            bindingType: bindingType
        )
        blurbOffsetYInches = container.bindingDouble(
            canonical: .blurbOffsetYInches,
            paperback: .pbBackBlurbOffsetYInches,
            hardcover: .hcBackBlurbOffsetYInches,
            bindingType: bindingType
        )
        quote = container.stringOrEmpty(.quote)
        quoteAttribution = container.stringOrEmpty(.quoteAttribution)
        quoteOffsetXInches = container.bindingDouble(
            canonical: .quoteOffsetXInches,
            paperback: .pbBackQuoteOffsetXInches,
            hardcover: .hcBackQuoteOffsetXInches,
            bindingType: bindingType
        )
        quoteOffsetYInches = container.bindingDouble(
            canonical: .quoteOffsetYInches,
            paperback: .pbBackQuoteOffsetYInches,
            hardcover: .hcBackQuoteOffsetYInches,
            bindingType: bindingType
        )
        quoteAttributionOffsetXInches = container.doubleOrZero(.quoteAttributionOffsetXInches)
        quoteAttributionOffsetYInches = container.doubleOrZero(.quoteAttributionOffsetYInches)
        authorBio = container.stringOrEmpty(.authorBio)
        authorBioOffsetXInches = container.bindingDouble(
            canonical: .authorBioOffsetXInches,
            paperback: .pbBackAuthorBioOffsetXInches,
            hardcover: .hcBackAuthorBioOffsetXInches,
            bindingType: bindingType
        )
        authorBioOffsetYInches = container.bindingDouble(
            canonical: .authorBioOffsetYInches,
            paperback: .pbBackAuthorBioOffsetYInches,
            hardcover: .hcBackAuthorBioOffsetYInches,
            bindingType: bindingType,
            fallback: .backAuthorBioOffsetYInches
        )
        authorBioParagraphGapPoints = container.doubleOrZero(.authorBioParagraphGapPoints)

        authorPhoto = container.stringOrEmpty(.authorPhoto)
        authorPhotoScaleInches = container.doubleOrZero(.authorPhotoScaleInches)
        authorPhotoOffsetXInches = container.bindingDouble(
            canonical: .authorPhotoOffsetXInches,
            paperback: .pbBackAuthorImageOffsetXInches,
            hardcover: .hcBackAuthorImageOffsetXInches,
            bindingType: bindingType,
            fallback: .backAuthorImageOffsetXInches
        )
        authorPhotoOffsetYInches = container.bindingDouble(
            canonical: .authorPhotoOffsetYInches,
            paperback: .pbBackAuthorImageOffsetYInches,
            hardcover: .hcBackAuthorImageOffsetYInches,
            bindingType: bindingType,
            fallback: .backAuthorImageOffsetYInches
        )

        colorTitle = container.stringOrEmpty(.colorTitle)
        colorAccent = container.stringOrEmpty(.colorAccent)
        colorBody = container.stringOrEmpty(.colorBody)
        colorSoft = container.stringOrEmpty(.colorSoft)

        fontTitle = container.stringOrEmpty(.fontTitle)
        fontBold = container.stringOrEmpty(.fontBold)
        fontRegular = container.stringOrEmpty(.fontRegular)
        fontItalic = container.stringOrEmpty(.fontItalic)

        templateFullCoverWidth = try container.decodeIfPresent(Double.self, forKey: .templateFullCoverWidth)
        templateFullCoverHeight = try container.decodeIfPresent(Double.self, forKey: .templateFullCoverHeight)
        templateFrontCoverWidth = try container.decodeIfPresent(Double.self, forKey: .templateFrontCoverWidth)
        templateFrontCoverHeight = try container.decodeIfPresent(Double.self, forKey: .templateFrontCoverHeight)
        templateSpineWidth = try container.decodeIfPresent(Double.self, forKey: .templateSpineWidth)
        templateHingeWidth = try container.decodeIfPresent(Double.self, forKey: .templateHingeWidth)
        templateWrapWidth = try container.decodeIfPresent(Double.self, forKey: .templateWrapWidth)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(bindingType, forKey: .bindingType)
        try container.encode(interiorType, forKey: .interiorType)
        try container.encode(paperType, forKey: .paperType)
        try container.encode(readingDirection, forKey: .readingDirection)
        try container.encode(platformPreset, forKey: .platformPreset)
        try container.encode(trimSize, forKey: .trimSize)
        try container.encode(customTrimWidthInches, forKey: .customTrimWidthInches)
        try container.encode(customTrimHeightInches, forKey: .customTrimHeightInches)
        try container.encode(customSpineWidthInches, forKey: .customSpineWidthInches)
        try container.encode(customBleedInches, forKey: .customBleedInches)
        try container.encode(customSafeMarginInches, forKey: .customSafeMarginInches)
        try container.encode(pageCount, forKey: .pageCount)
        try container.encode(uiUnits, forKey: .uiUnits)
        try container.encode(guideXOffsetInches, forKey: .guideXOffsetInches)
        try container.encode(frontCoverImage, forKey: .frontCoverImage)
        try container.encode(frontCoverImageCentered, forKey: .frontCoverImageCentered)
        try container.encode(frontCoverImageOffsetXInches, forKey: .frontCoverImageOffsetXInches)
        try container.encode(frontCoverImageOffsetYInches, forKey: .frontCoverImageOffsetYInches)
        try container.encode(frontText, forKey: .frontText)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(authorName, forKey: .authorName)
        try container.encode(frontTitleOffsetXInches, forKey: .frontTitleOffsetXInches)
        try container.encode(frontTitleOffsetYInches, forKey: .frontTitleOffsetYInches)
        try container.encode(frontTitleScale, forKey: .frontTitleScale)
        try container.encode(frontSubtitleOffsetXInches, forKey: .frontSubtitleOffsetXInches)
        try container.encode(frontSubtitleOffsetYInches, forKey: .frontSubtitleOffsetYInches)
        try container.encode(frontAuthorOffsetXInches, forKey: .frontAuthorOffsetXInches)
        try container.encode(frontAuthorOffsetYInches, forKey: .frontAuthorOffsetYInches)
        try container.encode(frontAuthorScale, forKey: .frontAuthorScale)
        try container.encode(spineText, forKey: .spineText)
        try container.encode(spineColor, forKey: .spineColor)
        try container.encode(spineTextOffsetInches, forKey: .spineTextOffsetInches)
        try container.encode(spineColorExtensionInches, forKey: .spineColorExtensionInches)
        try container.encode(spineTitleOffsetXInches, forKey: .spineTitleOffsetXInches)
        try container.encode(spineTitleOffsetYInches, forKey: .spineTitleOffsetYInches)
        try container.encode(spineAuthorOffsetXInches, forKey: .spineAuthorOffsetXInches)
        try container.encode(spineAuthorOffsetYInches, forKey: .spineAuthorOffsetYInches)
        try container.encode(blurb, forKey: .blurb)
        try container.encode(blurbOffsetXInches, forKey: .blurbOffsetXInches)
        try container.encode(blurbOffsetYInches, forKey: .blurbOffsetYInches)
        try container.encode(quote, forKey: .quote)
        try container.encode(quoteAttribution, forKey: .quoteAttribution)
        try container.encode(quoteOffsetXInches, forKey: .quoteOffsetXInches)
        try container.encode(quoteOffsetYInches, forKey: .quoteOffsetYInches)
        try container.encode(quoteAttributionOffsetXInches, forKey: .quoteAttributionOffsetXInches)
        try container.encode(quoteAttributionOffsetYInches, forKey: .quoteAttributionOffsetYInches)
        try container.encode(authorBio, forKey: .authorBio)
        try container.encode(authorBioOffsetXInches, forKey: .authorBioOffsetXInches)
        try container.encode(authorBioOffsetYInches, forKey: .authorBioOffsetYInches)
        try container.encode(authorBioParagraphGapPoints, forKey: .authorBioParagraphGapPoints)
        try container.encode(authorPhoto, forKey: .authorPhoto)
        try container.encode(authorPhotoScaleInches, forKey: .authorPhotoScaleInches)
        try container.encode(authorPhotoOffsetXInches, forKey: .authorPhotoOffsetXInches)
        try container.encode(authorPhotoOffsetYInches, forKey: .authorPhotoOffsetYInches)
        try container.encode(colorTitle, forKey: .colorTitle)
        try container.encode(colorAccent, forKey: .colorAccent)
        try container.encode(colorBody, forKey: .colorBody)
        try container.encode(colorSoft, forKey: .colorSoft)
        try container.encode(fontTitle, forKey: .fontTitle)
        try container.encode(fontBold, forKey: .fontBold)
        try container.encode(fontRegular, forKey: .fontRegular)
        try container.encode(fontItalic, forKey: .fontItalic)
        try container.encodeIfPresent(templateFullCoverWidth, forKey: .templateFullCoverWidth)
        try container.encodeIfPresent(templateFullCoverHeight, forKey: .templateFullCoverHeight)
        try container.encodeIfPresent(templateFrontCoverWidth, forKey: .templateFrontCoverWidth)
        try container.encodeIfPresent(templateFrontCoverHeight, forKey: .templateFrontCoverHeight)
        try container.encodeIfPresent(templateSpineWidth, forKey: .templateSpineWidth)
        try container.encodeIfPresent(templateHingeWidth, forKey: .templateHingeWidth)
        try container.encodeIfPresent(templateWrapWidth, forKey: .templateWrapWidth)
    }
}

// ── KeyedDecodingContainer helpers ──────────────────────────────

extension KeyedDecodingContainer where Key == CoverData.CodingKeys {
    func doubleOrZero(_ key: Key) -> Double {
        if let d = try? decodeIfPresent(Double.self, forKey: key) { return d }
        if let s = try? decodeIfPresent(String.self, forKey: key), let d = Double(s) { return d }
        return 0.0
    }

    func doubleOrOne(_ key: Key) -> Double {
        let v = doubleOrZero(key)
        return v == 0.0 ? 1.0 : v
    }

    func stringOrEmpty(_ key: Key) -> String {
        (try? decodeIfPresent(String.self, forKey: key)) ?? ""
    }

    func stringOrAuto(_ key: Key) -> String {
        let s = stringOrEmpty(key)
        return s.isEmpty ? "auto" : s
    }

    func boolOrFalse(_ key: Key) -> Bool {
        (try? decodeIfPresent(Bool.self, forKey: key)) ?? false
    }

    func boolOrTrue(_ key: Key) -> Bool {
        if let b = try? decodeIfPresent(Bool.self, forKey: key) { return b }
        return true
    }

    func decodeTrimPreset(forKey key: Key) throws -> TrimPreset? {
        guard contains(key) else { return nil }
        if let preset = try? decode(TrimPreset.self, forKey: key) { return preset }
        if let raw = try? decode(String.self, forKey: key) {
            return TrimPreset(fromLegacyString: raw)
        }
        return nil
    }

    func bindingDouble(
        canonical: Key,
        paperback: Key,
        hardcover: Key,
        bindingType: BindingType,
        fallback: Key? = nil
    ) -> Double {
        let bindingKey = bindingType == .hc ? hardcover : paperback
        if contains(bindingKey) {
            return doubleOrZero(bindingKey)
        }
        if contains(canonical) {
            return doubleOrZero(canonical)
        }
        if let fallback, contains(fallback) {
            return doubleOrZero(fallback)
        }
        return 0.0
    }
}

extension TrimPreset {
    init(fromLegacyString raw: String) {
        let cleaned = raw.trimmingCharacters(in: .whitespaces).lowercased()
        switch cleaned {
        case "5x7.4", "5x7_4": self = .fiveX7_4
        case "5x8": self = .fiveX8
        case "5.06x7.81": self = .five06X7_81
        case "5.25x8": self = .five25X8
        case "5.5x8.5": self = .five5X8_5
        case "6x9": self = .sixX9
        case "6.14x9.21": self = .six14X9_21
        case "6.69x9.61": self = .six69X9_61
        case "7x10": self = .sevenX10
        case "7.44x9.69": self = .seven44X9_69
        case "7.5x9.25": self = .seven5X9_25
        case "8x10": self = .eightX10
        case "8.25x6": self = .eight25X6
        case "8.25x8.25": self = .eight25X8_25
        case "8.27x11.69": self = .eight27X11_69
        case "8.5x8.5": self = .eight5X8_5
        case "8.5x11": self = .eight5X11
        case "custom": self = .custom
        default: self = .custom
        }
    }
}
