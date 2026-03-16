import SwiftUI
import UIKit

// MARK: - Tab

enum AppTab { case daily, monthly }

struct DailyReceiptView: View {
    let date: Date
    @Binding var description: String
    @Binding var items: [ExpenseItem]

    @State private var selectedTab: AppTab = .daily
    @State private var isAdding = false
    @State private var editingIndex: Int? = nil
    @State private var newItemName = ""
    @State private var newItemAmount = ""

    private enum InputField: Hashable { case name, amount }
    @State private var focusedField: InputField?

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
            // Negative spacing shifts the card ZStack up under the tabs.
            // zIndex(1) on tabHeader keeps tabs rendered in front of the machine.
            VStack(spacing: -10) {
                tabHeader
                ZStack(alignment: .top) {
                    Group {
                        if selectedTab == .daily {
                            receiptCard
                        } else {
                            monthlyCard
                        }
                    }
                    dispenserMachine
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .safeAreaInset(edge: .bottom) {
            if isEditing {
                doneButton.padding(.bottom, 12)
            }
        }
    }

    // MARK: - Done Button

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

    // MARK: - Dispenser Machine

    private var dispenserMachine: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(hex: "f0e4da"))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "cacaca"), lineWidth: 4))
            .frame(height: 32)
            .padding(.horizontal, 20)
    }

    // MARK: - Tab Header

    private var tabHeader: some View {
        HStack(alignment: .bottom, spacing: -28) {
            tabButton(tab: .daily,   label: "DAILY",   icon: "daily")
            tabButton(tab: .monthly, label: "MONTHLY", icon: "monthly")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .clipped()
    }

    private func tabButton(tab: AppTab, label: String, icon: String) -> some View {
        let isActive = selectedTab == tab
        let fillColor = isActive ? Color(hex: "f0e4da") : Color(hex: "98ABBA")
        let strokeColor = isActive ? Color(hex: "cacaca") : Color(hex: "437EAD")
        let shape = CustomTabShape()
        return Button(action: {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { selectedTab = tab }
        }) {
            HStack(spacing: 4) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(Color(hex: "546774"))
                Text(label)
                    .font(.custom("InstrumentSans-SemiBold", size: 13))
                    .foregroundColor(Color(hex: "546774"))
                    .kerning(2.0)
            }
            // Trailing padding compensates for the right-side notch so the label
            // centers within the visible shape area, not the full clipped frame.
            .padding(.trailing, 32)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(shape.fill(fillColor))
            .overlay(shape.stroke(strokeColor, lineWidth: 8))
            .clipShape(shape)
        }
        .buttonStyle(.plain)
        .zIndex(isActive ? 1 : 0)
    }

    // MARK: - Monthly Placeholder

    private var monthlyCard: some View {
        VStack(spacing: 0) {
            ScrollView { Color.clear.frame(height: 1) }
        }
        .background(
            ZStack {
                Color(hex: "f0e4da")
                Image("paper").resizable().scaledToFill().blendMode(.multiply).opacity(0.9)
            }
            .drawingGroup()
        )
        .clipShape(TornReceiptShape())
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    // MARK: - Receipt Card

    private var receiptCard: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    columnHeaders
                    divider
                    itemsArea
                        .padding(.top, 8)

                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .contentShape(Rectangle())
                        .onTapGesture { if !isEditing { startAdding() } }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56) // 28 base + 24 machine + 4 gap
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { if !isEditing { startAdding() } }
                )
            }

            // Footer pinned to bottom — hidden while editing
            if !items.isEmpty && !isEditing {
                VStack(spacing: 0) {
                    divider
                    footer.padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .background(
            ZStack {
                Color(hex: "f0e4da")
                Image("paper").resizable().scaledToFill().blendMode(.multiply).opacity(0.9)
            }
            .drawingGroup()
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
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            .padding(.vertical, 4)
    }

    private var itemsArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                if editingIndex == idx {
                    entryRow(number: idx + 1)
                } else {
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
                    .frame(height: 22)
                    .contentShape(Rectangle())
                }
            }

            if isAdding {
                entryRow(number: items.count + 1)
            }

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

    private func entryRow(number: Int) -> some View {
        let entryFont = UIFont(name: "CutiveMono-Regular", size: 16) ?? .monospacedSystemFont(ofSize: 16, weight: .regular)
        let blue = UIColor(red: 0.145, green: 0.361, blue: 0.525, alpha: 1) // #255c86
        let tint = UIColor(red: 0.074, green: 0.345, blue: 0.529, alpha: 1) // #135787

        return HStack(spacing: 0) {
            Text(String(format: "%02d", number))
                .font(.custom("CutiveMono-Regular", size: 16))
                .frame(width: 44, alignment: .leading)
                .foregroundColor(Color(hex: "546774").opacity(0.7))

            // Name field — same contextId as amount so keyboard stays up on transition
            LinkedTextField(
                text: $newItemName,
                keyboardType: .default,
                returnKeyType: .next,
                textAlignment: .left,
                autocapitalizationType: .allCharacters,
                uiFont: entryFont, uiTextColor: blue, uiTintColor: tint,
                contextId: "entry-row",
                isFocused: focusedField == .name,
                onFocus: { focusedField = .name },
                onReturn: { focusedField = .amount },
                filterInput: { $0.uppercased() }
            )
            .frame(maxWidth: .infinity)

            // Amount field — numberPad, keyboard stays visible thanks to shared contextId
            LinkedTextField(
                text: $newItemAmount,
                keyboardType: .numberPad,
                returnKeyType: .done,
                textAlignment: .right,
                autocapitalizationType: .none,
                uiFont: entryFont, uiTextColor: blue, uiTintColor: tint,
                contextId: "entry-row",
                isFocused: focusedField == .amount,
                onFocus: { focusedField = .amount },
                onReturn: { commitEntry(andDismiss: false) },
                filterInput: { $0.filter { $0.isNumber } }
            )
            .frame(width: 52)
        }
        .frame(height: 22)
        .onAppear {
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
            if !name.isEmpty {
                items[idx].name = name
                items[idx].amount = Int(newItemAmount) ?? 0
            }
            editingIndex = nil
            newItemName = ""
            newItemAmount = ""
            focusedField = andDismiss ? nil : .name
        } else {
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

// Folder-tab shape traced from Assets/Custom-Shapes/tab-shape.svg (viewBox 205×51).
// DAILY uses normal orientation; MONTHLY uses horizontal mirror so the concave
// notch appears on the left, letting the two tabs visually interlock.
struct CustomTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w: CGFloat = 205
        let h: CGFloat = 51
        let sx = rect.width / w
        let sy = rect.height / h
        let t = CGAffineTransform(scaleX: sx, y: sy)

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y).applying(t) }

        var p = Path()
        p.move(to: pt(91.1553, 2.0752))
        // Top-left section
        p.addCurve(to: pt(37.2656, 2.02441), control1: pt(71.7025, 2.0072),  control2: pt(52.1528, 1.97344))
        p.addCurve(to: pt(19.041,  2.1709),  control1: pt(29.8208, 2.0499),  control2: pt(23.5491, 2.09675))
        p.addCurve(to: pt(13.7002, 2.30273), control1: pt(16.7852, 2.208),   control2: pt(14.9829, 2.25187))
        p.addCurve(to: pt(12.3105, 2.375),   control1: pt(13.1156, 2.32592), control2: pt(12.6527, 2.35051))
        // Left side curving down
        p.addCurve(to: pt(11.7793, 3.625),   control1: pt(12.1655, 2.65756), control2: pt(11.9858, 3.06806))
        p.addCurve(to: pt(10.1211, 9.20117), control1: pt(11.2842, 4.96018), control2: pt(10.7224, 6.86837))
        p.addCurve(to: pt(6.40723, 26.1094), control1: pt(8.9225,  13.8511), control2: pt(7.61781, 19.9797))
        p.addCurve(to: pt(3.28223, 42.8857), control1: pt(5.1982,  32.2312), control2: pt(4.08901, 38.3226))
        p.addCurve(to: pt(2.375,   48.1055), control1: pt(2.90712, 45.0073), control2: pt(2.59887, 46.7978))
        // Bottom edge going right
        p.addCurve(to: pt(2.55762,  48.1035), control1: pt(2.43481, 48.1045), control2: pt(2.49569, 48.1045))
        p.addCurve(to: pt(9.8457,   47.9863), control1: pt(4.24381, 48.0767), control2: pt(6.71352, 48.0372))
        p.addCurve(to: pt(35.6338,  47.5547), control1: pt(16.1103, 47.8845), control2: pt(25.0272, 47.7372))
        p.addCurve(to: pt(111.862,  46.124),  control1: pt(56.8472, 47.1897), control2: pt(84.8204, 46.6848))
        p.addCurve(to: pt(182.488,  44.3594), control1: pt(138.907, 45.5632), control2: pt(165.01,  44.9463))
        p.addCurve(to: pt(190.443,  44.0684), control1: pt(185.394, 44.2618), control2: pt(188.057, 44.1636))
        // Concave right notch curving up
        p.addCurve(to: pt(172.008, 22.7246),  control1: pt(181.138, 39.742),  control2: pt(175.44,  30.9953))
        p.addCurve(to: pt(167.561, 7.52344),  control1: pt(169.688, 17.1345), control2: pt(168.335, 11.6232))
        p.addCurve(to: pt(166.78,  2.55762),  control1: pt(167.173, 5.46954), control2: pt(166.928, 3.75958))
        p.addCurve(to: pt(166.771, 2.4707),   control1: pt(166.777, 2.52838), control2: pt(166.774, 2.49934))
        // Top-right section
        p.addCurve(to: pt(161.937, 2.43848),  control1: pt(165.644, 2.46302), control2: pt(164.009, 2.45205))
        p.addCurve(to: pt(144.446, 2.33008),  control1: pt(157.719, 2.41086), control2: pt(151.69,  2.37257))
        p.addCurve(to: pt(91.1553, 2.0752),   control1: pt(129.958, 2.24509), control2: pt(110.607, 2.14318))
        p.closeSubpath()
        return p
    }
}

