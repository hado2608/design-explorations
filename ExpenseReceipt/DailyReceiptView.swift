import SwiftUI

// Matches the three states from the Figma design:
//   Empty   — no items, centered "+ tap to add expense" button
//   Filling — items list + active text-entry row (row with cursor)
//   Filled  — complete list with item count & total

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

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "135787").ignoresSafeArea()

            VStack(spacing: 0) {
                tabHeader
                receiptCard
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Tab Header

    private var tabHeader: some View {
        HStack(alignment: .bottom, spacing: -4) {
            // Active "DAILY" tab (front)
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "546774"))
                Text("DAILY")
                    .font(.custom("InstrumentSans-SemiBold", size: 14))
                    .foregroundColor(Color(hex: "546774"))
                    .kerning(2.24)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Color(hex: "f0e4da")
                    .clipShape(PaperTabShape())
            )
            .zIndex(1)

            // Inactive second tab (behind)
            Color(hex: "c8bdb5")
                .frame(width: 60, height: 40)
                .clipShape(PaperTabShape())
                .zIndex(0)
        }
        .padding(.leading, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Receipt Card

    private var receiptCard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                asteriskDivider
                columnHeaders
                asteriskDivider
                expenseRows
                    .padding(.top, 8)

                if !isAdding {
                    addButton
                        .frame(maxWidth: items.isEmpty ? .infinity : nil,
                               alignment: items.isEmpty ? .center : .leading)
                        .padding(.top, items.isEmpty ? 60 : 16)
                }

                Spacer(minLength: 60)

                if !items.isEmpty {
                    footer
                }

                asteriskDivider
                    .padding(.top, 8)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
        }
        .background(Color(hex: "f0e4da"))
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateString)
                .font(.custom("InstrumentSerif-Regular", size: 48))
                .foregroundColor(Color(hex: "135787"))
                .tracking(-2.4)

            TextField("write a description", text: $description)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "546774"))
                .tint(Color(hex: "135787"))
        }
        .padding(.bottom, 32)
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("QTY").frame(width: 52, alignment: .leading)
            Text("ITEM").frame(maxWidth: .infinity, alignment: .leading)
            Text("AMT").frame(width: 52, alignment: .trailing)
        }
        .font(.system(size: 14))
        .foregroundColor(Color(hex: "546774").opacity(0.6))
        .textCase(.uppercase)
        .padding(.vertical, 6)
    }

    private var asteriskDivider: some View {
        Text(String(repeating: "* ", count: 22).trimmingCharacters(in: .whitespaces))
            .font(.custom("CutiveMono-Regular", size: 14))
            .foregroundColor(Color(hex: "546774").opacity(0.6))
            .lineLimit(1)
            .padding(.vertical, 4)
    }

    private var expenseRows: some View {
        VStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                HStack(spacing: 0) {
                    Text(String(format: "%02d", idx + 1))
                        .frame(width: 52, alignment: .leading)
                    Text(item.name.uppercased())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("$\(item.amount)")
                        .frame(width: 52, alignment: .trailing)
                }
                .font(.custom("CutiveMono-Regular", size: 16))
                .foregroundColor(Color(hex: "546774"))
            }

            if isAdding {
                HStack(spacing: 0) {
                    Text(String(format: "%02d", items.count + 1))
                        .frame(width: 52, alignment: .leading)
                        .font(.custom("CutiveMono-Regular", size: 16))
                        .foregroundColor(Color(hex: "546774"))

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
                        .frame(width: 52, alignment: .trailing)
                }
                .onAppear { nameFieldFocused = true }
            }
        }
    }

    private var addButton: some View {
        Button(action: { isAdding = true }) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 36, weight: .thin))
                Text("tap to add expense")
                    .font(.system(size: 16))
                    .tracking(-0.32)
            }
            .foregroundColor(Color(hex: "255c86"))
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            asteriskDivider.padding(.bottom, 8)
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
        .foregroundColor(Color(hex: "546774"))
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

// MARK: - Tab Shape

struct PaperTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let taper: CGFloat = 10
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: taper, y: 0))
        path.addLine(to: CGPoint(x: rect.width - taper, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Previews

#Preview("Empty") {
    DailyReceiptView(date: Date(), description: .constant(""), items: .constant([]))
}

#Preview("Filled") {
    DailyReceiptView(
        date: Date(),
        description: .constant("groceries"),
        items: .constant([
            ExpenseItem(name: "Trader Joes", amount: 75),
            ExpenseItem(name: "Coffee", amount: 12),
            ExpenseItem(name: "Lunch", amount: 18),
        ])
    )
}
