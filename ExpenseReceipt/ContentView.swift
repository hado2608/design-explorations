import SwiftUI

struct ContentView: View {
    @State private var items: [ExpenseItem] = []
    @State private var description: String = ""

    var body: some View {
        DailyReceiptView(
            date: Date(),
            description: $description,
            items: $items
        )
    }
}

#Preview {
    ContentView()
}
