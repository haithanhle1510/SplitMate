import SwiftUI

struct AvatarView: View {
    let name: String
    var size: CGFloat = 36

    private static let palette: [Color] = [
        .appPeachMid, .appSage, .appWarmGray, .appPeach, .appTerra, .appSageLt,
    ]

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }

    private var background: Color {
        guard let scalar = name.unicodeScalars.first else { return .appPeach }
        let idx = Int(scalar.value) % Self.palette.count
        return Self.palette[idx]
    }

    var body: some View {
        ZStack {
            Circle().fill(background)
            Text(initials)
                .font(.nunito(size * 0.38, weight: .bold))
                .foregroundColor(.appText)
        }
        .frame(width: size, height: size)
    }
}
