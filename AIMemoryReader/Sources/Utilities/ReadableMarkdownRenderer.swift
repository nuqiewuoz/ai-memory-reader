#if os(macOS)
import AppKit
import SwiftUI

/// Renders a markdown document into an `NSAttributedString` suitable for
/// read-only display inside an `NSTextView`. Used by the find-in-page
/// view so we can highlight matches at character granularity on top of
/// a basic markdown appearance. The full MarkdownUI rendering is still
/// used when the find bar is closed.
///
/// Implementation notes:
/// - Foundation's `AttributedString(markdown:options:)` with
///   `.interpretedSyntax = .full` strips markdown markers from the output
///   and exposes block structure via `presentationIntent` plus inline
///   styling via `inlinePresentationIntent`. We iterate those runs and
///   translate them into AppKit visual attributes (fonts, colors, paragraph
///   indents).
/// - The returned string's character offsets are what NSTextView sees, so
///   find-in-page should search the rendered `.string`, not the raw file
///   contents, to get NSRanges that line up with display positions.
enum ReadableMarkdownRenderer {

    struct Output {
        let attributed: NSMutableAttributedString
        /// Display string the renderer produced. Equivalent to `attributed.string`
        /// but cached so callers don't have to pay for it repeatedly.
        let plain: String
    }

    static func render(_ source: String, palette: ThemePalette) -> Output {
        var attributed: AttributedString
        do {
            attributed = try AttributedString(
                markdown: source,
                options: AttributedString.MarkdownParsingOptions(
                    allowsExtendedAttributes: true,
                    interpretedSyntax: .full,
                    failurePolicy: .returnPartiallyParsedIfPossible
                )
            )
        } catch {
            attributed = AttributedString(source)
        }

        // Base style applied to every character first; specialized styles
        // below merge in on top of this.
        let baseFont = NSFont.systemFont(ofSize: 16)
        let baseParagraph: NSMutableParagraphStyle = {
            let p = NSMutableParagraphStyle()
            p.lineSpacing = 4
            p.paragraphSpacingBefore = 2
            p.paragraphSpacing = 6
            return p
        }()

        var baseContainer = AttributeContainer()
        baseContainer[AttributeScopes.AppKitAttributes.FontAttribute.self] = baseFont
        baseContainer[AttributeScopes.AppKitAttributes.ForegroundColorAttribute.self] = NSColor(palette.text)
        baseContainer[AttributeScopes.AppKitAttributes.ParagraphStyleAttribute.self] = baseParagraph
        attributed.mergeAttributes(baseContainer, mergePolicy: .keepNew)

        applyBlockStyles(to: &attributed, palette: palette, baseFontSize: baseFont.pointSize)
        applyInlineStyles(to: &attributed, palette: palette, baseFontSize: baseFont.pointSize)
        applyLinkStyles(to: &attributed, palette: palette)

        let ns = NSMutableAttributedString(attributedString: NSAttributedString(attributed))
        return Output(attributed: ns, plain: ns.string)
    }

    // MARK: - Block styles

    private static func applyBlockStyles(
        to attributed: inout AttributedString,
        palette: ThemePalette,
        baseFontSize: CGFloat
    ) {
        for run in attributed.runs {
            guard let intent = run.presentationIntent else { continue }

            var font: NSFont?
            var foreground: NSColor?
            var background: NSColor?
            var indent: CGFloat = 0
            var headingSize: CGFloat?

            for component in intent.components {
                switch component.kind {
                case .header(level: let level):
                    headingSize = headingFontSize(for: level)
                    foreground = NSColor(palette.heading)
                case .codeBlock:
                    font = NSFont.monospacedSystemFont(ofSize: 13.5, weight: .regular)
                    background = NSColor(palette.codeBackground)
                case .blockQuote:
                    let bqBase = NSFont.systemFont(ofSize: baseFontSize)
                    font = NSFontManager.shared.convert(bqBase, toHaveTrait: .italicFontMask)
                    foreground = NSColor(palette.blockquote)
                    indent += 16
                case .listItem:
                    indent += 20
                case .thematicBreak:
                    foreground = NSColor(palette.divider)
                default:
                    break
                }
            }

            var container = AttributeContainer()
            if let headingSize {
                container[AttributeScopes.AppKitAttributes.FontAttribute.self]
                    = NSFont.systemFont(ofSize: headingSize, weight: .bold)
            } else if let font {
                container[AttributeScopes.AppKitAttributes.FontAttribute.self] = font
            }
            if let foreground {
                container[AttributeScopes.AppKitAttributes.ForegroundColorAttribute.self] = foreground
            }
            if let background {
                container[AttributeScopes.AppKitAttributes.BackgroundColorAttribute.self] = background
            }
            if indent > 0 {
                let p = NSMutableParagraphStyle()
                p.lineSpacing = 4
                p.paragraphSpacing = 6
                p.firstLineHeadIndent = indent
                p.headIndent = indent
                container[AttributeScopes.AppKitAttributes.ParagraphStyleAttribute.self] = p
            }
            attributed[run.range].mergeAttributes(container, mergePolicy: .keepNew)
        }
    }

    private static func headingFontSize(for level: Int) -> CGFloat {
        switch level {
        case 1: return 28
        case 2: return 24
        case 3: return 20
        case 4: return 18
        case 5: return 17
        default: return 16
        }
    }

    // MARK: - Inline styles (bold/italic/code/strike)

    private static func applyInlineStyles(
        to attributed: inout AttributedString,
        palette: ThemePalette,
        baseFontSize: CGFloat
    ) {
        for run in attributed.runs {
            guard let inline = run.inlinePresentationIntent else { continue }

            // Start from whatever font the run already has (block style may
            // have promoted it to a heading size) so bold/italic compose
            // correctly.
            let existing = attributed[run.range]
                .runs
                .first?
                .attributes[AttributeScopes.AppKitAttributes.FontAttribute.self]
                ?? NSFont.systemFont(ofSize: baseFontSize)

            var font: NSFont = existing
            if inline.contains(.stronglyEmphasized) {
                font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            }
            if inline.contains(.emphasized) {
                font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            }

            var container = AttributeContainer()
            if inline.contains(.stronglyEmphasized) || inline.contains(.emphasized) {
                container[AttributeScopes.AppKitAttributes.FontAttribute.self] = font
            }
            if inline.contains(.code) {
                container[AttributeScopes.AppKitAttributes.FontAttribute.self]
                    = NSFont.monospacedSystemFont(ofSize: 13.5, weight: .regular)
                container[AttributeScopes.AppKitAttributes.ForegroundColorAttribute.self] = NSColor(palette.code)
                container[AttributeScopes.AppKitAttributes.BackgroundColorAttribute.self] = NSColor(palette.codeBackground)
            }
            if inline.contains(.strikethrough) {
                container[AttributeScopes.AppKitAttributes.StrikethroughStyleAttribute.self]
                    = NSUnderlineStyle.single
            }
            attributed[run.range].mergeAttributes(container, mergePolicy: .keepNew)
        }
    }

    // MARK: - Links

    private static func applyLinkStyles(to attributed: inout AttributedString, palette: ThemePalette) {
        for run in attributed.runs {
            guard run.link != nil else { continue }
            var container = AttributeContainer()
            container[AttributeScopes.AppKitAttributes.ForegroundColorAttribute.self] = NSColor(palette.link)
            container[AttributeScopes.AppKitAttributes.UnderlineStyleAttribute.self] = NSUnderlineStyle.single
            attributed[run.range].mergeAttributes(container, mergePolicy: .keepNew)
        }
    }
}
#endif