struct TornReceiptShape: Shape {
    var toothCount: Int = 20

    func path(in rect: CGRect) -> Path {
        let toothWidth = rect.width / CGFloat(toothCount)
        let toothHeight: CGFloat = 10
        var path = Path()

        // Sharp top corners — machine rectangle covers the top edge
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - toothHeight))

        var x = rect.width
        while x > 0 {
            path.addLine(to: CGPoint(x: x - toothWidth / 2, y: rect.height))
            x -= toothWidth
            path.addLine(to: CGPoint(x: max(x, 0), y: rect.height - toothHeight))
        }

        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - LinkedTextField
// Two fields sharing the same textInputContextIdentifier keep the keyboard
// panel on screen when focus switches — only the content (QWERTY ↔ numpad) swaps.

final class ContextualTextField: UITextField {
    var contextId: String = "entry"
    override var textInputContextIdentifier: String? { contextId }
}

struct LinkedTextField: UIViewRepresentable {
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .next
    var textAlignment: NSTextAlignment = .left
    var autocapitalizationType: UITextAutocapitalizationType = .none
    var uiFont: UIFont = .systemFont(ofSize: 16)
    var uiTextColor: UIColor = .label
    var uiTintColor: UIColor = .systemBlue
    var contextId: String = "entry"
    var isFocused: Bool = false
    var onFocus: (() -> Void)? = nil
    var onReturn: () -> Void = {}
    var filterInput: ((String) -> String)? = nil

