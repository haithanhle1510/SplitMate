import SwiftUI

struct EmptyStateView: View {
    let emoji: String
    let title: String
    let message: String
    var ctaLabel: String? = nil
    var onCtaTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appPeach)
                    .frame(width: 96, height: 96)
                Text(emoji).font(.system(size: 40))
            }
            .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(title)
                    .font(.nunito(20, weight: .heavy))
                    .foregroundColor(.appText)
                Text(message)
                    .font(.nunito(14, weight: .semibold))
                    .foregroundColor(.appMuted)
                    .multilineTextAlignment(.center)
            }
            if let ctaLabel, let onCtaTap {
                TerraButton(label: ctaLabel, action: onCtaTap)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
