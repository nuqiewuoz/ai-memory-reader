import Foundation
import Markdown
import SwiftUI

enum MarkdownRenderer {
    static func render(_ source: String) -> AttributedString {
        let document = Document(parsing: source)
        var visitor = AttributedStringVisitor()
        return visitor.visit(document)
    }
}

// MARK: - Visitor

private struct AttributedStringVisitor: MarkupVisitor {
    typealias Result = AttributedString

    private var listDepth = 0
    private var orderedListCounter = 0
    private var isInOrderedList = false

    // MARK: - Document

    mutating func defaultVisit(_ markup: any Markup) -> AttributedString {
        var result = AttributedString()
        for child in markup.children {
            result.append(visit(child))
        }
        return result
    }

    // MARK: - Block Elements

    mutating func visitDocument(_ document: Document) -> AttributedString {
        var result = AttributedString()
        for (index, child) in document.children.enumerated() {
            result.append(visit(child))
            if index < document.childCount - 1 {
                result.append(AttributedString("\n"))
            }
        }
        return result
    }

    mutating func visitHeading(_ heading: Heading) -> AttributedString {
        var result = AttributedString()
        for child in heading.children {
            result.append(visit(child))
        }
        let sizes: [Int: CGFloat] = [1: 28, 2: 24, 3: 20, 4: 17, 5: 15, 6: 13]
        let size = sizes[heading.level] ?? 15
        result.font = .system(size: size, weight: .bold)
        result.foregroundColor = .primary
        var spaced = AttributedString("\n")
        spaced.append(result)
        spaced.append(AttributedString("\n"))
        return spaced
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> AttributedString {
        var result = AttributedString()
        for child in paragraph.children {
            result.append(visit(child))
        }
        result.append(AttributedString("\n\n"))
        return result
    }

    mutating func visitText(_ text: Markdown.Text) -> AttributedString {
        var s = AttributedString(text.string)
        s.font = .system(size: 14)
        s.foregroundColor = .primary
        return s
    }

    mutating func visitStrong(_ strong: Strong) -> AttributedString {
        var result = AttributedString()
        for child in strong.children {
            result.append(visit(child))
        }
        result.font = .system(size: 14, weight: .bold)
        return result
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> AttributedString {
        var result = AttributedString()
        for child in emphasis.children {
            result.append(visit(child))
        }
        result.font = .system(size: 14).italic()
        return result
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> AttributedString {
        var result = AttributedString()
        for child in strikethrough.children {
            result.append(visit(child))
        }
        result.strikethroughStyle = .single
        return result
    }

    // MARK: - Code

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> AttributedString {
        var s = AttributedString(inlineCode.code)
        s.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        s.foregroundColor = Color(.systemPink)
        s.backgroundColor = Color(.quaternaryLabelColor)
        return s
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> AttributedString {
        let code = codeBlock.code.hasSuffix("\n")
            ? String(codeBlock.code.dropLast())
            : codeBlock.code

        var header = AttributedString("")
        if let lang = codeBlock.language, !lang.isEmpty {
            header = AttributedString("  \(lang)\n")
            header.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
            header.foregroundColor = .secondary
            header.backgroundColor = Color(.controlBackgroundColor)
        }

        var s = AttributedString(code)
        s.font = .monospacedSystemFont(ofSize: 12.5, weight: .regular)
        s.foregroundColor = .primary
        s.backgroundColor = Color(.controlBackgroundColor)

        var result = AttributedString("\n")
        result.append(header)
        result.append(s)
        result.append(AttributedString("\n\n"))
        return result
    }

    // MARK: - Lists

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> AttributedString {
        listDepth += 1
        var result = AttributedString()
        for child in unorderedList.children {
            result.append(visit(child))
        }
        listDepth -= 1
        if listDepth == 0 {
            result.append(AttributedString("\n"))
        }
        return result
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> AttributedString {
        listDepth += 1
        let previousState = isInOrderedList
        isInOrderedList = true
        orderedListCounter = 0
        var result = AttributedString()
        for child in orderedList.children {
            result.append(visit(child))
        }
        isInOrderedList = previousState
        listDepth -= 1
        if listDepth == 0 {
            result.append(AttributedString("\n"))
        }
        return result
    }

    mutating func visitListItem(_ listItem: ListItem) -> AttributedString {
        let indent = String(repeating: "  ", count: listDepth - 1)
        let bullet: String
        if isInOrderedList {
            orderedListCounter += 1
            bullet = "\(indent)\(orderedListCounter). "
        } else {
            let bullets = ["•", "◦", "▪"]
            let b = bullets[min(listDepth - 1, bullets.count - 1)]
            bullet = "\(indent)\(b) "
        }

        var prefix = AttributedString(bullet)
        prefix.font = .system(size: 14)
        prefix.foregroundColor = .secondary

        var content = AttributedString()
        for child in listItem.children {
            let childContent = visit(child)
            content.append(childContent)
        }

        // Remove trailing double newline from paragraph, add single newline
        var line = prefix
        line.append(content)

        let str = String(line.characters)
        if str.hasSuffix("\n\n") {
            // Trim one trailing newline
            var trimmed = AttributedString()
            var chars = Array(str)
            if chars.count >= 2 {
                chars.removeLast()
            }
            trimmed = AttributedString(String(chars))
            trimmed.font = .system(size: 14)
            return trimmed
        }

        return line
    }

    // MARK: - Links & Images

    mutating func visitLink(_ link: Markdown.Link) -> AttributedString {
        var result = AttributedString()
        for child in link.children {
            result.append(visit(child))
        }
        if let dest = link.destination, let url = URL(string: dest) {
            result.link = url
            result.foregroundColor = .accentColor
            result.underlineStyle = .single
        }
        return result
    }

    mutating func visitImage(_ image: Markdown.Image) -> AttributedString {
        let alt = image.plainText
        var s = AttributedString("🖼 \(alt.isEmpty ? "image" : alt)")
        s.font = .system(size: 14).italic()
        s.foregroundColor = .secondary
        return s
    }

    // MARK: - Block Quote

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> AttributedString {
        var content = AttributedString()
        for child in blockQuote.children {
            content.append(visit(child))
        }
        var bar = AttributedString("┃ ")
        bar.foregroundColor = .accentColor
        bar.font = .system(size: 14, weight: .bold)

        var result = bar
        result.append(content)
        return result
    }

    // MARK: - Thematic Break

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> AttributedString {
        var s = AttributedString("\n────────────────────────────────\n\n")
        s.foregroundColor = .secondary
        s.font = .system(size: 10)
        return s
    }

    // MARK: - Table

    mutating func visitTable(_ table: Markdown.Table) -> AttributedString {
        var result = AttributedString("\n")

        // Collect all rows (head + body)
        var allRows: [[AttributedString]] = []

        // Header
        if let head = table.children.first(where: { $0 is Markdown.Table.Head }) as? Markdown.Table.Head {
            for row in head.children {
                if let tableRow = row as? Markdown.Table.Row {
                    var cells: [AttributedString] = []
                    for cell in tableRow.children {
                        if let tableCell = cell as? Markdown.Table.Cell {
                            var cellContent = AttributedString()
                            for child in tableCell.children {
                                cellContent.append(visit(child))
                            }
                            cellContent.font = .system(size: 13, weight: .bold)
                            cells.append(cellContent)
                        }
                    }
                    allRows.append(cells)
                }
            }
        }

        // Body
        if let body = table.children.first(where: { $0 is Markdown.Table.Body }) as? Markdown.Table.Body {
            for row in body.children {
                if let tableRow = row as? Markdown.Table.Row {
                    var cells: [AttributedString] = []
                    for cell in tableRow.children {
                        if let tableCell = cell as? Markdown.Table.Cell {
                            var cellContent = AttributedString()
                            for child in tableCell.children {
                                cellContent.append(visit(child))
                            }
                            cellContent.font = .system(size: 13)
                            cells.append(cellContent)
                        }
                    }
                    allRows.append(cells)
                }
            }
        }

        // Render as aligned text
        for (rowIndex, row) in allRows.enumerated() {
            var rowString = AttributedString()
            for (cellIndex, cell) in row.enumerated() {
                if cellIndex > 0 {
                    var sep = AttributedString("  │  ")
                    sep.foregroundColor = .secondary
                    sep.font = .system(size: 13)
                    rowString.append(sep)
                }
                rowString.append(cell)
            }
            rowString.append(AttributedString("\n"))
            result.append(rowString)

            // Separator after header
            if rowIndex == 0 && allRows.count > 1 {
                var sep = AttributedString("─────────────────────────\n")
                sep.foregroundColor = .secondary
                sep.font = .system(size: 10)
                result.append(sep)
            }
        }

        result.append(AttributedString("\n"))
        return result
    }

    // MARK: - Soft/Hard Break

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> AttributedString {
        return AttributedString(" ")
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> AttributedString {
        return AttributedString("\n")
    }

    // MARK: - HTML

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> AttributedString {
        var s = AttributedString(html.rawHTML)
        s.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        s.foregroundColor = .secondary
        return s
    }

    mutating func visitInlineHTML(_ html: InlineHTML) -> AttributedString {
        var s = AttributedString(html.rawHTML)
        s.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        s.foregroundColor = .secondary
        return s
    }
}
