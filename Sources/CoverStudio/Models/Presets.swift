import Foundation

enum BindingType: String, Codable, CaseIterable {
    case pb = "pb"
    case hc = "hc"

    var label: String {
        switch self {
        case .pb: "Paperback"
        case .hc: "Hardcover"
        }
    }
}

enum InteriorType: String, Codable, CaseIterable {
    case blackWhite = "black_white"
    case standardColor = "standard_color"
    case premiumColor = "premium_color"

    var label: String {
        switch self {
        case .blackWhite: "Black & White"
        case .standardColor: "Standard Color"
        case .premiumColor: "Premium Color"
        }
    }
}

enum PaperType: String, Codable, CaseIterable {
    case white = "white"
    case cream = "cream"
    case groundwood = "groundwood"

    var label: String {
        switch self {
        case .white: "White"
        case .cream: "Cream"
        case .groundwood: "Groundwood"
        }
    }

    static func options(for interior: InteriorType, binding: BindingType = .pb) -> [PaperType] {
        switch interior {
        case .blackWhite:
            return binding == .pb ? [.white, .cream, .groundwood] : [.white, .cream]
        case .standardColor, .premiumColor:
            return [.white]
        }
    }
}

enum ReadingDirection: String, Codable, CaseIterable {
    case ltr = "ltr"
    case rtl = "rtl"

    var label: String {
        switch self {
        case .ltr: "Left to Right"
        case .rtl: "Right to Left"
        }
    }
}

enum TrimPreset: String, Codable, CaseIterable {
    case custom, fiveX7_4, fiveX8, five06X7_81, five25X8, five5X8_5
    case sixX9, six14X9_21, six69X9_61, sevenX10, seven44X9_69
    case seven5X9_25, eightX10, eight25X6, eight25X8_25
    case eight27X11_69, eight5X8_5, eight5X11

    var dimensions: (width: Double, height: Double) {
        switch self {
        case .custom: (0, 0)
        case .fiveX7_4: (5.0, 7.4)
        case .fiveX8: (5.0, 8.0)
        case .five06X7_81: (5.06, 7.81)
        case .five25X8: (5.25, 8.0)
        case .five5X8_5: (5.5, 8.5)
        case .sixX9: (6.0, 9.0)
        case .six14X9_21: (6.14, 9.21)
        case .six69X9_61: (6.69, 9.61)
        case .sevenX10: (7.0, 10.0)
        case .seven44X9_69: (7.44, 9.69)
        case .seven5X9_25: (7.5, 9.25)
        case .eightX10: (8.0, 10.0)
        case .eight25X6: (8.25, 6.0)
        case .eight25X8_25: (8.25, 8.25)
        case .eight27X11_69: (8.27, 11.69)
        case .eight5X8_5: (8.5, 8.5)
        case .eight5X11: (8.5, 11.0)
        }
    }

    var label: String {
        if self == .custom { return "Custom" }
        let dims = dimensions
        return "\(dims.width) × \(dims.height) in"
    }

    static func paperbackPresets() -> [TrimPreset] { allCases }
    static func hardcoverPresets() -> [TrimPreset] {
        [.custom, .five5X8_5, .sixX9, .six14X9_21, .sevenX10, .eight5X11]
    }
}

enum Units: String, Codable, CaseIterable {
    case inches = "in"
    case millimeters = "mm"
    case centimeters = "cm"

    var label: String {
        switch self {
        case .inches: "Inches"
        case .millimeters: "Millimeters"
        case .centimeters: "Centimeters"
        }
    }

    func toInches(_ value: Double) -> Double {
        switch self {
        case .inches: value
        case .millimeters: value / 25.4
        case .centimeters: value / 2.54
        }
    }

    func fromInches(_ value: Double) -> Double {
        switch self {
        case .inches: value
        case .millimeters: value * 25.4
        case .centimeters: value * 2.54
        }
    }
}

enum AuthorPhotoShape: String, Codable, CaseIterable {
    case circle
    case square
    case raw

    var label: String {
        switch self {
        case .circle: "Circle"
        case .square: "Square"
        case .raw: "Raw"
        }
    }
}

/// How the front cover art fills the front panel.
enum FrontImageFit: String, Codable, CaseIterable {
    /// Auto: cover-fit when the source aspect is close to the panel, stretch otherwise.
    case auto
    /// Scale uniformly to cover the panel, crop the overflow.
    case cover
    /// Scale to the exact panel dimensions (non-uniform when aspects differ).
    case stretch

    var label: String {
        switch self {
        case .auto: "Auto"
        case .cover: "Cover (scale + crop)"
        case .stretch: "Stretch to exact size"
        }
    }
}

extension FrontImageFit {
    /// Resolve `.auto` to a concrete mode: cover-fit when the source aspect ratio is within
    /// 15% of the front panel aspect ratio, stretch otherwise.
    func resolved(sourceWidth: Int, sourceHeight: Int, panelWidth: Int, panelHeight: Int) -> FrontImageFit {
        guard self == .auto else { return self }
        guard sourceWidth > 0, sourceHeight > 0, panelWidth > 0, panelHeight > 0 else { return .cover }
        let panelAspect = Double(panelWidth) / Double(panelHeight)
        let sourceAspect = Double(sourceWidth) / Double(sourceHeight)
        return abs(sourceAspect - panelAspect) / panelAspect <= 0.15 ? .cover : .stretch
    }
}
