import Foundation

struct CSVParser {
    static func safeSplit(line: String) -> [String] {
        var result = [String]()
        var current = ""
        var isInsideQuotes = false
        
        for char in line {
            if char == "\"" {
                isInsideQuotes.toggle()
            } else if char == "," && !isInsideQuotes {
                result.append(current.trimmingCharacters(in: .init(charactersIn: "\" ")))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .init(charactersIn: "\" ")))
        return result
    }
}