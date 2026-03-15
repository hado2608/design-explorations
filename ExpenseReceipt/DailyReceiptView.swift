import SwiftUI

struct DailyReceiptView: View {
    let date: Date
    @Binding var description: String
    @Binding var items: [ExpenseItem]

    @State private var isAdding = false
    @State private var editingIndex: Int? = nil
    @State private var newItemName = ""
    @State private var newItemAmount = ""

    private enum InputField: Hashable { case name, amount }
    @FocusState private var focusedField: InputField?

    private var isEditing: Bool { editingIndex != nil || isAdding }

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
        .safeAreaInset(edge: .bottom) {
            if isEditing {
                doneButton.padding(.bottom, 12)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }

    private var doneButton: some View {
        Button(action: { commitEntry(andDismiss: true) }) {
            Text("done")
                .font(.custom("InstrumentSans-SemiBold", size: 16))
                .foregroundColor(Color(hex: "f0e4da"))
                .tracking(0.3)
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(Color(hex: "135787"))
                .clipShape(Capsule())
                .shadow(color: Color(red: 0.11, green: 0.20, blue: 0.28).opacity(0.2),
                        radius: 30, x: 4, y: 4)
        }
    }

    // MARK: - Tab Header

    private var tabHeader: some View {
        HStack(alignment: .bottom, spacing: -2) {
            tabButton(label: "DAILY", icon: "calendar", isActive: true)
            tabButton(label: "MONTHLY", icon: nil, isActive: false)
            Spacer()
        }
        .padding(.leading, 20)
        .padding(.top, 8)
    }

    private func tabButton(label: String, icon: String?, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "546774"))
            }
            Text(label)
                .font(.custom("InstrumentSans-SemiBold", size: 13))
                .foregroundColor(Color(hex: "546774"))
                .kerning(2.0)
        }
        .frame(width: 120, height: 44)
        .background(
            (isActive ? Color(hex: "f0e4da") : Color(hex: "c0b5ac"))
                .clipShape(PaperTabShape())
        )
        .zIndex(isActive ? 1 : 0)
    }

    // MARK: - Receipt Card

    private var receiptCard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                columnHeaders
                divider
                itemsArea
                    .padding(.top, 8)

                Spacer(minLength: 32)

                if !items.isEmpty {
                    divider.padding(.bottom, 8)
                    footer
                }

                // Full-width tap catcher for empty space below content
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .contentShape(Rectangle())
                    .onTapGesture { if !isEditing { startAdding() } }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { if !isEditing { startAdding() } }
            )
        }
        .background(
            ZStack {
                Color(hex: "f0e4da")
                Image("paper").resizable(resizingMode: .tile).opacity(0.35)
            }
        )
        .clipShape(TornReceiptShape())
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateString)
                .font(.custom("InstrumentSerif-Regular", size: 48))
                .foregroundColor(Color(hex: "135787"))
                .tracking(-2.4)

            TextField("write a description", text: $description)
                .font(.custom("InstrumentSans-Regular", size: 16))
                .foregroundColor(Color(hex: "546774"))
                .tint(Color(hex: "135787"))
        }
        .padding(.bottom, 24)
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("QTY").frame(width: 44, alignment: .leading)
            Text("ITEM").frame(maxWidth: .infinity, alignment: .leading)
            Text("AMT").frame(width: 52, alignment: .trailing)
        }
        .font(.custom("InstrumentSans-Regular", size: 14))
        .foregroundColor(Color(hex: "546774").opacity(0.6))
        .textCase(.uppercase)
        .padding(.vertical, 6)
    }

    private var divider: some View {
        Text(String(repeating: "* ", count: 40))
            .font(.custom("CutiveMono-Regular", size: 14))
            .foregroundColor(Color(hex: "546774").opacity(0.6))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.vertical, 4)
    }

    private var itemsArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                if editingIndex == idx {
                    entryRow(number: idx + 1)
                } else {
                    // Tappable display row
                    HStack(spacing: 0) {
                        Text(String(format: "%02d", idx + 1))
                            .frame(width: 44, alignment: .leading)
                            .foregroundColor(Color(hex: "546774").opacity(0.7))
                        Text(item.name.uppercased())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(hex: "255c86"))
                            .onTapGesture { startEditing(index: idx, field: .name) }
                        Text("$\(item.amount)")
                            .frame(width: 52, alignment: .trailing)
                            .foregroundColor(Color(hex: "255c86"))
                            .onTapGesture { startEditing(index: idx, field: .amount) }
                    }
                    .font(.custom("CutiveMono-Regular", size: 16))
                    .contentShape(Rectangle())
                }
            }

            if isAdding {
                entryRow(number: items.count + 1)
            }

            // Empty state label — tap handled by receipt background
            if items.isEmpty && !isAdding {
                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .thin))
                    Text("tap to add expense")
                        .font(.custom("InstrumentSans-Regular", size: 16))
                        .tracking(-0.32)
                }
                .foregroundColor(Color(hex: "255c86"))
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // Shared entry row for both new items and editing existing ones
    private func entryRow(number: Int) -> some View {
        HStack(spacing: 0) {
            Text(String(format: "%02d", number))
                .frame(width: 44, alignment: .leading)
                .foregroundColor(Color(hex: "546774").opacity(0.7))

            TextField("", text: $newItemName)
                .foregroundColor(Color(hex: "255c86"))
                .textInputAutocapitalization(.characters)
                .frame(maxWidth: .infinity, alignment: .leading)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .amount }

            TextField("0", text: $newItemAmount)
                .foregroundColor(Color(hex: "255c86"))
                .multilineTextAlignment(.trailing)
                .frame(width: 52, alignment: .trailing)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .amount)
                // Toolbar above number pad with a Return key
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(action: { commitEntry(andDismiss: false) }) {
                            Image(systemName: "return")
                                .foregroundColor(Color(hex: "135787"))
                        }
                    }
                }
        }
        .font(.custom("CutiveMono-Regular", size: 16))
        .tint(Color(hex: "135787"))
        .onAppear {
            // Focus name unless we're jumping straight to amount (tap on price)
            if focusedField == nil { focusedField = .name }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack {
                Text("ITEM COUNT")
                    .foregroundColor(Color(hex: "546774").opacity(0.6))
                Spacer()
                Text(String(format: "%02d", items.count))
                    .foregroundColor(Color(hex: "175987"))
                    .font(.custom("InstrumentSans-Medium", size: 16))
            }
            HStack {
                Text("TOTAL:")
                    .foregroundColor(Color(hex: "546774").opacity(0.6))
                Spacer()
                Text("$\(total)")
                    .foregroundColor(Color(hex: "175987"))
                    .font(.custom("InstrumentSans-Medium", size: 16))
            }
        }
        .font(.custom("InstrumentSans-Regular", size: 16))
        .textCase(.uppercase)
    }

    // MARK: - Actions

    private func startAdding() {
        newItemName = ""
        newItemAmount = ""
        editingIndex = nil
        isAdding = true
        focusedField = .name
    }

    private func startEditing(index: Int, field: InputField) {
        guard !isEditing else { return }
        newItemName = items[index].name
        newItemAmount = items[index].amount == 0 ? "" : "\(items[index].amount)"
        editingIndex = index
        isAdding = false
        focusedField = field
    }

    private func commitEntry(andDismiss: Bool) {
        let name = newItemName.trimmingCharacters(in: .whitespaces)

        if let idx = editingIndex {
            // Save edit to existing item
            if !name.isEmpty {
                items[idx].name = name
                items[idx].amount = Int(newItemAmount) ?? 0
            }
            editingIndex = nil
            newItemName = ""
            newItemAmount = ""
            focusedField = andDismiss ? nil : .name

        } else {
            // Commit new item
            if !name.isEmpty {
                items.append(ExpenseItem(name: name, amount: Int(newItemAmount) ?? 0))
            }
            newItemName = ""
            newItemAmount = ""
            if andDismiss {
                isAdding = false
                focusedField = nil
            } else {
                focusedField = .name
            }
        }
    }
}

// MARK: - Shapes

struct PaperTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let taper: CGFloat = 12, r: CGFloat = 5
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: taper, y: r))
        path.addArc(center: CGPoint(x: taper + r, y: r), radius: r,
                    startAngle: .degrees(180), endAngle: .degrees(-90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.width - taper - r, y: 0))
        path.addArc(center: CGPoint(x: rect.width - taper - r, y: r), radius: r,
                    startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct TornReceiptShape: Shape {
    var toothCount: Int = 22
    var cornerRadius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        let toothWidth = rect.width / CGFloat(toothCount)
        let toothHeight: CGFloat = 10
        let r = cornerRadius
        var path = Path()

        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: rect.width - r, y: 0))
        path.addArc(center: CGPoint(x: rect.width - r, y: r), radius: r,
                    startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - toothHeight))

        var x = rect.width
        while x > 0 {
            path.addLine(to: CGPoint(x: x - toothWidth / 2, y: rect.height))
            x -= toothWidth
            path.addLine(to: CGPoint(x: max(x, 0), y: rect.height - toothHeight))
        }

        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(center: CGPoint(x: r, y: r), radius: r,
                    startAngle: .degrees(180), endAngle: .degrees(-90), clockwise: false)
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
