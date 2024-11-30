import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    @Published var currentText: String = ""
    @Published var formattedText: String = ""
    @Published var isAutoPasteEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isAutoPasteEnabled, forKey: "isAutoPasteEnabled")
        }
    }

    private var timer: Timer?
    private var isProcessingTest = false
    private var lastProcessedText: String?
    private var lastChangeCount: Int = 0
    let formattingService = TextFormattingService()

    private let pasteboard: NSPasteboard = {
        let pb = NSPasteboard.general
        pb.declareTypes([.string], owner: nil)
        return pb
    }()

    init() {
        isAutoPasteEnabled = UserDefaults.standard.bool(forKey: "isAutoPasteEnabled")
        lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }

    private func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func checkClipboard() {
        guard !isProcessingTest else { return }

        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard let text = pasteboard.string(forType: .string) else { return }
        guard text != lastProcessedText else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if text != self.currentText {
                self.currentText = text
                self.formattedText = self.formattingService.formatText(text)

                if self.isAutoPasteEnabled {
                    self.lastProcessedText = self.formattedText
                    self.writeToClipboard(self.formattedText)
                }
            }
        }
    }

    private func writeToClipboard(_ text: String) {
        pasteboard.clearContents()
        if pasteboard.setString(text, forType: .string) {
            lastChangeCount = pasteboard.changeCount
            lastProcessedText = text
        }
    }

    func formatCurrentText() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.formattedText = self.formattingService.formatText(self.currentText)
        }
    }

    func copyToClipboard(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.writeToClipboard(text)
        }
    }

    func runTestCase(_ text: String) -> String {
        isProcessingTest = true
        let result = formattingService.formatText(text)
        isProcessingTest = false
        return result
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopMonitoring()
    }
}