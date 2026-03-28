#if os(macOS)
import AppKit
import MarkdownUI
import SwiftUI

/// Exports markdown content to PDF using an offscreen NSHostingView
@MainActor
enum PDFExporter {

    /// Export markdown text to PDF, showing a save panel for the user to pick location.
    /// - Parameters:
    ///   - markdownText: The raw markdown string
    ///   - defaultFilename: Default filename (without extension) for the save panel
    ///   - baseURL: Base URL for resolving relative image paths
    static func exportToPDF(markdownText: String, defaultFilename: String, baseURL: URL) {
        // Show save panel
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultFilename + ".pdf"
        panel.title = "Export PDF"
        panel.message = "Choose where to save the PDF"

        guard panel.runModal() == .OK, let saveURL = panel.url else { return }

        // Create the SwiftUI view for rendering
        let markdownView = PDFMarkdownView(markdownText: markdownText, baseURL: baseURL)

        // Render in an offscreen hosting view
        let hostingView = NSHostingView(rootView: markdownView)

        // Set a fixed width for the PDF page (US Letter width minus margins: 612 - 2*40 = 532pt)
        let pageWidth: CGFloat = 532
        let fittingSize = hostingView.fittingSize
        // Let it calculate height for the given width
        hostingView.frame = NSRect(x: 0, y: 0, width: pageWidth, height: 10000)
        hostingView.layoutSubtreeIfNeeded()

        let intrinsicHeight = hostingView.fittingSize.height
        hostingView.frame = NSRect(x: 0, y: 0, width: pageWidth, height: max(intrinsicHeight, 100))
        hostingView.layoutSubtreeIfNeeded()

        // Use NSPrintOperation to generate paginated PDF
        let printInfo = NSPrintInfo()
        printInfo.paperSize = NSSize(width: 612, height: 792) // US Letter
        printInfo.topMargin = 40
        printInfo.bottomMargin = 40
        printInfo.leftMargin = 40
        printInfo.rightMargin = 40
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = saveURL

        let printOperation = NSPrintOperation(view: hostingView, printInfo: printInfo)
        printOperation.showsPrintPanel = false
        printOperation.showsProgressPanel = true
        printOperation.run()
    }
}

/// A simple wrapper view that renders markdown with the memoryReader theme
private struct PDFMarkdownView: View {
    let markdownText: String
    let baseURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Markdown(markdownText)
                .markdownTheme(.memoryReader)
                .markdownImageProvider(.localFile(basePath: baseURL))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(0)
        }
        .frame(width: 532) // Match page content width
        .background(.white)
        .environment(\.colorScheme, .light) // Force light mode for PDF
    }
}
#endif
