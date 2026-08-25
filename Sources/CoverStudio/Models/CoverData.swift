import Foundation
import Yams

let currentSchemaVersion = 2

struct CoverData: Codable, Equatable {
    var schemaVersion: Int = currentSchemaVersion

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
    var pbPageCount: Int = 200
    var hcPageCount: Int = 200

    // UI
    var uiUnits: Units = .inches
    var guideXOffsetInches: Double = 0.0

    func resolvedPageCount() -> Int {
        bindingType == .hc ? hcPageCount : pbPageCount
    }

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
    var frontTitleCenterX: Bool = false
    var frontTitleCenterY: Bool = false
    var frontTitleScale: Double = 1.0
    var frontSubtitleOffsetXInches: Double = 0.0
    var frontSubtitleOffsetYInches: Double = 0.0
    var frontSubtitleCenterX: Bool = false
    var frontSubtitleCenterY: Bool = false
    var frontSubtitleScale: Double = 1.0
    var frontAuthorOffsetXInches: Double = 0.0
    var frontAuthorOffsetYInches: Double = 0.0
    var frontAuthorCenterX: Bool = false
    var frontAuthorCenterY: Bool = false
    var frontAuthorScale: Double = 1.0

    // Binding-specific overrides (hc_ prefixed keys in legacy cover.md)
    var hcFrontImageOffsetXInches: Double = 0.0
    var hcFrontImageOffsetYInches: Double = 0.0
    var hcFrontTitleOffsetXInches: Double = 0.0
    var hcFrontTitleOffsetYInches: Double = 0.0
    var hcFrontTitleCenterX: Bool = false
    var hcFrontTitleCenterY: Bool = false
    var hcFrontSubtitleOffsetXInches: Double = 0.0
    var hcFrontSubtitleOffsetYInches: Double = 0.0
    var hcFrontSubtitleCenterX: Bool = false
    var hcFrontSubtitleCenterY: Bool = false
    var hcFrontAuthorOffsetXInches: Double = 0.0
    var hcFrontAuthorOffsetYInches: Double = 0.0
    var hcFrontAuthorCenterX: Bool = false
    var hcFrontAuthorCenterY: Bool = false
    var hcFrontTitleScale: Double = 1.0
    var hcFrontSubtitleScale: Double = 1.0
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
    func resolvedTitleCenterX() -> Bool {
        if bindingType == .hc { return hcFrontTitleCenterX }
        return frontTitleCenterX
    }
    func resolvedTitleCenterY() -> Bool {
        if bindingType == .hc { return hcFrontTitleCenterY }
        return frontTitleCenterY
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
    func resolvedAuthorCenterX() -> Bool {
        if bindingType == .hc { return hcFrontAuthorCenterX }
        return frontAuthorCenterX
    }
    func resolvedAuthorCenterY() -> Bool {
        if bindingType == .hc { return hcFrontAuthorCenterY }
        return frontAuthorCenterY
    }
    func resolvedSubtitleOffsetX() -> Double {
        if bindingType == .hc { return hcFrontSubtitleOffsetXInches }
        return frontSubtitleOffsetXInches
    }
    func resolvedSubtitleOffsetY() -> Double {
        if bindingType == .hc { return hcFrontSubtitleOffsetYInches }
        return frontSubtitleOffsetYInches
    }
    func resolvedSubtitleScale() -> Double {
        if bindingType == .hc { return hcFrontSubtitleScale }
        return frontSubtitleScale
    }
    func resolvedSubtitleCenterX() -> Bool {
        if bindingType == .hc { return hcFrontSubtitleCenterX }
        return frontSubtitleCenterX
    }
    func resolvedSubtitleCenterY() -> Bool {
        if bindingType == .hc { return hcFrontSubtitleCenterY }
        return frontSubtitleCenterY
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
    var spineColorExtensionInches: Double = CoverLayoutDefaults.spineColorExtensionInches
    var spineTitleOffsetXInches: Double = 0.0
    var spineTitleOffsetYInches: Double = 0.0
    var spineAuthorOffsetXInches: Double = 0.0
    var spineAuthorOffsetYInches: Double = 0.0

    // Back cover — text
    var blurb: String = ""
    var blurbOffsetXInches: Double = 0.0
    var blurbOffsetYInches: Double = 0.0
    var blurbWidthInches: Double = 0.0
    var quote: String = ""
    var quoteAttribution: String = ""
    var quoteOffsetXInches: Double = 0.0
    var quoteOffsetYInches: Double = 0.0
    var quoteAttributionOffsetXInches: Double = 0.0
    var quoteAttributionOffsetYInches: Double = 0.0
    var authorBio: String = ""
    var authorBioOffsetXInches: Double = 0.0
    var authorBioOffsetYInches: Double = 0.0
    var authorBioWidthInches: Double = 0.0
    var authorBioParagraphGapPoints: Double = CoverLayoutDefaults.backAuthorBioParagraphGapPoints

    // Back cover — image
    var authorPhoto: String = ""
    var authorPhotoScaleInches: Double = CoverLayoutDefaults.backAuthorPhotoSizeInches
    var authorPhotoOffsetXInches: Double = 0.0
    var authorPhotoOffsetYInches: Double = 0.0
    var authorPhotoShape: AuthorPhotoShape = .circle
    var authorPhotoCropOffsetX: Double = 0.0  // -1…+1, shifts crop window left/right within source image
    var authorPhotoCropOffsetY: Double = 0.0  // -1…+1, shifts crop window up/down within source image

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

    mutating func applyDefaultLocations() {
        frontCoverImageOffsetXInches = 0.0
        frontCoverImageOffsetYInches = 0.0
        frontTitleOffsetXInches = 0.0
        frontTitleOffsetYInches = 0.0
        frontTitleCenterX = false
        frontTitleCenterY = false
        frontTitleScale = 1.0
        frontSubtitleOffsetXInches = 0.0
        frontSubtitleOffsetYInches = 0.0
        frontSubtitleCenterX = false
        frontSubtitleCenterY = false
        frontSubtitleScale = 1.0
        frontAuthorOffsetXInches = 0.0
        frontAuthorOffsetYInches = 0.0
        frontAuthorCenterX = false
        frontAuthorCenterY = false
        frontAuthorScale = 1.0

        hcFrontImageOffsetXInches = 0.0
        hcFrontImageOffsetYInches = 0.0
        hcFrontTitleOffsetXInches = 0.0
        hcFrontTitleOffsetYInches = 0.0
        hcFrontTitleCenterX = false
        hcFrontTitleCenterY = false
        hcFrontSubtitleOffsetXInches = 0.0
        hcFrontSubtitleOffsetYInches = 0.0
        hcFrontSubtitleCenterX = false
        hcFrontSubtitleCenterY = false
        hcFrontAuthorOffsetXInches = 0.0
        hcFrontAuthorOffsetYInches = 0.0
        hcFrontAuthorCenterX = false
        hcFrontAuthorCenterY = false
        hcFrontTitleScale = 1.0
        hcFrontSubtitleScale = 1.0
        hcFrontAuthorScale = 1.0

        spineTextOffsetInches = 0.0
        spineColorExtensionInches = CoverLayoutDefaults.spineColorExtensionInches
        spineTitleOffsetXInches = 0.0
        spineTitleOffsetYInches = 0.0
        spineAuthorOffsetXInches = 0.0
        spineAuthorOffsetYInches = 0.0

        blurbOffsetXInches = 0.0
        blurbOffsetYInches = 0.0
        blurbWidthInches = 0.0
        quoteOffsetXInches = 0.0
        quoteOffsetYInches = 0.0
        quoteAttributionOffsetXInches = 0.0
        quoteAttributionOffsetYInches = 0.0
        authorBioOffsetXInches = 0.0
        authorBioOffsetYInches = 0.0
        authorBioWidthInches = 0.0
        authorBioParagraphGapPoints = CoverLayoutDefaults.backAuthorBioParagraphGapPoints
        authorPhotoScaleInches = CoverLayoutDefaults.backAuthorPhotoSizeInches
        authorPhotoOffsetXInches = 0.0
        authorPhotoOffsetYInches = 0.0
        authorPhotoCropOffsetX = 0.0
        authorPhotoCropOffsetY = 0.0
    }

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
        case pbPageCount = "pb_page_count"
        case hcPageCount = "hc_page_count"

        case uiUnits = "ui_units"
        case guideXOffsetInches = "guide_x_offset_inches"

        case frontCoverImage = "front_cover_image"
        case frontCoverImageCentered = "front_cover_image_centered"
        case frontCoverImageOffsetXInches = "front_cover_image_offset_x_inches"
        case frontCoverImageOffsetYInches = "front_cover_image_offset_y_inches"
        case pbFrontImageOffsetXInches = "pb_front_image_offset_x_inches"
        case pbFrontImageOffsetYInches = "pb_front_image_offset_y_inches"

        case title, subtitle
        case frontText = "front_text"
        case authorName = "author_name"
        case frontTitleOffsetXInches = "front_title_offset_x_inches"
        case frontTitleOffsetYInches = "front_title_offset_y_inches"
        case frontTitleCenterX = "front_title_center_x"
        case frontTitleCenterY = "front_title_center_y"
        case frontTitleCentered = "front_title_centered"
        case frontTitleScale = "front_title_scale"
        case frontSubtitleOffsetXInches = "front_subtitle_offset_x_inches"
        case frontSubtitleOffsetYInches = "front_subtitle_offset_y_inches"
        case frontSubtitleCenterX = "front_subtitle_center_x"
        case frontSubtitleCenterY = "front_subtitle_center_y"
        case frontSubtitleCentered = "front_subtitle_centered"
        case frontSubtitleScale = "front_subtitle_scale"
        case frontAuthorOffsetXInches = "front_author_offset_x_inches"
        case frontAuthorOffsetYInches = "front_author_offset_y_inches"
        case frontAuthorCenterX = "front_author_center_x"
        case frontAuthorCenterY = "front_author_center_y"
        case frontAuthorCentered = "front_author_centered"
        case frontAuthorScale = "front_author_scale"
        case pbFrontTitleOffsetXInches = "pb_front_title_offset_x_inches"
        case pbFrontTitleOffsetYInches = "pb_front_title_offset_y_inches"
        case pbFrontTitleCenterX = "pb_front_title_center_x"
        case pbFrontTitleCenterY = "pb_front_title_center_y"
        case pbFrontTitleCentered = "pb_front_title_centered"
        case pbFrontSubtitleOffsetXInches = "pb_front_subtitle_offset_x_inches"
        case pbFrontSubtitleOffsetYInches = "pb_front_subtitle_offset_y_inches"
        case pbFrontSubtitleCenterX = "pb_front_subtitle_center_x"
        case pbFrontSubtitleCenterY = "pb_front_subtitle_center_y"
        case pbFrontSubtitleCentered = "pb_front_subtitle_centered"
        case pbFrontSubtitleScale = "pb_front_subtitle_scale"
        case pbFrontAuthorOffsetXInches = "pb_front_author_offset_x_inches"
        case pbFrontAuthorOffsetYInches = "pb_front_author_offset_y_inches"
        case pbFrontAuthorCenterX = "pb_front_author_center_x"
        case pbFrontAuthorCenterY = "pb_front_author_center_y"
        case pbFrontAuthorCentered = "pb_front_author_centered"

        // Binding-specific CodingKeys for legacy hc_ prefixed fields
        case hcFrontImageOffsetXInches = "hc_front_image_offset_x_inches"
        case hcFrontImageOffsetYInches = "hc_front_image_offset_y_inches"
        case hcFrontTitleOffsetXInches = "hc_front_title_offset_x_inches"
        case hcFrontTitleOffsetYInches = "hc_front_title_offset_y_inches"
        case hcFrontTitleCenterX = "hc_front_title_center_x"
        case hcFrontTitleCenterY = "hc_front_title_center_y"
        case hcFrontTitleCentered = "hc_front_title_centered"
        case hcFrontSubtitleOffsetXInches = "hc_front_subtitle_offset_x_inches"
        case hcFrontSubtitleOffsetYInches = "hc_front_subtitle_offset_y_inches"
        case hcFrontSubtitleCenterX = "hc_front_subtitle_center_x"
        case hcFrontSubtitleCenterY = "hc_front_subtitle_center_y"
        case hcFrontSubtitleCentered = "hc_front_subtitle_centered"
        case hcFrontAuthorOffsetXInches = "hc_front_author_offset_x_inches"
        case hcFrontAuthorOffsetYInches = "hc_front_author_offset_y_inches"
        case hcFrontAuthorCenterX = "hc_front_author_center_x"
        case hcFrontAuthorCenterY = "hc_front_author_center_y"
        case hcFrontAuthorCentered = "hc_front_author_centered"
        case hcFrontTitleScale = "hc_front_title_scale"
        case hcFrontSubtitleScale = "hc_front_subtitle_scale"
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
        case blurbWidthInches = "blurb_width_inches"
        case pbBackBlurbWidthInches = "pb_back_blurb_width_inches"
        case hcBackBlurbWidthInches = "hc_back_blurb_width_inches"
        case pbBackQuoteOffsetXInches = "pb_back_quote_offset_x_inches"
        case pbBackQuoteOffsetYInches = "pb_back_quote_offset_y_inches"
        case hcBackQuoteOffsetXInches = "hc_back_quote_offset_x_inches"
        case hcBackQuoteOffsetYInches = "hc_back_quote_offset_y_inches"
        case pbBackAuthorBioOffsetXInches = "pb_back_author_bio_offset_x_inches"
        case pbBackAuthorBioOffsetYInches = "pb_back_author_bio_offset_y_inches"
        case hcBackAuthorBioOffsetXInches = "hc_back_author_bio_offset_x_inches"
        case hcBackAuthorBioOffsetYInches = "hc_back_author_bio_offset_y_inches"
        case backAuthorBioOffsetYInches = "back_author_bio_offset_y_inches"
        case authorBioWidthInches = "author_bio_width_inches"
        case pbBackAuthorBioWidthInches = "pb_back_author_bio_width_inches"
        case hcBackAuthorBioWidthInches = "hc_back_author_bio_width_inches"
        case backAuthorBioParagraphGapPoints = "back_author_bio_paragraph_gap_points"
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
        case authorPhotoShape = "author_photo_shape"
        case authorPhotoCircular = "author_photo_circular"
        case authorPhotoCropOffsetX = "author_photo_crop_offset_x"
        case authorPhotoCropOffsetY = "author_photo_crop_offset_y"

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

        let fileSchemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        schemaVersion = currentSchemaVersion
        _ = fileSchemaVersion  // retained for future per-version migration logic

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
        pbPageCount = try container.decodeIfPresent(Int.self, forKey: .pbPageCount) ?? pageCount
        hcPageCount = try container.decodeIfPresent(Int.self, forKey: .hcPageCount) ?? pageCount

        uiUnits = try container.decodeIfPresent(Units.self, forKey: .uiUnits) ?? .inches
        guideXOffsetInches = container.doubleOrZero(.guideXOffsetInches)

        frontCoverImage = container.stringOrEmpty(.frontCoverImage)
        frontCoverImageCentered = container.boolOrFalse(.frontCoverImageCentered)
        frontCoverImageOffsetXInches = container.bindingDouble(
            canonical: .frontCoverImageOffsetXInches,
            paperback: .pbFrontImageOffsetXInches,
            hardcover: .frontCoverImageOffsetXInches,
            bindingType: .pb
        )
        frontCoverImageOffsetYInches = container.bindingDouble(
            canonical: .frontCoverImageOffsetYInches,
            paperback: .pbFrontImageOffsetYInches,
            hardcover: .frontCoverImageOffsetYInches,
            bindingType: .pb
        )

        frontText = container.boolOrTrue(.frontText)
        title = container.stringOrEmpty(.title)
        subtitle = container.stringOrEmpty(.subtitle)
        authorName = container.stringOrEmpty(.authorName)
        frontTitleOffsetXInches = container.bindingDouble(
            canonical: .frontTitleOffsetXInches,
            paperback: .pbFrontTitleOffsetXInches,
            hardcover: .frontTitleOffsetXInches,
            bindingType: .pb
        )
        frontTitleOffsetYInches = container.bindingDouble(
            canonical: .frontTitleOffsetYInches,
            paperback: .pbFrontTitleOffsetYInches,
            hardcover: .frontTitleOffsetYInches,
            bindingType: .pb
        )
        frontTitleCenterX = container.bindingBool(
            canonical: .frontTitleCenterX,
            paperback: .pbFrontTitleCenterX,
            hardcover: .frontTitleCenterX,
            bindingType: .pb,
            fallback: .frontTitleCentered
        )
        frontTitleCenterY = container.bindingBool(
            canonical: .frontTitleCenterY,
            paperback: .pbFrontTitleCenterY,
            hardcover: .frontTitleCenterY,
            bindingType: .pb,
            fallback: .frontTitleCentered
        )
        frontTitleScale = container.doubleOrOne(.frontTitleScale)
        frontSubtitleOffsetXInches = container.bindingDouble(
            canonical: .frontSubtitleOffsetXInches,
            paperback: .pbFrontSubtitleOffsetXInches,
            hardcover: .frontSubtitleOffsetXInches,
            bindingType: .pb
        )
        frontSubtitleOffsetYInches = container.bindingDouble(
            canonical: .frontSubtitleOffsetYInches,
            paperback: .pbFrontSubtitleOffsetYInches,
            hardcover: .frontSubtitleOffsetYInches,
            bindingType: .pb
        )
        frontSubtitleCenterX = container.bindingBool(
            canonical: .frontSubtitleCenterX,
            paperback: .pbFrontSubtitleCenterX,
            hardcover: .frontSubtitleCenterX,
            bindingType: .pb,
            fallback: .frontSubtitleCentered
        )
        frontSubtitleCenterY = container.bindingBool(
            canonical: .frontSubtitleCenterY,
            paperback: .pbFrontSubtitleCenterY,
            hardcover: .frontSubtitleCenterY,
            bindingType: .pb,
            fallback: .frontSubtitleCentered
        )
        frontSubtitleScale = container.bindingDoubleOrDefault(
            canonical: .frontSubtitleScale,
            paperback: .pbFrontSubtitleScale,
            hardcover: .frontSubtitleScale,
            bindingType: .pb,
            defaultValue: 1.0
        )
        frontAuthorOffsetXInches = container.bindingDouble(
            canonical: .frontAuthorOffsetXInches,
            paperback: .pbFrontAuthorOffsetXInches,
            hardcover: .frontAuthorOffsetXInches,
            bindingType: .pb
        )
        frontAuthorOffsetYInches = container.bindingDouble(
            canonical: .frontAuthorOffsetYInches,
            paperback: .pbFrontAuthorOffsetYInches,
            hardcover: .frontAuthorOffsetYInches,
            bindingType: .pb
        )
        frontAuthorCenterX = container.bindingBool(
            canonical: .frontAuthorCenterX,
            paperback: .pbFrontAuthorCenterX,
            hardcover: .frontAuthorCenterX,
            bindingType: .pb,
            fallback: .frontAuthorCentered
        )
        frontAuthorCenterY = container.bindingBool(
            canonical: .frontAuthorCenterY,
            paperback: .pbFrontAuthorCenterY,
            hardcover: .frontAuthorCenterY,
            bindingType: .pb,
            fallback: .frontAuthorCentered
        )
        frontAuthorScale = container.doubleOrOne(.frontAuthorScale)

        hcFrontImageOffsetXInches = container.doubleOrZero(.hcFrontImageOffsetXInches)
        hcFrontImageOffsetYInches = container.doubleOrZero(.hcFrontImageOffsetYInches)
        hcFrontTitleOffsetXInches = container.doubleOrZero(.hcFrontTitleOffsetXInches)
        hcFrontTitleOffsetYInches = container.doubleOrZero(.hcFrontTitleOffsetYInches)
        hcFrontTitleCenterX = container.boolOrDefault(.hcFrontTitleCenterX, defaultValue: container.boolOrDefault(.hcFrontTitleCentered, defaultValue: false))
        hcFrontTitleCenterY = container.boolOrDefault(.hcFrontTitleCenterY, defaultValue: container.boolOrDefault(.hcFrontTitleCentered, defaultValue: false))
        hcFrontSubtitleOffsetXInches = container.doubleOrZero(.hcFrontSubtitleOffsetXInches)
        hcFrontSubtitleOffsetYInches = container.doubleOrZero(.hcFrontSubtitleOffsetYInches)
        hcFrontSubtitleCenterX = container.boolOrDefault(.hcFrontSubtitleCenterX, defaultValue: container.boolOrDefault(.hcFrontSubtitleCentered, defaultValue: false))
        hcFrontSubtitleCenterY = container.boolOrDefault(.hcFrontSubtitleCenterY, defaultValue: container.boolOrDefault(.hcFrontSubtitleCentered, defaultValue: false))
        hcFrontAuthorOffsetXInches = container.doubleOrZero(.hcFrontAuthorOffsetXInches)
        hcFrontAuthorOffsetYInches = container.doubleOrZero(.hcFrontAuthorOffsetYInches)
        hcFrontAuthorCenterX = container.boolOrDefault(.hcFrontAuthorCenterX, defaultValue: container.boolOrDefault(.hcFrontAuthorCentered, defaultValue: false))
        hcFrontAuthorCenterY = container.boolOrDefault(.hcFrontAuthorCenterY, defaultValue: container.boolOrDefault(.hcFrontAuthorCentered, defaultValue: false))
        hcFrontTitleScale = container.doubleOrOne(.hcFrontTitleScale)
        hcFrontSubtitleScale = container.doubleOrDefault(.hcFrontSubtitleScale, defaultValue: 1.0)
        hcFrontAuthorScale = container.doubleOrOne(.hcFrontAuthorScale)

        spineText = container.boolOrTrue(.spineText)
        spineColor = container.stringOrAuto(.spineColor)
        spineTextOffsetInches = container.doubleOrZero(.spineTextOffsetInches)
        spineColorExtensionInches = container.doubleOrDefault(
            .spineColorExtensionInches,
            defaultValue: CoverLayoutDefaults.spineColorExtensionInches
        )
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
        blurbWidthInches = container.bindingDouble(
            canonical: .blurbWidthInches,
            paperback: .pbBackBlurbWidthInches,
            hardcover: .hcBackBlurbWidthInches,
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
        authorBioWidthInches = container.bindingDouble(
            canonical: .authorBioWidthInches,
            paperback: .pbBackAuthorBioWidthInches,
            hardcover: .hcBackAuthorBioWidthInches,
            bindingType: bindingType
        )
        authorBioParagraphGapPoints = container.doubleOrDefault(
            .authorBioParagraphGapPoints,
            defaultValue: container.doubleOrDefault(
                .backAuthorBioParagraphGapPoints,
                defaultValue: CoverLayoutDefaults.backAuthorBioParagraphGapPoints
            )
        )

        authorPhoto = container.stringOrEmpty(.authorPhoto)
        authorPhotoScaleInches = container.doubleOrDefault(
            .authorPhotoScaleInches,
            defaultValue: CoverLayoutDefaults.backAuthorPhotoSizeInches
        )
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
        authorPhotoShape = try container.decodeIfPresent(AuthorPhotoShape.self, forKey: .authorPhotoShape)
            ?? (container.boolOrDefault(.authorPhotoCircular, defaultValue: true) ? .circle : .square)
        authorPhotoCropOffsetX = container.doubleOrDefault(.authorPhotoCropOffsetX, defaultValue: 0.0)
        authorPhotoCropOffsetY = container.doubleOrDefault(.authorPhotoCropOffsetY, defaultValue: 0.0)

        colorTitle = container.stringOrDefault(.colorTitle, defaultValue: "#daa520")
        colorAccent = container.stringOrDefault(.colorAccent, defaultValue: "#eec448")
        colorBody = container.stringOrDefault(.colorBody, defaultValue: "#efe6d4")
        colorSoft = container.stringOrDefault(.colorSoft, defaultValue: "#c6bca9")

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
        try container.encode(resolvedPageCount(), forKey: .pageCount)
        try container.encode(pbPageCount, forKey: .pbPageCount)
        try container.encode(hcPageCount, forKey: .hcPageCount)
        try container.encode(uiUnits, forKey: .uiUnits)
        try container.encode(guideXOffsetInches, forKey: .guideXOffsetInches)
        try container.encode(frontCoverImage, forKey: .frontCoverImage)
        try container.encode(frontCoverImageCentered, forKey: .frontCoverImageCentered)
        try container.encode(frontCoverImageOffsetXInches, forKey: .frontCoverImageOffsetXInches)
        try container.encode(frontCoverImageOffsetYInches, forKey: .frontCoverImageOffsetYInches)
        try container.encode(frontCoverImageOffsetXInches, forKey: .pbFrontImageOffsetXInches)
        try container.encode(frontCoverImageOffsetYInches, forKey: .pbFrontImageOffsetYInches)
        try container.encode(hcFrontImageOffsetXInches, forKey: .hcFrontImageOffsetXInches)
        try container.encode(hcFrontImageOffsetYInches, forKey: .hcFrontImageOffsetYInches)
        try container.encode(frontText, forKey: .frontText)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(authorName, forKey: .authorName)
        try container.encode(frontTitleOffsetXInches, forKey: .frontTitleOffsetXInches)
        try container.encode(frontTitleOffsetYInches, forKey: .frontTitleOffsetYInches)
        try container.encode(frontTitleCenterX, forKey: .frontTitleCenterX)
        try container.encode(frontTitleCenterY, forKey: .frontTitleCenterY)
        try container.encode(frontTitleScale, forKey: .frontTitleScale)
        try container.encode(frontTitleOffsetXInches, forKey: .pbFrontTitleOffsetXInches)
        try container.encode(frontTitleOffsetYInches, forKey: .pbFrontTitleOffsetYInches)
        try container.encode(frontTitleCenterX, forKey: .pbFrontTitleCenterX)
        try container.encode(frontTitleCenterY, forKey: .pbFrontTitleCenterY)
        try container.encode(hcFrontTitleOffsetXInches, forKey: .hcFrontTitleOffsetXInches)
        try container.encode(hcFrontTitleOffsetYInches, forKey: .hcFrontTitleOffsetYInches)
        try container.encode(hcFrontTitleCenterX, forKey: .hcFrontTitleCenterX)
        try container.encode(hcFrontTitleCenterY, forKey: .hcFrontTitleCenterY)
        try container.encode(hcFrontTitleScale, forKey: .hcFrontTitleScale)
        try container.encode(frontSubtitleOffsetXInches, forKey: .frontSubtitleOffsetXInches)
        try container.encode(frontSubtitleOffsetYInches, forKey: .frontSubtitleOffsetYInches)
        try container.encode(frontSubtitleCenterX, forKey: .frontSubtitleCenterX)
        try container.encode(frontSubtitleCenterY, forKey: .frontSubtitleCenterY)
        try container.encode(frontSubtitleScale, forKey: .frontSubtitleScale)
        try container.encode(frontSubtitleOffsetXInches, forKey: .pbFrontSubtitleOffsetXInches)
        try container.encode(frontSubtitleOffsetYInches, forKey: .pbFrontSubtitleOffsetYInches)
        try container.encode(frontSubtitleCenterX, forKey: .pbFrontSubtitleCenterX)
        try container.encode(frontSubtitleCenterY, forKey: .pbFrontSubtitleCenterY)
        try container.encode(frontSubtitleScale, forKey: .pbFrontSubtitleScale)
        try container.encode(hcFrontSubtitleOffsetXInches, forKey: .hcFrontSubtitleOffsetXInches)
        try container.encode(hcFrontSubtitleOffsetYInches, forKey: .hcFrontSubtitleOffsetYInches)
        try container.encode(hcFrontSubtitleCenterX, forKey: .hcFrontSubtitleCenterX)
        try container.encode(hcFrontSubtitleCenterY, forKey: .hcFrontSubtitleCenterY)
        try container.encode(hcFrontSubtitleScale, forKey: .hcFrontSubtitleScale)
        try container.encode(frontAuthorOffsetXInches, forKey: .frontAuthorOffsetXInches)
        try container.encode(frontAuthorOffsetYInches, forKey: .frontAuthorOffsetYInches)
        try container.encode(frontAuthorCenterX, forKey: .frontAuthorCenterX)
        try container.encode(frontAuthorCenterY, forKey: .frontAuthorCenterY)
        try container.encode(frontAuthorScale, forKey: .frontAuthorScale)
        try container.encode(frontAuthorOffsetXInches, forKey: .pbFrontAuthorOffsetXInches)
        try container.encode(frontAuthorOffsetYInches, forKey: .pbFrontAuthorOffsetYInches)
        try container.encode(frontAuthorCenterX, forKey: .pbFrontAuthorCenterX)
        try container.encode(frontAuthorCenterY, forKey: .pbFrontAuthorCenterY)
        try container.encode(hcFrontAuthorOffsetXInches, forKey: .hcFrontAuthorOffsetXInches)
        try container.encode(hcFrontAuthorOffsetYInches, forKey: .hcFrontAuthorOffsetYInches)
        try container.encode(hcFrontAuthorCenterX, forKey: .hcFrontAuthorCenterX)
        try container.encode(hcFrontAuthorCenterY, forKey: .hcFrontAuthorCenterY)
        try container.encode(hcFrontAuthorScale, forKey: .hcFrontAuthorScale)
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
        try container.encode(blurbWidthInches, forKey: .blurbWidthInches)
        if bindingType == .hc {
            try container.encode(blurbOffsetXInches, forKey: .hcBackBlurbOffsetXInches)
            try container.encode(blurbOffsetYInches, forKey: .hcBackBlurbOffsetYInches)
            try container.encode(blurbWidthInches, forKey: .hcBackBlurbWidthInches)
        } else {
            try container.encode(blurbOffsetXInches, forKey: .pbBackBlurbOffsetXInches)
            try container.encode(blurbOffsetYInches, forKey: .pbBackBlurbOffsetYInches)
            try container.encode(blurbWidthInches, forKey: .pbBackBlurbWidthInches)
        }
        try container.encode(quote, forKey: .quote)
        try container.encode(quoteAttribution, forKey: .quoteAttribution)
        try container.encode(quoteOffsetXInches, forKey: .quoteOffsetXInches)
        try container.encode(quoteOffsetYInches, forKey: .quoteOffsetYInches)
        if bindingType == .hc {
            try container.encode(quoteOffsetXInches, forKey: .hcBackQuoteOffsetXInches)
            try container.encode(quoteOffsetYInches, forKey: .hcBackQuoteOffsetYInches)
        } else {
            try container.encode(quoteOffsetXInches, forKey: .pbBackQuoteOffsetXInches)
            try container.encode(quoteOffsetYInches, forKey: .pbBackQuoteOffsetYInches)
        }
        try container.encode(quoteAttributionOffsetXInches, forKey: .quoteAttributionOffsetXInches)
        try container.encode(quoteAttributionOffsetYInches, forKey: .quoteAttributionOffsetYInches)
        try container.encode(authorBio, forKey: .authorBio)
        try container.encode(authorBioOffsetXInches, forKey: .authorBioOffsetXInches)
        try container.encode(authorBioOffsetYInches, forKey: .authorBioOffsetYInches)
        try container.encode(authorBioWidthInches, forKey: .authorBioWidthInches)
        if bindingType == .hc {
            try container.encode(authorBioOffsetXInches, forKey: .hcBackAuthorBioOffsetXInches)
            try container.encode(authorBioOffsetYInches, forKey: .hcBackAuthorBioOffsetYInches)
            try container.encode(authorBioWidthInches, forKey: .hcBackAuthorBioWidthInches)
        } else {
            try container.encode(authorBioOffsetXInches, forKey: .pbBackAuthorBioOffsetXInches)
            try container.encode(authorBioOffsetYInches, forKey: .pbBackAuthorBioOffsetYInches)
            try container.encode(authorBioWidthInches, forKey: .pbBackAuthorBioWidthInches)
        }
        try container.encode(authorBioParagraphGapPoints, forKey: .authorBioParagraphGapPoints)
        try container.encode(authorPhoto, forKey: .authorPhoto)
        try container.encode(authorPhotoScaleInches, forKey: .authorPhotoScaleInches)
        try container.encode(authorPhotoOffsetXInches, forKey: .authorPhotoOffsetXInches)
        try container.encode(authorPhotoOffsetYInches, forKey: .authorPhotoOffsetYInches)
        try container.encode(authorPhotoShape, forKey: .authorPhotoShape)
        try container.encode(authorPhotoCropOffsetX, forKey: .authorPhotoCropOffsetX)
        try container.encode(authorPhotoCropOffsetY, forKey: .authorPhotoCropOffsetY)
        if bindingType == .hc {
            try container.encode(authorPhotoOffsetXInches, forKey: .hcBackAuthorImageOffsetXInches)
            try container.encode(authorPhotoOffsetYInches, forKey: .hcBackAuthorImageOffsetYInches)
        } else {
            try container.encode(authorPhotoOffsetXInches, forKey: .pbBackAuthorImageOffsetXInches)
            try container.encode(authorPhotoOffsetYInches, forKey: .pbBackAuthorImageOffsetYInches)
        }
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
        if let d = try? decodeIfPresent(Double.self, forKey: key) { return d }
        if let s = try? decodeIfPresent(String.self, forKey: key), let d = Double(s) { return d }
        return 1.0
    }

    func doubleOrDefault(_ key: Key, defaultValue: Double) -> Double {
        if let d = try? decodeIfPresent(Double.self, forKey: key) { return d }
        if let s = try? decodeIfPresent(String.self, forKey: key), let d = Double(s) { return d }
        return defaultValue
    }

    func optionalDouble(_ key: Key) -> Double? {
        if let d = try? decodeIfPresent(Double.self, forKey: key) { return d }
        if let s = try? decodeIfPresent(String.self, forKey: key) {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            return Double(trimmed)
        }
        return nil
    }

    func stringOrEmpty(_ key: Key) -> String {
        (try? decodeIfPresent(String.self, forKey: key)) ?? ""
    }

    func stringOrAuto(_ key: Key) -> String {
        let s = stringOrEmpty(key)
        return s.isEmpty ? "auto" : s
    }

    func stringOrDefault(_ key: Key, defaultValue: String) -> String {
        let s = stringOrEmpty(key).trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? defaultValue : s
    }

    func boolOrFalse(_ key: Key) -> Bool {
        (try? decodeIfPresent(Bool.self, forKey: key)) ?? false
    }

    func boolOrTrue(_ key: Key) -> Bool {
        if let b = try? decodeIfPresent(Bool.self, forKey: key) { return b }
        return true
    }

    func boolOrDefault(_ key: Key, defaultValue: Bool) -> Bool {
        if let b = try? decodeIfPresent(Bool.self, forKey: key) { return b }
        if let s = try? decodeIfPresent(String.self, forKey: key) {
            switch s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1": return true
            case "false", "no", "0": return false
            default: break
            }
        }
        return defaultValue
    }

    func optionalBool(_ key: Key) -> Bool? {
        if let b = try? decodeIfPresent(Bool.self, forKey: key) { return b }
        if let s = try? decodeIfPresent(String.self, forKey: key) {
            switch s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1": return true
            case "false", "no", "0": return false
            default: return nil
            }
        }
        return nil
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
        if let value = optionalDouble(bindingKey) {
            return value
        }
        if let value = optionalDouble(canonical) {
            return value
        }
        if let fallback, let value = optionalDouble(fallback) {
            return value
        }
        return 0.0
    }

    func bindingDoubleOrDefault(
        canonical: Key,
        paperback: Key,
        hardcover: Key,
        bindingType: BindingType,
        fallback: Key? = nil,
        defaultValue: Double
    ) -> Double {
        let bindingKey = bindingType == .hc ? hardcover : paperback
        if let value = optionalDouble(bindingKey) {
            return value
        }
        if let value = optionalDouble(canonical) {
            return value
        }
        if let fallback, let value = optionalDouble(fallback) {
            return value
        }
        return defaultValue
    }

    func bindingBool(
        canonical: Key,
        paperback: Key,
        hardcover: Key,
        bindingType: BindingType,
        fallback: Key? = nil
    ) -> Bool {
        let bindingKey = bindingType == .hc ? hardcover : paperback
        if let value = optionalBool(bindingKey) {
            return value
        }
        if let value = optionalBool(canonical) {
            return value
        }
        if let fallback, let value = optionalBool(fallback) {
            return value
        }
        return false
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
