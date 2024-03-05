import Foundation
import UIKit

struct QRCodeData {
    let urlParams: QRCodeURLParameters?
    
    var isContentAssetAvailable: Bool {
        urlParams?.source != nil
    }
    
    var isSourceAssetURL: Bool {
        guard
            let assetID = urlParams?.source
        else {
            return false
        }
        return isValidURL(assetID)
    }
    
    private func isValidURL(
        _ urlString: String
    ) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }
}
