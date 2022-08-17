//
//  Player.swift
//  SDKSampleSwiftUI
//
//  Created by Udaya Sri Senarathne on 2022-01-11.
//

import UIKit
import SwiftUI
import iOSClientExposure
import iOSClientExposurePlayback

struct CustomVideoPlayer: UIViewControllerRepresentable {
    
    var playable : AssetPlayable

    func makeUIViewController(context: Context) -> UIViewController {
        
        let playerViewController = PlayerViewController()
        playerViewController.playable = playable
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        print(" Update UI View Controller ")
    }
}
