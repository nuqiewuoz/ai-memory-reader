# AI Memory Reader

A native macOS app for browsing and reading AI agent memory files — beautifully rendered, instantly accessible.

![AI Memory Reader Screenshot](screenshots/placeholder.png)
<!-- TODO: Replace with actual screenshots -->

## Features

- **Beautiful Markdown Rendering** — GitHub-style markdown with code blocks, tables, lists, and more (powered by MarkdownUI)
- **Auto-Discover AI Sources** — Automatically detects Claude/OpenClaw, OpenAI/Codex, and Gemini memory directories
- **Today Panel** — Highlights today's memory file for quick access
- **File Tree Navigation** — Browse markdown files with an expandable sidebar
- **Dark & Light Themes** — Follows system appearance
- **File Watching** — Auto-refreshes when files change on disk
- **Local Folder Support** — Open any folder containing markdown files
- **Keyboard Shortcuts** — ⌘O to open folders, native macOS navigation

## Supported AI Sources

| AI Source | Directory | Key Files |
|-----------|-----------|-----------|
| Claude / OpenClaw | `~/.openclaw/workspace/` | MEMORY.md, SOUL.md, AGENTS.md, memory/*.md |
| OpenAI / Codex | `~/.codex/` | AGENTS.md, instructions.md |
| Gemini | `~/.gemini/` | GEMINI.md |

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/user/ai-memory-reader.git
   cd ai-memory-reader
   ```

2. Generate the Xcode project (requires [XcodeGen](https://github.com/yonaskolb/XcodeGen)):
   ```bash
   xcodegen generate
   ```

3. Open in Xcode:
   ```bash
   open AIMemoryReader.xcodeproj
   ```

4. Build and run (⌘R)

### Requirements

- macOS 15.0+
- Xcode 16.0+
- Swift 6.0

## Tech Stack

- **UI:** SwiftUI + NavigationSplitView
- **Markdown:** [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) (GitHub theme)
- **State:** @Observable macro
- **File Watching:** FSEvents
- **Project:** XcodeGen + SPM

## Roadmap

- [ ] Edit mode (inline markdown editing)
- [ ] iPhone / iPad adaptation
- [ ] AI tool integration (CLI / URL Scheme / MCP)
- [ ] Multi-window support
- [ ] Export to PDF
- [ ] Custom AI source paths
- [ ] iCloud sync

## License

MIT
