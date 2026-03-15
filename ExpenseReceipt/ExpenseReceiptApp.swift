import SwiftUI
import CoreText

@main
struct ExpenseReceiptApp: App {
    init() {
        registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func registerFonts() {
        let fontNames = [
            "InstrumentSerif-Regular",
            "InstrumentSans-Regular",
            "InstrumentSans-Medium",
            "InstrumentSans-SemiBold",
        ]
        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                print("⚠️ Font not found in bundle: \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
