import UIKit
import iOSClientExposure

struct ErrorModel: Error {
    
    let error: ExposureError
    
    var title: String {
        error.domain
    }
    var message: String {
        "\(error.code) " + error.message + "\n" + (error.info ?? "")
    }
    
    let okAction = UIAlertAction(
        title: NSLocalizedString("Ok", comment: ""),
        style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        }
    )
    
    func show(
        vc: UIViewController
    ) {
        vc.popupAlert(
            title: NSLocalizedString(title, comment: ""),
            message: NSLocalizedString(message, comment: ""),
            actions: [okAction],
            preferedStyle: .alert
        )
    }
}
