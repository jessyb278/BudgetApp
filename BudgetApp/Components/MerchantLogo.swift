import SwiftUI

struct MerchantLogo: View {
    let merchant: Merchant
    var size: CGFloat = 44
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(merchant.color.opacity(0.3))
            Image(systemName: merchant.icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(merchant.color)
        }
        .frame(width: size, height: size)
    }
}
