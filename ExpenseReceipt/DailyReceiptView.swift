import SwiftUI

// Matches the three states from the Figma design:
//   Empty   — no items, centered "+ ADD AN EXPENSE" button
//   Filling — items list + active text-entry row (row with cursor)
//   Filled  — complete list with item count & total, date turns blue

struct DailyReceiptView: View {
    let date: Date
    @Binding var description: String
    @Binding var items: [ExpenseItem]

    @State private var isAdding = false
    @State private var newItemName = ""
    @State private var newItemAmount = ""
    @FocusState private var nameFieldFocused: Bool

    // MARK: - Computed

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    private var total: Int { items.reduce(0) { $0 + $1.amount } }

    /// Blue when the receipt is finalized (items present, not actively editing)
    private var headerColor: Color {
        !items.isEmpty && !isAdding ? Color(hex: "135787") : .black
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                columnHeaders
                Divider().overlay(Color.black)
                expenseRows.padding(.top, 16)

                if !isAdding {
                    addButton
                        .frame(maxWidth: items.isEmpty ? .infinity : nil,
                               alignment: items.isEmpty ? .center : .leading)
                        .padding(.top, items.isEmpty ? 40 : 16)
                }

                Spacer(minLength: 48)

                if !items.isEmpty {
                    footer
                }
            }
            .padding(.horizontal, 24)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateString)
                .font(.custom("CoFoRaffine-Medium", size: 32))
                .foregroundColor(headerColor)

            TextField("write a description", text: $description)
                .font(.custom("CoFoRaffine-Regular", size: 16))
                .foregroundColor(headerColor)
                .tint(headerColor)
        }
        .padding(.top, 24)
        .padding(.bottom, 51)
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("QTY").frame(width: 60, alignment: .leading)
            Text("ITEM").frame(maxWidth: .infinity, alignment: .leading)
            Text("AMT").frame(width: 60, alignment: .trailing)
        }
        .font(.custom("CutiveMono-Regular", size: 16))
        .foregroundColor(.black)
        .padding(.bottom, 8)
    }

    private var expenseRows: some View {
        VStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                HStack(spacing: 0) {
                    Text(String(format: "%02d", idx + 1))
                        .frame(width: 60, alignment: .leading)
                    Text(item.name.uppercased())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("$\(item.amount)")
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.custom("CutiveMono-Regular", size: 16))
                .foregroundColor(.black)
            }

            if isAdding {
                HStack(spacing: 0) {
                    Text(String(format: "%02d", items.count + 1))
                        .frame(width: 60, alignment: .leading)
                        .font(.custom("CutiveMono-Regular", size: 16))
                        .foregroundColor(.black)

                    TextField("", text: $newItemName)
                        .font(.custom("CutiveMono-Regular", size: 16))
                        .textInputAutocapitalization(.characters)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .focused($nameFieldFocused)
                        .onSubmit { submitItem() }

                    TextField("0", text: $newItemAmount)
                        .font(.custom("CutiveMono-Regular", size: 16))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60, alignment: .trailing)
                }
                .onAppear { nameFieldFocused = true }
            }
        }
    }

    private var addButton: some View {
        Button(action: { isAdding = true }) {
            HStack(spacing: 9) {
                Image(systemName: "plus").font(.system(size: 14, weight: .regular))
                Text("ADD AN EXPENSE")
                    .font(.custom("CutiveMono-Regular", size: 16))
            }
            .foregroundColor(.black)
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.black).padding(.bottom, 8)
            HStack {
                Text("ITEM COUNT")
                Spacer()
                Text(String(format: "%02d", items.count))
            }
            .padding(.bottom, 8)
            HStack {
                Text("TOTAL:")
                Spacer()
                Text("$\(total)")
            }
        }
        .font(.custom("CutiveMono-Regular", size: 16))
        .foregroundColor(.black)
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func submitItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            isAdding = false
            newItemName = ""
            newItemAmount = ""
            return
        }
        items.append(ExpenseItem(name: name, amount: Int(newItemAmount) ?? 0))
        newItemName = ""
        newItemAmount = ""
        isAdding = false
    }
}

#Preview("Empty") {
    DailyReceiptView(date: Date(), description: .constant(""), items: .constant([]))
}

#Preview("Filled") {
    DailyReceiptView(
        date: Date(),
        description: .constant("groceries"),
        items: .constant([
            ExpenseItem(name: "Trader Joes", amount: 75),
            ExpenseItem(name: "Trader Joes", amount: 75),
            ExpenseItem(name: "Trader Joes", amount: 75),
            ExpenseItem(name: "Trader Joes", amount: 75),
            ExpenseItem(name: "Trader Joes", amount: 75),
            ExpenseItem(name: "Trader Joes", amount: 75),
        ])
    )
}
