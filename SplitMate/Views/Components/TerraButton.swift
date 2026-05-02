import SwiftUI

struct TerraButton: View {
    let label: String
    var outline: Bool = false
    var small: Bool = false
    var fullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.nunito(small ? 13 : 16, weight: .heavy))
                .foregroundColor(outline ? .appTerra : .appWhite)
                .padding(.vertical, small ? 7 : 13)
                .padding(.horizontal, small ? 14 : 24)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(outline ? Color.clear : Color.appTerra)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appTerra, lineWidth: outline ? 1.5 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}
