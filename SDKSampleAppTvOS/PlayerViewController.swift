//
//  PlayerViewController.swift
//  SDKSampleAppTvOS
//
//  Created by Udaya Sri Senarathne on 2021-11-24.
//

import Foundation
import UIKit
import TVUIKit
import Player
import Exposure
import ExposurePlayback
import AVFoundation
import AVKit

class PlayerViewController: UIViewController, AVPlayerViewControllerDelegate {
    fileprivate(set) var player: Player<HLSNative<ExposureContext>>!
    var playable: Playable!
    var environment: Environment!
    var sessionToken: SessionToken!
    var newPlayerViewController = AVPlayerViewController()
    
    @objc dynamic var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        
        if let playerViewController = playerViewController {
            view.addSubview(playerViewController.view)
            playerViewController.view.frame = view.bounds
        }
    }
    
    override func viewWillLayoutSubviews() {
        
        if let playerViewController = playerViewController {
            playerViewController.view.frame = view.bounds
        }
        super.viewWillLayoutSubviews()
    }
    
    public func startPlayback() {
    
        if let oldPlayerViewController = self.playerViewController {
            oldPlayerViewController.removeFromParent()
            oldPlayerViewController.viewIfLoaded?.removeFromSuperview()
        }
        
        self.playerViewController = newPlayerViewController
        
        addChild(newPlayerViewController)
        
        
        if isViewLoaded {
            view.addSubview(newPlayerViewController.view)
        }

        self.player = Player(environment: environment, sessionToken: sessionToken)
        newPlayerViewController = self.player.configureWithDefaultSkin(avPlayerViewController: newPlayerViewController)
        newPlayerViewController.delegate = self

        self.player.startPlayback(playable: playable, properties: PlaybackProperties(playFrom: .beginning))
        
        self.playBackMonitoring(newPlayerViewController)
    }
    
    private func playBackMonitoring(_ newPlayerViewController: AVPlayerViewController) {
        self.player
            .onError{  [weak self] player, source, error in
                print(" Error " , error.localizedDescription )
                let _ = self?._dismiss()
            }
        
            .onPlaybackCompleted { [weak self] player, source in
                let _ = self?._dismiss()
            }
        
            .onPlaybackReady{  player, source in
                print(" On playback ready ")
            }
            .onPlaybackStarted { player, source in
                print(" On playback onPlaybackStarted ")
            }
        
            .onPlaybackAborted { [weak self] player, source in
                let _ = self?._dismiss()
            }
    }
    
    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
        return _dismiss()
    }
    
    private func _dismiss(stopping: Bool = true) -> Bool {
        if let playerViewController = self.playerViewController {
            UserDefaults.standard.set(false, forKey: "isPlaying")
            self.player.stop()
            if let presenting = presentingViewController {
                presenting.dismiss(animated: true, completion: {
                    if stopping {
                        playerViewController.player?.rate = 0.0 // stop playback immediately (don't wait for dealloc)
                    }
                    playerViewController.removeFromParent()
                    playerViewController.view.removeFromSuperview()
                    self.playerViewController = nil
                })
                return true
            }
        }
        if let presenting = presentingViewController {
            UserDefaults.standard.set(false, forKey: "isPlaying")
            self.player.stop()
            if presenting.presentedViewController == self {
                presenting.dismiss(animated: true, completion: {
                    
                })
            }
        }
        return false
    }
    
}
