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
    var playerAssetDataSource: PlayerAssetDataSource!
    var newPlayerViewController = AVPlayerViewController()
    var assetViewModel: AssetViewModel?
    var properties: PlaybackProperties!
    
    var pushNextCuePoint: Int64?
    var contentProposalViewController: ContentProposalViewController?
    
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
        
        self.contentProposalViewController = ContentProposalViewController()
        
        self.playerViewController = newPlayerViewController
        
        addChild(newPlayerViewController)
        
        
        if isViewLoaded {
            view.addSubview(newPlayerViewController.view)
        }

        self.player = Player(environment: environment, sessionToken: sessionToken)
        newPlayerViewController = self.player.configureWithDefaultSkin(avPlayerViewController: newPlayerViewController)
        newPlayerViewController.delegate = self

        self.player.startPlayback(playable: playable)
        
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
            .onPlaybackStarted { [weak self] player, source in
                
                let extenalMediaInfo = self?.createExternalMediaInfo()
                
                let playerItem = newPlayerViewController.player?.currentItem
                if self?.pushNextCuePoint != nil || self?.pushNextCuePoint != 0  {
                    playerItem?.nextContentProposal = self?.setProposal()
                }
                
                playerItem?.externalMetadata = extenalMediaInfo ?? []
                
                // Customising subtitles
                /* if let currentItem = player.playerItem ,
                  let textStyle = AVTextStyleRule(textMarkupAttributes: [kCMTextMarkupAttribute_OrthogonalLinePositionPercentageRelativeToWritingDirection as String: 10]), let textStyle1:AVTextStyleRule = AVTextStyleRule(textMarkupAttributes: [
                            kCMTextMarkupAttribute_CharacterBackgroundColorARGB as String: [0,0,1,0.3]
                            ]), let textStyle2:AVTextStyleRule = AVTextStyleRule(textMarkupAttributes: [
                                kCMTextMarkupAttribute_ForegroundColorARGB as String: [1,0,1,1.0]
                    ]), let textStyleSize3: AVTextStyleRule = AVTextStyleRule(textMarkupAttributes: [
                        kCMTextMarkupAttribute_RelativeFontSize as String: 200
                    ]) {
                    
                    playerItem?.textStyleRules = [textStyle, textStyle1, textStyle2, textStyleSize3]
                } */
                
                newPlayerViewController.player?.replaceCurrentItem(with: playerItem)
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


// MARK: Push Next Content
extension PlayerViewController {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, shouldPresent proposal: AVContentProposal) -> Bool {
        // Set the presentation to use on the player view controller for this content proposal
        playerViewController.contentProposalViewController = contentProposalViewController
        return true
    }
    
    /// Set up Content proposal / Push Next Content proposal
    /// - Returns: AVContentProposal
    func setProposal() -> AVContentProposal? {
        
        // Set Next Episode / Program Meta data
        guard let cuepoint = pushNextCuePoint else {
            return nil
            
        }

        // Set up Next content Image
        let image = UIImage(named: "dummy")
        
        // Set up Next content Title
        let title = "Lorem Ipsum is simply dummy text of the printing"
        var contentMetadata = [AVMetadataItem]()
        
        let titleItem = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierTitle, value: title)
        contentMetadata.append(titleItem)
        
        // Set up Next content desciption
        let desciption = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum"
        let descItem = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierDescription, value: desciption)
        contentMetadata.append(descItem)
        
        let contentProposal = AVContentProposal(contentTimeForTransition: CMTime(milliseconds: cuepoint), title: title, previewImage: image)
        contentProposal.automaticAcceptanceInterval = -1.0
        contentProposal.metadata = contentMetadata
        return contentProposal
    }
    
    
    
    func playerViewController(_ playerViewController: AVPlayerViewController, didAccept proposal: AVContentProposal) {
        
        print(" User did accept content proposal ")
        
        // Start the player with next content Id
        // can be fetched by WLA : /push-next-content/ end point
        // Assign new push next content value
        /*
         self.playerAssetDataSource.assetId = assetId
         let newPlayable = AssetPlayable(assetId : nextAssetId)
         self.playable = newPlayable
         self.properties = PlaybackProperties(playFrom: .defaultBehaviour)
         
         // Fetch next asset's details
         self.playerAssetDataSource.onDataUpdated = { viewModel in
             self.assetViewModel = viewModel

             if let assetDuration = viewModel?.asset.duration, let pushNextCuepoint = nextContent.upNext?.pushNextCuepoint {
                 self.pushNextCuePoint = pushNextCuepoint
             } else {
                 self.pushNextCuePoint = 0
             }
             DispatchQueue.main.async {
                 self.startPlayback()
             }
         }
         
         */

        
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, didReject proposal: AVContentProposal) {
        // print(" didReject content proposal")
    }
}

// MARK: AVPlayerViewController Custom MediaInfo
extension PlayerViewController {
    
    /// Create External media info that will be shown in swip down modal in tv
    /// - Returns: AVMetadataItem
    private func createExternalMediaInfo() -> [AVMetadataItem] {
        // ExternamMediaInfo
        var metadata = [AVMetadataItem]()
        
        
        if let title = assetViewModel?.title {
            
            let titleItem = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierTitle, value: title)
            metadata.append(titleItem)
        }
        
        if let desciption = assetViewModel?.description {
            
            let descItem = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierDescription, value: desciption)
            metadata.append(descItem)
        }
        
        if let image = assetViewModel?.image?.url, let url = URL(string: "\(image)?w=280") {
            do {
                let data =  try Data(contentsOf: url )
                if let image = UIImage(data: data) , let pngData = image.pngData() {
                    
                    let artworkItem = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierArtwork, value: pngData)
                    metadata.append(artworkItem)
                }
            } catch {
                print(" Error gettting data from url " , error.localizedDescription)
            }
        }
        
        return metadata
    }
    
    
    private func makeMetadataItem(_ identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}
