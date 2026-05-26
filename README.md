# CoverStudio

CoverStudio is a macOS app for designing and tuning full-wrap book covers.

It is built for authors and small publishers who need more control than a
template-only tool gives them: exact print dimensions, front/spine/back layout
controls, YAML-backed project files, and export-ready cover images.

The first target workflow is Amazon KDP paperback and hardcover cover creation,
especially projects that already keep cover metadata in `cover/cover.md` or
`cover/cover.yaml`.

## Current Status

CoverStudio is early software. It can already:

- Load and save cover metadata from YAML and Markdown frontmatter.
- Preview a full wraparound cover with guides.
- Configure paperback and hardcover geometry.
- Use KDP-style trim, spine, hinge, wrap, bleed, and safe-area values.
- Place front-cover art, title, subtitle, and author text.
- Preserve precomposed front art with `front_text: false`.
- Tune spine text, spine color, and color extension.
- Place back-cover blurb, quote, author bio, and author photo.
- Export PNG, JPEG, and PDF output.

The app is being developed against real book projects, so compatibility with
existing cover metadata matters as much as the native UI.

## Requirements

- macOS 14 or newer
- Xcode command line tools
- Swift 5.10 or newer

## Build And Run

From the repository root:

```sh
swift build
swift run CoverStudio
```

To build a release app bundle:

```sh
./build-app.sh
```

The script creates:

```text
.build/release/CoverStudio.app
```

To package a downloadable DMG for a GitHub Release:

```sh
./scripts/package-release.sh 0.1.0
```

For public distribution, sign and notarize the DMG with a Developer ID
certificate. See `RELEASE.md` for the release checklist.

Unsigned early-test builds can still be shared with trusted testers. See
`UNSIGNED_INSTALL.md` for the first-launch steps macOS may require.

## Project Layout

A typical book project can look like this:

```text
MyBook/
  cover/
    cover.md
    assets/
      base.png
```

CoverStudio prefers `cover/cover.md` when it exists, then falls back to
`cover/cover.yaml`. Markdown cover files should begin with YAML frontmatter:

```yaml
---
schema_version: 1
binding_type: hc
trim_size: 6x9
front_cover_image: cover/assets/base.png
front_text: false
spine_text: true
---
```

Relative asset paths may be written relative to the book root, such as
`cover/assets/base.png`, or relative to the cover metadata file.

## Repository

The public repository is:

https://github.com/56phil/CoverStudio

## License

CoverStudio is available under the MIT License.
