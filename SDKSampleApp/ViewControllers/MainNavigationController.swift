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
    
    var qrCodeData: QRCodeData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if StorageProvider.storedSessionToken != nil {
            viewControllers = [RootViewController()]
        } else {
            viewControllers = [EnvironmentViewController()]
        }
        tryPlayingAssetIfPossible()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - QR Code related funcs

extension MainNavigationController {
    
    func tryPlayingAssetIfPossible() {
        if let qrCodeData, qrCodeData.isContentAssetAvailable {
            showPlayerController(
                qrCodeData: qrCodeData,
                environment: StorageProvider.storedEnvironment
            )
        }
    }
    
    private func showPlayerController(
        qrCodeData: QRCodeData,
        environment: Environment?
    ) {
        guard let source = qrCodeData.urlParams?.source else {
            return
        }
        
        let playerVC = PlayerViewController()
        
        if qrCodeData.isSourceAssetURL,
           let sourceURL = URL(string: source) {
            /// assetURL
            playerVC.shouldPlayWithUrl = true
            playerVC.urlPlayable = URLPlayable(url: sourceURL)
            viewControllers.append(playerVC)
        } else if let sessionToken = StorageProvider.storedSessionToken,
                  let environment = StorageProvider.storedEnvironment {
            /// assetID
            playerVC.sessionToken = sessionToken
            playerVC.environment = environment
            playerVC.shouldPlayWithUrl = false
            playerVC.playable = AssetPlayable(assetId: source)
            viewControllers.append(playerVC)
        }
        
    }
}
