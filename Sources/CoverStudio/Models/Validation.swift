import Foundation

struct Validation {
    struct Issue {
        enum Severity: String {
            case error, warning, info
        }
        let severity: Severity
        let field: String
        let message: String
    }

    static func validate(_ data: CoverData) -> [Issue] {
        var issues: [Issue] = []

        // Required string fields
        let required: [(String, String)] = [
            ("binding_type", data.bindingType.rawValue),
            ("interior_type", data.interiorType.rawValue),
            ("paper_type", data.paperType.rawValue),
            ("trim_size", data.trimSize.rawValue),
        ]
        for (key, value) in required where value.isEmpty {
            issues.append(Issue(severity: .error, field: key, message: "Required value is missing."))
        }

        // Custom trim
        if data.trimSize == .custom {
            if data.customTrimWidthInches <= 0 {
                issues.append(Issue(severity: .error, field: "custom_trim_width_inches", message: "Must be greater than zero."))
            }
            if data.customTrimHeightInches <= 0 {
                issues.append(Issue(severity: .error, field: "custom_trim_height_inches", message: "Must be greater than zero."))
            }
            if data.customSpineWidthInches < 0 {
                issues.append(Issue(severity: .error, field: "custom_spine_width_inches", message: "Cannot be negative."))
            }
            if data.customBleedInches < 0 {
                issues.append(Issue(severity: .error, field: "custom_bleed_inches", message: "Cannot be negative."))
            }
            if data.customSafeMarginInches < 0 {
                issues.append(Issue(severity: .error, field: "custom_safe_margin_inches", message: "Cannot be negative."))
            }
        }

        // Page count
        if data.pageCount < 24 {
            issues.append(Issue(severity: .error, field: "page_count", message: "Print books usually require at least 24 pages."))
        }

        // Front cover image
        if data.frontCoverImage.isEmpty {
            issues.append(Issue(severity: .error, field: "front_cover_image", message: "Front cover image is required."))
        } else {
            let url = URL(fileURLWithPath: data.frontCoverImage)
            if !FileManager.default.fileExists(atPath: url.path) {
                issues.append(Issue(severity: .error, field: "front_cover_image", message: "Image does not exist: \(data.frontCoverImage)"))
            }
        }

        // Author photo
        if !data.authorPhoto.isEmpty {
            let url = URL(fileURLWithPath: data.authorPhoto)
            if !FileManager.default.fileExists(atPath: url.path) {
                issues.append(Issue(severity: .warning, field: "author_photo", message: "Author photo path does not exist."))
            }
        }

        // Colors
        for (key, color, label) in [
            ("color_title", data.colorTitle, "Title color"),
            ("color_accent", data.colorAccent, "Accent color"),
            ("color_body", data.colorBody, "Body color"),
            ("color_soft", data.colorSoft, "Soft text color"),
        ] {
            if !isValidHexColor(color) {
                issues.append(Issue(severity: .error, field: key, message: "\(label) must be a HEX color such as #daa520."))
            }
        }

        // Hardcover template
        if data.bindingType == .hc {
            let templateFields: [(String, Double?)] = [
                ("template_full_cover_width", data.templateFullCoverWidth),
                ("template_full_cover_height", data.templateFullCoverHeight),
                ("template_front_cover_width", data.templateFrontCoverWidth),
                ("template_front_cover_height", data.templateFrontCoverHeight),
                ("template_spine_width", data.templateSpineWidth),
                ("template_hinge_width", data.templateHingeWidth),
                ("template_wrap_width", data.templateWrapWidth),
            ]
            for (key, value) in templateFields where value == nil {
                issues.append(Issue(severity: .error, field: key, message: "Hardcover requires this template dimension."))
            }
        }

        // Custom trim info
        if data.trimSize == .custom {
            issues.append(Issue(severity: .info, field: "trim_size", message: "Using a custom size. Check your printer’s bleed, spine, and safe-area requirements."))
        }

        // Blurb warning
        if data.blurb.isEmpty {
            issues.append(Issue(severity: .warning, field: "blurb", message: "Back-cover blurb is empty."))
        }

        return issues
    }

    private static func isValidHexColor(_ value: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^#?[0-9a-fA-F]{6}$")
        return regex.firstMatch(in: value.trimmingCharacters(in: .whitespaces), range: NSRange(location: 0, length: value.count)) != nil
    }
}
