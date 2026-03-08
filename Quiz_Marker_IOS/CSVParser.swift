import Foundation

struct CSVParser {
    /// Splits a CSV line into columns, respecting quotes and cleaning whitespace/\r characters.
    static func safeSplit(line: String) -> [String] {
        var result = [String]()
        var current = ""
        var isInsideQuotes = false
        
        // 1. Remove hidden Carriage Returns (\r) that break the last column (the answer)
        let cleanLine = line.replacingOccurrences(of: "\r", with: "")
        
        for char in cleanLine {
            if char == "\"" {
                isInsideQuotes.toggle()
            } else if char == "," && !isInsideQuotes {
                // 2. Trim quotes and extra spaces from the captured column
                result.append(current.trimmingCharacters(in: .init(charactersIn: "\" ")))
                current = ""
            } else {
                current.append(char)
            }
        }
        
        // 3. Add the last column and trim it
        result.append(current.trimmingCharacters(in: .init(charactersIn: "\" ")))
        
        // 4. Final Safety: Clean every single string in the array
        return result.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
