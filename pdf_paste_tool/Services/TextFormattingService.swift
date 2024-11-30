import Foundation

class TextFormattingService {
    // 缓存正则表达式以提高性能
    private static let chinesePattern = "([\\p{Han}，。！？：；（）【】])"
    private static let chineseSpacePattern = "\(chinesePattern)\\s+\(chinesePattern)"

    // 缓存标点符号映射
    private static let punctuationMap: [Character: Character] = [
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

    // 缓存正则表达式模式
    private static let mixedTextPatterns: [(pattern: String, replacement: String)] = [
        ("([\\p{Han}，。！？：；（）【】])\\s*([a-zA-Z0-9])", "$1 $2"),
        ("([a-zA-Z0-9])\\s*([\\p{Han}，。！？：；（）【】])", "$1 $2")
    ]

    /// 格式化文本的主入口
    func formatText(_ text: String) -> String {
        // 确保输入文本是有效的
        guard !text.isEmpty else { return "" }

        // 确保文本编码正确
        guard let data = text.data(using: .utf8),
              let validText = String(data: data, encoding: .utf8) else {
            return text
        }

        var result = validText

        // 使用 autoreleasepool 来管理内存
        autoreleasepool {
            // 1. 处理多余的空格
            result = removeExtraSpaces(result)

            // 2. 处理标点符号
            result = convertPunctuation(result)

            // 3. 处理中英文混排
            result = formatMixedText(result)
        }

        return result
    }

    /// 处理多余的空格
    private func removeExtraSpaces(_ text: String) -> String {
        var result = text

        autoreleasepool {
            // 1. 处理换行和多余空格
            result = result.replacingOccurrences(
                of: "\\s*\\n\\s*",
                with: "",
                options: .regularExpression
            )

            // 2. 处理中文字符之间的空格
            while result.range(of: Self.chineseSpacePattern, options: .regularExpression) != nil {
                result = result.replacingOccurrences(
                    of: Self.chineseSpacePattern,
                    with: "$1$2",
                    options: .regularExpression
                )
            }

            // 3. 处理连续的空格
            result = result.replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )

            // 4. 处理中英文混排的空格
            for (pattern, replacement) in Self.mixedTextPatterns {
                result = result.replacingOccurrences(
                    of: pattern,
                    with: replacement,
                    options: .regularExpression
                )
            }

            // 5. 处理标点符号
            result = processPunctuation(result)
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// 处理标点符号
    private func processPunctuation(_ text: String) -> String {
        var result = text

        // 处理英文标点
        let punctuationMarks = ",.!?:;"
        for mark in punctuationMarks {
            result = result.replacingOccurrences(
                of: "\\s*\(NSRegularExpression.escapedPattern(for: String(mark)))\\s*",
                with: String(mark),
                options: .regularExpression
            )
        }

        // 处理中文标点
        let chinesePunctuationMarks = "，。！？：；（）【】"
        for mark in chinesePunctuationMarks {
            result = result.replacingOccurrences(
                of: "\\s*\(NSRegularExpression.escapedPattern(for: String(mark)))\\s*",
                with: String(mark),
                options: .regularExpression
            )
        }

        return result
    }

    /// 转换标点符号
    private func convertPunctuation(_ text: String) -> String {
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
            } else if let mappedChar = Self.punctuationMap[char] {
                // 如果在括号内，使用对应的标点类型
                let shouldUseChinesePunctuation = isInChineseParentheses || (!isInEnglishParentheses && isChineseChar(previousChar))
                result.append(shouldUseChinesePunctuation ? mappedChar : char)
            } else if let originalChar = Self.punctuationMap.first(where: { $0.value == char })?.key {
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