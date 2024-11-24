import SwiftUI
import AppKit

struct MainView: View {
    @StateObject private var clipboardManager = ClipboardManager()
    @State private var testResults: String = ""
    @State private var isShowingTestResults: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""

    private let testCases = [
        " Hello  world  你好  世界 ",
        "你好,世界.这是一个测试!",
        "Hello，world。This is a test！",
        "这是一个test测试案例",
        "这是(test)测试",
        "Hello世界,这是一个test案例,包含english和中文,以及标点符号(punctuation)!"
    ]

    var body: some View {
        VStack(spacing: 8) {
            // 标题栏 - 调整对齐
            VStack(alignment: .leading) {
                Text("CopyTxMate")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 12)  // 与内容区域保持一致的左对齐
                    .padding(.vertical, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.windowBackgroundColor))

            // 主要内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // 原始文本区域
                    VStack(alignment: .leading, spacing: 4) {
                        Text("待处理的文本：")
                            .font(.system(size: 13, weight: .medium))
                        NSTextEditorView(text: Binding(
                            get: { clipboardManager.currentText },
                            set: { clipboardManager.currentText = $0 }
                        ))
                        .frame(height: 70)
                        .border(Color(NSColor.separatorColor), width: 1)
                    }

                    // 格式化文本区域
                    VStack(alignment: .leading, spacing: 4) {
                        Text("格式化后的文本：")
                            .font(.system(size: 13, weight: .medium))
                        NSTextEditorView(text: Binding(
                            get: { clipboardManager.formattedText },
                            set: { clipboardManager.formattedText = $0 }
                        ))
                        .frame(height: 70)
                        .border(Color(NSColor.separatorColor), width: 1)
                    }

                    // 测试结果区域
                    if isShowingTestResults {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("测试用例结果：")
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                MacButton(
                                    action: {
                                        withAnimation {
                                            isShowingTestResults = false
                                            testResults = ""
                                        }
                                    },
                                    label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color(NSColor.secondaryLabelColor))
                                    }
                                )
                            }

                            NSTextEditorView(text: .constant(testResults))
                                .frame(height: 100)
                                .border(Color(NSColor.separatorColor), width: 1)
                        }
                    }

                    // 底部按钮区域
                    HStack(spacing: 8) {
                        MacButton(title: "格式化", systemImage: "text.quote") {
                            clipboardManager.formatCurrentText()
                            showToast(message: "文本格式化完成")
                            NSSound.beep()  // 添加音效反馈
                        }
                        .keyboardShortcut("f", modifiers: .command)

                        MacButton(title: "复制结果", systemImage: "doc.on.doc") {
                            clipboardManager.copyToClipboard(clipboardManager.formattedText)
                            showToast(message: "格式化结果已复制到剪贴板")
                            NSSound.beep()  // 添加音效反馈
                        }
                        .keyboardShortcut("v", modifiers: .command)
                        .disabled(clipboardManager.isAutoPasteEnabled)

                        MacButton(
                            title: isShowingTestResults ? "隐藏测试" : "运行测试",
                            systemImage: isShowingTestResults ? "eye.slash" : "play.fill",
                            helpText: "可查看部分格式化后处理的示例"  // 添加帮助提示
                        ) {
                            if !isShowingTestResults {
                                runTests()
                                showToast(message: "测试用例运行完成")
                                NSSound.beep()  // 添加音效反馈
                            } else {
                                withAnimation {
                                    isShowingTestResults = false
                                    testResults = ""
                                }
                            }
                        }
                        .keyboardShortcut("t", modifiers: .command)

                        MacButton(
                            title: clipboardManager.isAutoPasteEnabled ? "关闭自动格式化" : "开启自动格式化",
                            systemImage: clipboardManager.isAutoPasteEnabled ? "scissors.badge.ellipsis" : "scissors",
                            helpText: "开启后，复制的文本会自动进行格式化处理"
                        ) {
                            clipboardManager.isAutoPasteEnabled.toggle()
                            showToast(message: clipboardManager.isAutoPasteEnabled ?
                                "已开启自动格式化功能，复制文本将自动处理" :
                                "已关闭自动格式化功能，需手动处理文本")
                            NSSound.beep()  // 添加音效反馈
                        }
                        .keyboardShortcut("a", modifiers: .command)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 2)
            }
        }
        .frame(minWidth: 550, minHeight: 280)
        .frame(idealWidth: 550, idealHeight: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            MacToastView(message: toastMessage, isShowing: $showToast)
                .animation(.easeInOut(duration: 0.3), value: showToast)
        )
    }

    private func showToast(message: String) {
        toastMessage = message
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }

    private func runTests() {
        DispatchQueue.main.async {
            var results = "测试结果：\n\n"

            for (index, testCase) in testCases.enumerated() {
                let formatted = clipboardManager.runTestCase(testCase)
                results += "测试 #\(index + 1)\n"
                results += "输入：\(testCase)\n"
                results += "输出：\(formatted)\n\n"
            }

            withAnimation {
                testResults = results
                isShowingTestResults = true
            }
        }
    }
}