    func makeUIView(context: Context) -> ContextualTextField {
        let tf = ContextualTextField()
        tf.contextId = contextId
        tf.delegate = context.coordinator
        tf.keyboardType = keyboardType
        tf.returnKeyType = returnKeyType
        tf.textAlignment = textAlignment
        tf.autocapitalizationType = autocapitalizationType
        tf.font = uiFont
        tf.textColor = uiTextColor
        tf.tintColor = uiTintColor
        tf.borderStyle = .none
        tf.backgroundColor = .clear
        tf.contentVerticalAlignment = .center
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Return button toolbar (visible above numpad which has no return key)
        let bar = UIToolbar(frame: .zero)
        bar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let ret  = UIBarButtonItem(
            image: UIImage(systemName: "return"), style: .plain,
            target: context.coordinator, action: #selector(Coordinator.returnTapped)
        )
        ret.tintColor = UIColor(red: 0.074, green: 0.345, blue: 0.529, alpha: 1)
        bar.items = [flex, ret]
        tf.inputAccessoryView = bar
        return tf
    }

    func updateUIView(_ tf: ContextualTextField, context: Context) {
        if tf.text != text { tf.text = text }
        if tf.keyboardType != keyboardType {
            tf.keyboardType = keyboardType
            if tf.isFirstResponder { tf.reloadInputViews() }
        }
        if tf.returnKeyType != returnKeyType { tf.returnKeyType = returnKeyType }
        tf.textColor = uiTextColor
        tf.tintColor = uiTintColor
        tf.textAlignment = textAlignment
        if isFocused && !tf.isFirstResponder {
            DispatchQueue.main.async { _ = tf.becomeFirstResponder() }
        } else if !isFocused && tf.isFirstResponder {
            _ = tf.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: LinkedTextField
        init(_ p: LinkedTextField) { parent = p }

        func textFieldDidBeginEditing(_ tf: UITextField) { parent.onFocus?() }

        func textField(_ tf: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString str: String) -> Bool {
            let current = tf.text ?? ""
            guard let r = Range(range, in: current) else { return true }
            var updated = current.replacingCharacters(in: r, with: str)
            if let filter = parent.filterInput { updated = filter(updated) }
            if updated != current.replacingCharacters(in: r, with: str) {
                tf.text = updated; parent.text = updated; return false
            }
            parent.text = updated
            return true
        }

        func textFieldShouldReturn(_ tf: UITextField) -> Bool {
            parent.onReturn(); return false
        }

        @objc func returnTapped() { parent.onReturn() }
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
