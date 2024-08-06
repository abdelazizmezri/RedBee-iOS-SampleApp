//
//  MainNavigationController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-21.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import iOSClientExposure
import iOSClientExposurePlayback

/// Handles the main navigation in the app
class MainNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if StorageProvider.storedSessionToken != nil {
            viewControllers = [RootViewController()]
        } else {
            let environment = Environment(baseUrl: "https://exposure.api.redbee.live", customer: "TV5MONDE", businessUnit: "TV5MONDEplus")
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            Authenticate(environment: environment)
                .anonymous()
                .request()
                .validate()
                .response{ [weak self] in
                    
                    print($0)
                    
                    if let error = $0.error {
                        
                        let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                        self?.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
                    }
                    
                    if let credentials = $0.value {
                        
                        StorageProvider.store(environment: environment)
                        StorageProvider.store(sessionToken: credentials.sessionToken)
                        
                        
                    }
            }
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