// MARK: - macOS 原生文本编辑器
struct NSTextEditorView: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // 基本配置
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.isEditable = false
        textView.isSelectable = true

        // 设置文本容器选项
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.bounds.width,
            height: .greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true

        // 禁用自动功能
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        // 配置菜单
        let menu = NSMenu()

        // 复制菜单项
        let copyItem = NSMenuItem(
            title: "复制",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        copyItem.target = textView
        menu.addItem(copyItem)

        // 全选菜单项
        let selectAllItem = NSMenuItem(
            title: "全选",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        selectAllItem.target = textView
        menu.addItem(selectAllItem)

        textView.menu = menu

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
            super.init()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }

        // 处理菜单验证
        func textView(_ textView: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            menu.items.forEach { item in
                if item.action == #selector(NSText.copy(_:)) {
                    item.isEnabled = textView.selectedRange().length > 0
                }
            }
            return menu
        }

        // 允许选择操作
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return false
        }
    }
}

// 添加 String 扩展
extension String {
    func substring(with range: NSRange) -> String? {
        guard let range = Range(range, in: self) else { return nil }
        return String(self[range])
    }
}

// MARK: - macOS 风格按钮
struct MacButton: View {
    let title: String?
    let systemImage: String?
    let helpText: String?
    let action: () -> Void
    let label: (() -> AnyView)?

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var showingHelp = false

    init(
        title: String? = nil,
        systemImage: String? = nil,
        helpText: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.helpText = helpText
        self.action = action
        self.label = nil
    }

    init(action: @escaping () -> Void, label: @escaping () -> some View) {
        self.title = nil
        self.systemImage = nil
        self.helpText = nil
        self.action = action
        self.label = { AnyView(label()) }
    }

    var body: some View {
        Button(action: action) {
            if let label = label {
                label()
            } else {
                HStack(spacing: 4) {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 13))
                    }
                    if let title = title {
                        Text(title)
                            .font(.system(size: 13))
                    }
                    if let helpText = helpText {
                        GeometryReader { geometry in
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 13))
                                .foregroundColor(Color(NSColor.secondaryLabelColor))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    showingHelp ? AnyView(
                                        VStack {
                                            Text(helpText)
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(NSColor.labelColor))
                                                .padding(8)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(width: 250)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color(NSColor.windowBackgroundColor))
                                                        .shadow(
                                                            color: Color.black.opacity(0.2),
                                                            radius: 4,
                                                            x: 0,
                                                            y: 2
                                                        )
                                                )
                                        }
                                        .offset(y: -35)
                                        .offset(x: -117)
                                    ) : AnyView(EmptyView())
                                )
                                .onHover { hovering in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showingHelp = hovering
                                    }
                                }
                        }
                        .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .buttonStyle(MacButtonStyle(isHovered: isHovered, isPressed: isPressed))
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - macOS 风格按钮样式
struct MacButtonStyle: ButtonStyle {
    let isHovered: Bool
    let isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
    }

    private var backgroundColor: Color {
        if isPressed {
            return Color(NSColor.selectedControlColor)
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor)
        } else {
            return Color(NSColor.controlColor)
        }
    }
}

// MARK: - macOS 风格 Toast 视图
struct MacToastView: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                Text(message)
                    .foregroundColor(Color(NSColor.labelColor))
                    .font(.system(size: 13))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .shadow(
                                color: Color(NSColor.shadowColor).opacity(0.3),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    )
                    .padding(.bottom, 20)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}