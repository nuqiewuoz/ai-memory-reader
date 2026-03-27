# AI Memory Reader — MVP Plan

## 一句话定位
专为查阅 AI 工作记忆而设计的 Mac 原生 Markdown 阅读器。

## 核心痛点
- AI 大模型（Claude/OpenClaw、Codex/OpenAI、Gemini）都用 .md 文件记录上下文/记忆
- 分散在不同目录，没有统一入口
- 现有编辑器太重，不针对"AI 记忆"场景
- 用户只想快速翻阅

## MVP 范围

### ✅ 做
- 完美的 Markdown 阅读体验（渲染、排版、代码高亮、中英文混排）
- 自动发现 AI 记忆目录（Claude/OpenClaw、Codex/OpenAI、Gemini）
- 文件树侧边栏
- 本地文件/文件夹选择
- 全文搜索
- Dark/Light 主题（跟随系统）
- 快捷键
- Today 面板（高亮今天的 memory 文件）
- 文件变化自动刷新

### ❌ MVP 不做
- 编辑功能（V2）
- iPhone 版本（V2）
- AI 工具调用接口/CLI（V2）
- 云同步
- 插件系统

## 技术选型
- UI: SwiftUI (macOS 15+)
- Markdown 渲染: swift-markdown (Apple) + AttributedString
- 代码高亮: Splash 或 Highlightr
- 文件监听: DispatchSource / FSEvents
- 项目结构: SPM

## AI 源路径

| AI | 路径 | 关键文件 |
|---|---|---|
| Claude/OpenClaw | ~/.openclaw/workspace/ | MEMORY.md, SOUL.md, AGENTS.md, memory/*.md |
| OpenAI/Codex | ~/.codex/ | AGENTS.md, instructions.md |
| Gemini | ~/.gemini/ | GEMINI.md |

## 里程碑
- M1: 基础框架 + 文件树 + Markdown 渲染
- M2: AI 源自动发现 + 预置路径
- M3: 搜索 + 文件监听 + 自动刷新
- M4: 打磨阅读体验（代码高亮、表格、TOC）
- M5: 本地文件/文件夹选择 + 快捷键

## V2 方向
- 编辑模式
- iPhone 适配
- AI 工具调用接口（CLI / URL Scheme / MCP，方便 AI agent 直接调用）
- 多窗口
- Markdown 导出 PDF
- 自定义 AI 源路径
- iCloud 同步

## 开发日志
（每个重要节点记录在下方）

---
### 2026-03-26 — Plan 确认
- Plan 由 Qun 确认
- 开始 M1 开发

### 2026-03-26 — M2 完成 ✅
**AI 源自动发现 + 预置路径**

已实现功能：
- `AISource` 模型，预置三个 AI 源：
  - Claude/OpenClaw: `~/.openclaw/workspace/`（🦞 橙色）
  - OpenAI/Codex: `~/.codex/`（🤖 绿色）
  - Gemini: `~/.gemini/`（✨ 蓝色）
- 启动时自动检测磁盘上哪些 AI 源存在
- 侧边栏顶部显示已检测到的 AI 源，带图标 + 名称 + 选中高亮
- 点击 AI 源加载其目录到文件树
- "Local Files…" 选项打开文件夹选择器（保留原有 ⌘O 行为）
- 通过 UserDefaults 记住上次选择的源，跨启动保持
- Today 面板：如果当前源有 `memory/YYYY-MM-DD.md` 今日文件，自动展开并选中，文件树中显示 "Today" 标签
- 每个 AI 源行右侧显示小圆点指示今日记忆文件是否存在

新增文件：
- `AIMemoryReader/Sources/Models/AISource.swift` — AI 源模型

修改文件：
- `AppState.swift` — 新增源管理、持久化、今日文件自动选中
- `SidebarView.swift` — 重构为 AI 源区 + 文件树区 + AISourceRow 组件
- `ContentView.swift` — 使用 `restoreOrAutoSelect()` 替代硬编码自动加载

### 2026-03-26 — M1 完成 ✅
**基础框架 + 文件树 + Markdown 渲染**

已实现功能：
- macOS SwiftUI 应用，最低 macOS 15.0，Swift 6
- `NavigationSplitView` 侧边栏 + 详情布局
- 文件树导航：文件夹可展开，.md 文件可点击选择
- 只显示 .md 文件和包含 .md 文件的目录，自动过滤无关文件
- 完整 Markdown 渲染（基于 Apple swift-markdown）：
  - 标题（H1-H6，不同字号）
  - 粗体、斜体、删除线
  - 行内代码（粉色 + 背景色）、代码块（等宽字体 + 背景色 + 语言标签）
  - 有序/无序列表（嵌套缩进 + 不同 bullet 样式）
  - 表格（文本对齐渲染，表头加粗）
  - 链接（可点击）、图片（显示 alt text）
  - 引用块（竖线标识）
  - 分割线
- 中英文混排支持
- 文本可选中复制
- Dark/Light 主题跟随系统
- ⌘O 打开文件夹
- 首次启动自动加载 `~/.openclaw/workspace/`（如果存在）
- 使用 XcodeGen 生成 Xcode 项目，SPM 管理依赖

技术栈：
- SwiftUI + NavigationSplitView
- swift-markdown 0.5+ (SPM)
- @Observable macro for state management
- MarkupVisitor pattern for markdown → AttributedString

项目结构：
```
AIMemoryReader/Sources/
  App/          → AIMemoryReaderApp.swift
  Models/       → AppState.swift, FileNode.swift
  Views/        → ContentView.swift, SidebarView.swift, DetailView.swift
  Utilities/    → FileTreeBuilder.swift, MarkdownRenderer.swift
```
