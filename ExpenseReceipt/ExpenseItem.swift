import Foundation

struct ExpenseItem: Identifiable {
    let id = UUID()
    var name: String
    var amount: Int
}
