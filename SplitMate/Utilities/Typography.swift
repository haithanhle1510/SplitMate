import SwiftUI
import CoreText

extension Font {
    static func nunito(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        Font.custom("Nunito", size: size, relativeTo: textStyle).weight(weight)
    }
}

enum FontRegistration {
    static func registerCustomFonts() {
        guard let url = Bundle.main.url(forResource: "Nunito", withExtension: "ttf") else {
            print("Nunito.ttf not found in bundle")
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
