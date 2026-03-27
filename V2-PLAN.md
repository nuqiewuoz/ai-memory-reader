# AI Memory Reader — V2 Plan

## V2 范围

### V2.1: 编辑模式
- 实时预览：左侧编辑、右侧渲染，或切换模式
- 基于 TextEditor / NSTextView 的 Markdown 编辑器
- 语法高亮（编辑态）
- 自动保存
- ⌘S 手动保存
- 编辑/预览切换快捷键（⌘E）

### V2.2: iPhone 适配
- 用 SwiftUI 多平台支持，共享核心代码
- iPhone 上：单栏布局（文件列表 → 阅读页 push）
- 支持 Files app 打开 .md 文件
- 适配 iPhone 屏幕尺寸和安全区域
- Dynamic Type 支持

### V2.3: AI 工具调用接口
- **URL Scheme**：`aimemoryreader://open?path=/path/to/file.md`
- **CLI**：`aimr open /path/to/file.md`（命令行打开指定文件）
- **MCP Server**（可选）：让 AI agent 通过 MCP 协议查询/打开文件
- 支持 AI agent 指定打开某个文件、跳转到某个 heading

## 里程碑

| 阶段 | 内容 | 预估 |
|---|---|---|
| V2.1-M1 | 编辑器基础框架 + 编辑/预览切换 | 1-2 天 |
| V2.1-M2 | 语法高亮 + 自动保存 | 1 天 |
| V2.2-M1 | iPhone target + 单栏布局 | 1 天 |
| V2.2-M2 | Files app 集成 + 适配打磨 | 半天 |
| V2.3-M1 | URL Scheme + CLI | 半天 |
| V2.3-M2 | MCP Server（可选） | 1 天 |

## 开发日志

### 2026-03-26 — V2 Plan 确认
- V2.1（编辑模式）+ V2.2（iPhone）+ V2.3（AI 工具调用）
- 开始 V2.1 开发

### 2026-03-26 — V2.3 完成：AI 工具调用接口
#### V2.3-M1: URL Scheme + CLI
- URL Scheme 处理器：`aimemoryreader://open?path=/path/to/file.md&heading=Heading`
- macOS 和 iOS 均支持通过 URL scheme 打开文件并跳转到指定 heading
- AppState 新增 `pendingURLHeading` 属性，DetailView 监听并自动滚动
- CLI 工具 `aimr`：shell 脚本，通过 `open` 命令调用 URL scheme
- 用法：`aimr open /path/to/file.md --heading "Section Title"`
- URL scheme 已在 Info.plist 中注册（V1 已有）

### 2026-03-26 — V2.2 完成：iPhone 适配
#### V2.2-M1: iOS target + 跨平台共享代码
- 新增 iOS target（AIMemoryReader-iOS），最低支持 iOS 17
- project.yml 同时定义 macOS 和 iOS 两个 target，共享同一套源码
- 使用 `#if os(macOS)` / `#if os(iOS)` 隔离平台特定代码
- macOS 保持 NavigationSplitView 布局不变
- iOS 使用 NavigationStack：文件列表 → push 到阅读页
- iOS 通过 UIDocumentPickerViewController 从 Files app 打开 .md 文件
- Info.plist 注册 UTType（net.daringfireball.markdown）+ UISupportsDocumentBrowser
- MarkdownUI 主题支持 Dynamic Type（baseFontSize / headingScale 按平台适配）
- SplashCodeSyntaxHighlighter 跨平台适配（NSFont → UIFont）
- macOS 专有代码已隔离：FSEvents 文件监视、NSOpenPanel、NSTextView 编辑器
- 编辑模式仅 macOS 可用（NSTextView wrapper）

### 2026-03-26 — V2.1 完成：编辑模式
#### V2.1-M1: 编辑器框架 + 编辑/预览切换
- 新增 `MarkdownEditorView.swift`：基于 NSTextView 的 Markdown 编辑器
- DetailView 中添加 Read/Edit 模式切换（铅笔/眼睛图标按钮）
- ⌘E 快捷键切换编辑/预览模式
- 编辑器使用 SF Mono 等宽字体（14pt）
- 支持行号显示（LineNumberRulerView）
- 支持标准文本编辑（undo/redo、cut/copy/paste、Find面板）

#### V2.1-M2: 语法高亮 + 自动保存
- Markdown 语法高亮（MarkdownHighlighter）：
  - 标题（#）：蓝色 + 粗体 + 按级别缩放字号
  - 粗体（**text**）：粗体渲染
  - 斜体（*text*）：斜体渲染
  - 代码（`inline` 和 ```blocks```）：粉色 + 半透明背景
  - 链接：蓝色 + 下划线
  - 引用（>）：灰色
  - 列表标记、水平线等
- 自动保存：2 秒无输入后自动保存（debounce）
- ⌘S 手动保存
- "Saved" 状态指示器（绿色勾 + 文字，2 秒后消失）
- 编辑 → 预览切换时自动保存并刷新渲染视图
- 暗色/亮色模式自适应高亮颜色
