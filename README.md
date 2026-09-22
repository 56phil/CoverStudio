# CoverStudio

CoverStudio is a macOS app for designing and tuning full-wrap book covers.

It is built for authors and small publishers who need more control than a
template-only tool gives them: exact print dimensions, front/spine/back layout
controls, Markdown project files, and export-ready cover images.

The first target workflow is Amazon KDP paperback and hardcover cover creation,
especially projects that already keep cover metadata in `cover/cover.md`.

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
- Set the back-cover blurb, quote, and bio font sizes, per binding (paperback and hardcover independently).
- Export the full wraparound cover as PDF; a PNG copy is written alongside it automatically.
- Export a front-cover crop as JPEG.
- Run headless: `render`, `validate`, and `inspect` subcommands for scripts and CI.

The app is being developed against real book projects, so compatibility with
existing cover metadata matters as much as the native UI.

## Requirements

- macOS 14 or newer
- Xcode command line tools
- Swift 5.10 or newer

## Headless Use

CoverStudio is a GUI app when launched with no arguments, and a command-line
tool when given a subcommand. The same binary does both, and both render
through the same code path, so a headless run produces the cover the window
would have shown.

This is for scripts, hooks, and CI: regenerate a cover after the page count
changes, or gate a commit on whether the cover still validates.

```sh
swift build -c release
BIN=.build/release/CoverStudio

# Render the full wraparound cover and a front-cover crop.
$BIN render ~/Developer/LaTeX/AllMyBooks/pic \
     --out-pdf build/pic-cover.pdf \
     --out-png build/pic-cover.png \
     --out-front build/pic-front.jpg

# Check the cover without rendering anything.
$BIN validate ~/Developer/LaTeX/AllMyBooks/pic

# Read the computed layout (spine, wrap size, pixel dimensions).
$BIN inspect ~/Developer/LaTeX/AllMyBooks/pic
```

A project directory is enough: the tool finds `cover/cover.md` inside it. You
can also point straight at the file, or use `--cover <path>` instead of a
positional argument.

### Commands

| Command | Purpose |
| --- | --- |
| `render` | Write the wraparound cover as PDF and/or PNG, and/or the front crop. |
| `validate` | Report validation errors and warnings. Renders nothing. |
| `inspect` | Print the computed geometry. Renders nothing. |
| `version`, `help` | Print the version or the full usage text. |

### Render options

| Option | Meaning |
| --- | --- |
| `--out-pdf <path>` | Full wraparound cover as PDF, at exact physical size. |
| `--out-png <path>` | Full wraparound cover as PNG. |
| `--out-front <path>` | Front-cover crop only. |
| `--front-format <fmt>` | `jpg` (default) or `png` for `--out-front`. |
| `--front-quality <q>` | JPEG quality, 0.0–1.0 (default `0.95`). |
| `--dpi <n>` | DPI recorded in PNG/JPEG output (default `300`). |
| `--bind <pb\|hc>` | Override the binding for this run only. |
| `--guides` | Draw trim and spine guides into the output. |
| `--no-fit` | Skip regenerating `<base>-fitted.png`. |
| `--force` | Render even when validation reports errors. |
| `--json` | Machine-readable output on stdout. |

### Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success. |
| 1 | Usage error. |
| 2 | The cover has validation errors. |
| 3 | Rendering or I/O failed. |

`validate` accepts `--strict` to treat warnings as failures as well.

```sh
# Fail a build when the cover is broken or the copy is empty.
$BIN validate ./my-book --strict || exit 1
```

### What the tool will not do

It reads the project and writes only the files you name. It never saves
`cover.md`, so running it cannot rewrite your project behind your back. That
matters because CoverStudio's editor holds the whole document in memory and a
save from a stale copy can silently drop blurb, bio, and other fields.

Two notes on rendering headless:

- `--force` exists because a cover can be deliberately incomplete. Without it,
  a validation error stops the render so a missing front image fails loudly
  instead of producing a plausible-looking cover.
- Invalid option values are rejected rather than ignored. `--dpi abc` is an
  error, not a silent fall back to 300, because a wrongly-implied resolution
  is invisible in the output.

Running the binary from inside an unsigned `CoverStudio.app` prints one
`sandbox_extension_issue_file_to_process` line to stderr during `render`. It is
cosmetic: exit status and stdout are unaffected, and the plain binary
(`.build/release/CoverStudio`) is silent.

## Back-Cover Font Sizes

The blurb, quote, and author-bio sizes are adjustable, separately for paperback
and hardcover. The controls are in the Back tab, under each block.

Each size is stored as `0` when unset, which means "use the default":

| Field | Default |
| --- | --- |
| `blurb_font_size_points` / `hc_blurb_font_size_points` | 43 |
| `quote_font_size_points` / `hc_quote_font_size_points` | 38 |
| `author_bio_font_size_points` / `hc_author_bio_font_size_points` | 32 |

Sizes are in points at the render DPI (300), so 1pt here is 1px on the cover.
The defaults are the sizes the renderer previously hardcoded, so a `cover.md`
that predates these fields renders exactly as it did — the addition is a no-op
until you set something.

The paperback and hardcover fields are independent. Setting the paperback blurb
to 40pt leaves the hardcover at its default until you set that one too.

### Truncation is reported

The back-cover text blocks stop at a computed height and draw silently, so copy
that is too long is **cut, not reported** — a paragraph simply does not appear.
That was survivable with fixed sizes. Now that the size is a control, the
renderer reports what it had to clip:

```sh
$ CoverStudio render ./my-book --out-png out.png
out.png
warning: blurb is clipped — needs 8338px, 2057px available (over by 6281px).
Reduce its font size or shorten it.
```

`--json` carries the same under a `clipped` array, so a script can gate on it:

```sh
CoverStudio render ./my-book --out-png out.png --json | jq -e '.clipped | length == 0'
```

The check never fires on copy that fits, so the warning stays meaningful. Note
it detects a block whose *height* overflows; it cannot detect a blurb pushed
under the author photo by an offset, which is a positioning problem rather than
a size one.

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
./scripts/package-release.sh
```

The version comes from `coverStudioVersion` in `Sources/CoverStudio/CLI.swift` — the
same string `CoverStudio --version` prints — so the DMG name, the bundle, and the
binary cannot disagree. Bump that one line to cut a release; `scripts/version.sh`
is what reads it.

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

Cover control files are Markdown documents that begin with YAML frontmatter:

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
