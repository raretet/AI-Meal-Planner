import SwiftUI
import UIKit

struct AssetIcon: View {
    let assetName: String
    let systemName: String
    var pointSize: CGFloat = 22

    private var hasAsset: Bool {
        UIImage(named: assetName) != nil
    }

    var body: some View {
        Group {
            if hasAsset {
                Image(assetName)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: pointSize, height: pointSize)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: pointSize * 0.92, weight: .medium))
            }
        }
    }
}
