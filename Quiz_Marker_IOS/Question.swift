import Foundation

struct Question: Identifiable, Hashable {
    let id = UUID() // Required for SwiftUI Lists
    let number: String
    let unit: String
    let chapter: String
    let text: String
    let choices: [String: String]
    let answer: String
}
