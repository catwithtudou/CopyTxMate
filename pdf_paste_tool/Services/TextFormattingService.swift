import Foundation

class TextFormattingService {
    // MARK: - Public Methods

    /// 处理文本的主入口
    /// - Parameter text: 原始文本
    /// - Returns: 格式化后的文本
    func formatText(_ text: String) -> String {
        // 确保输入文本是有效的
        guard !text.isEmpty else { return "" }

        // 确保文本编码正确
        guard let data = text.data(using: .utf8),
              let validText = String(data: data, encoding: .utf8) else {
            return text
        }

        var result = validText

        // 1. 处理多余的空格
        result = removeExtraSpaces(result)

        // 2. 处理标点符号
        result = convertPunctuation(result)

        // 3. 处理中英文混排
        result = formatMixedText(result)

        return result
    }

    // MARK: - Private Methods

    /// 移除多余的空格
    private func removeExtraSpaces(_ text: String) -> String {
        var result = text

        // 1. 处理换行和多余空格
        result = result.replacingOccurrences(
            of: "\\s*\\n\\s*",
            with: "",
            options: .regularExpression
        )

        // 2. 处理连续的空格
        result = result.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        // 3. 移除标点符号前后的空格
        let punctuationMarks = "，。！？：；,.!?:;（）()【】[]"
        for mark in punctuationMarks {
            result = result.replacingOccurrences(
                of: "\\s*\(NSRegularExpression.escapedPattern(for: String(mark)))\\s*",
                with: String(mark),
                options: .regularExpression
            )
        }

        // 4. 处理中英文之间的空格
        result = result.replacingOccurrences(
            of: "([\\p{Han}])\\s+([a-zA-Z0-9])",
            with: "$1 $2",
            options: .regularExpression
        )

        result = result.replacingOccurrences(
            of: "([a-zA-Z0-9])\\s+([\\p{Han}])",
            with: "$1 $2",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// 转换标点符号
    private func convertPunctuation(_ text: String) -> String {
        let punctuationMap: [Character: Character] = [
            ",": "，",
            ".": "。",
            "!": "！",
            "?": "？",
            ":": "：",
            ";": "；",
            "(": "（",
            ")": "）",
            "[": "【",
            "]": "】"
        ]

        var result = ""
        var previousChar: Character? = nil
        var isInChineseParentheses = false
        var isInEnglishParentheses = false

        for char in text {
            if char == "（" || char == "(" {
                // 根据上下文决定使用哪种括号
                let shouldUseChinesePunctuation = isChineseChar(previousChar)
                isInChineseParentheses = shouldUseChinesePunctuation
                isInEnglishParentheses = !shouldUseChinesePunctuation
                result.append(shouldUseChinesePunctuation ? "（" : "(")
            } else if char == "）" || char == ")" {
                // 使用与开始括号匹配的结束括号
                if isInChineseParentheses {
                    result.append("）")
                    isInChineseParentheses = false
                } else if isInEnglishParentheses {
                    result.append(")")
                    isInEnglishParentheses = false
                } else {
                    // 如果没有匹配的开始括号，根据上下文决定
                    result.append(isChineseChar(previousChar) ? "）" : ")")
                }
            } else if let mappedChar = punctuationMap[char] {
                // 如果在括号内，使用对应的标点类型
                let shouldUseChinesePunctuation = isInChineseParentheses || (!isInEnglishParentheses && isChineseChar(previousChar))
                result.append(shouldUseChinesePunctuation ? mappedChar : char)
            } else if let originalChar = punctuationMap.first(where: { $0.value == char })?.key {
                // 如果在括号内，使用对应的标点类型
                let shouldUseEnglishPunctuation = isInEnglishParentheses || (!isInChineseParentheses && !isChineseChar(previousChar))
                result.append(shouldUseEnglishPunctuation ? originalChar : char)
            } else {
                result.append(char)
            }
            previousChar = char
        }

        return result
    }

    /// 格式化中英文混排
    private func formatMixedText(_ text: String) -> String {
        var result = text

        // 在中英文之间添加空格（排除标点符号）
        let chinesePattern = "[\\p{Han}]"
        let englishPattern = "[a-zA-Z0-9]+"

        // 中文后面跟英文
        result = result.replacingOccurrences(
            of: "(\(chinesePattern))(\(englishPattern))",
            with: "$1 $2",
            options: .regularExpression
        )

        // 英文后面跟中文
        result = result.replacingOccurrences(
            of: "(\(englishPattern))(\(chinesePattern))",
            with: "$1 $2",
            options: .regularExpression
        )

        return result
    }

    /// 判断字符是否为中文
    private func isChineseChar(_ char: Character?) -> Bool {
        guard let char = char else { return false }
        let scalars = String(char).unicodeScalars
        return scalars.contains(where: {
            $0.value >= 0x4E00 && $0.value <= 0x9FFF
        })
    }
}