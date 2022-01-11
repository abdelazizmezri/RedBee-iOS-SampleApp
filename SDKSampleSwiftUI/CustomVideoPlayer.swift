//
//  Player.swift
//  SDKSampleSwiftUI
//
//  Created by Udaya Sri Senarathne on 2022-01-11.
//

import UIKit
import SwiftUI
import Exposure
import ExposurePlayback

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
