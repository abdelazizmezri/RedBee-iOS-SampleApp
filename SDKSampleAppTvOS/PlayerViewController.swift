//
//  PlayerViewController.swift
//  SDKSampleAppTvOS
//
//  Created by Udaya Sri Senarathne on 2021-11-24.
//

import Foundation
import UIKit
import TVUIKit
import iOSClientPlayer
import iOSClientExposure
import iOSClientExposurePlayback
import AVFoundation
import AVKit

class PlayerViewController: UIViewController, AVPlayerViewControllerDelegate {
    fileprivate(set) var player: Player<HLSNative<ExposureContext>>!
    var playable: Playable!
    var environment: Environment!
    var sessionToken: SessionToken!
    var playerAssetDataSource: PlayerAssetDataSource!
    var newPlayerViewController = AVPlayerViewController()
    
    
    @objc dynamic var playerViewController: AVPlayerViewController?
    
    var assetViewModel: AssetViewModel?
    var properties: PlaybackProperties!
    
    var pushNextCuePoint: Int64?
    var contentProposalViewController: ContentProposalViewController?
    
    var avInterstitialTimeRange = [AVInterstitialTimeRange]() // Store all ad breaks as AVInterstitialTimeRange
    var adBreaks = [AVInterstitialTimeRange: Bool]() // Store all adbreaks with isAlreadyWatched - true : false
    private var scubbedPosition: CMTime = CMTime(milliseconds: 0)
    
    
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
        
        newPlayerViewController.delegate = self
        
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
        
        self.playerViewController = self.player.configureWithDefaultSkin(avPlayerViewController: newPlayerViewController)
        self.playerViewController?.delegate = self
        
        self.player.startPlayback(playable: playable)
        
        self.playBackMonitoring(newPlayerViewController)
    }
    
    
    // reset by removing the playerViewController & creating a new one
    public func reset() -> AVPlayerViewController {
        
        if let playerViewController = self.playerViewController {
            print("PlayerViewController - reset old view")
            playerViewController.removeFromParent()
            playerViewController.viewIfLoaded?.removeFromSuperview()
        }
        
        let newAVPlayerViewController = AVPlayerViewController()
        self.playerViewController = newAVPlayerViewController
        if let playerViewController = playerViewController {
            print("PlayerViewController - reset new view created")
            addChild(playerViewController)
            if isViewLoaded {
                view.addSubview(playerViewController.view)
            }
            playerViewController.delegate = self
        }
        return newAVPlayerViewController
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
        
            .onPlaybackStartWithAds{ [weak self] vodDuration, adDuration, totalDuration, adMarkers in
                print("on playback start with ads \(adMarkers)")

                self?.player.playerItem?.interstitialTimeRanges = adMarkers.compactMap({ MarkerPoint in
                    if let startOffset = MarkerPoint.offset, let endOffset = MarkerPoint.endOffset {
                        let timeRange = CMTimeRange(
                            start: CMTime(milliseconds: Int64(startOffset)),
                            end: CMTime(milliseconds: Int64(endOffset))
                        )
                        
                        self?.avInterstitialTimeRange.append(AVInterstitialTimeRange(timeRange: timeRange))
                        return AVInterstitialTimeRange(timeRange: timeRange)
                    }
                    return nil
                })
                
                if let playerViewController = self?.playerViewController {
                    // force a re-render to fix timeline not renderinging the new duration/admarkers correctly
                    playerViewController.showsPlaybackControls = false
                    playerViewController.showsPlaybackControls = true
                }
                
            }
            .onWillPresentInterstitial{ [weak self] _ , _, _,_, _ , _    in
                print("On will present interstitial")
                self?.playerViewController?.requiresLinearPlayback = true;
            }
            .onDidPresentInterstitial{ [weak self] _ in
                print("On did present interstitial")
                self?.playerViewController?.requiresLinearPlayback = false;
            }
            .onServerSideAdShouldSkip{ [weak self] skipTime in
                print( "On server-side ad should skip")
                self?.player.seek(toPosition: Int64(skipTime))
            }
        
            .onPlaybackAborted { [weak self] player, source in
                print(" On playback aborted")
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

extension PlayerViewController {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willPresent interstitial: AVInterstitialTimeRange) {
         
        // playerViewController.requiresLinearPlayback = true
        
        print(" willPresent interstitial start \(interstitial.timeRange.start)  & End \(interstitial.timeRange.end)" )
         
        // playerViewController.requiresLinearPlayback = true
         // Check if the ad is already watched or not
         /* if self.adBreaks[interstitial] == false {
             DispatchQueue.main.async {
                 // Disable player ff / rw
                 playerViewController.requiresLinearPlayback = true
                 playerViewController.isSkipForwardEnabled = false
                 playerViewController.isSkipBackwardEnabled = false
                 
                 // assign the interstitial as already watched ad
                 self.adBreaks[interstitial] = true
             }
         } else {
             DispatchQueue.main.async {
                 playerViewController.player?.seek(to: interstitial.timeRange.end)
             }
             
         } */
     }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, didPresent interstitial: AVInterstitialTimeRange) {
        // interstitial is finished presenting , assign the interstitial as already watched ad
        
        print(" didPresent interstitial start \(interstitial.timeRange.start)  & End \(interstitial.timeRange.end)" )
        
        // playerViewController.requiresLinearPlayback = false
        
        // playerViewController.requiresLinearPlayback = false
        
        /* self.adBreaks[interstitial] = true
        
        DispatchQueue.main.async {
            
            // Check if there is already seeked / scubbedPosition available that user intiated before ad break
            if self.scubbedPosition != CMTime.zero {
                playerViewController.player?.seek(to: self.scubbedPosition )
                
                // assign scubbedPosition to zero
                self.scubbedPosition = CMTime.zero
            }
            
            // Enabled player ff / rw
            playerViewController.requiresLinearPlayback = false
            playerViewController.isSkipForwardEnabled = true
            playerViewController.isSkipBackwardEnabled = true
        } */
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController,
    willResumePlaybackAfterUserNavigatedFrom oldTime: CMTime,
                              to targetTime: CMTime) {
        print("willResumePlaybackAfterUserNavigatedFrom")
        if let targetTimeInMs = targetTime.milliseconds {
            print("player should seek " , targetTimeInMs)
            self.player.seek(toPosition: targetTimeInMs)
        }
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, timeToSeekAfterUserNavigatedFrom oldTime: CMTime, to targetTime: CMTime) -> CMTime {
        
        print( "timeToSeekAfterUserNavigatedFrom \(oldTime.milliseconds) & target Time \(targetTime.milliseconds) " )
        
        
        
        
//
        
//        let seekRange = CMTimeRange(start: oldTime, end: targetTime)
//
//        if let adTimeRanges = playerViewController.player?.currentItem?.interstitialTimeRanges {
//            // Iterate over the defined interstitial time ranges.
//            for interstitialRange in adTimeRanges {
//                // If the current interstitial content is contained within the
//                // user's seek range, return the interstitial content's start time.
//                if seekRange.containsTimeRange(interstitialRange.timeRange) {
//
//                    print(" AD is inside the seek time range yes " )
//
//                    return interstitialRange.timeRange.start
//                }
//            }
//        }

        
        // Define time range of the user's seek operation
        /* let seekRange = CMTimeRange(start: oldTime, end: targetTime)
        
        let _ = self.avInterstitialTimeRange.compactMap {
            
        }
        
        // Iterate over the defined interstitial time ranges.
        for interstitialRange in self.avInterstitialTimeRange {
            // If the current interstitial content is contained within the
            // user's seek range, return the interstitial content's start time.
            if seekRange.containsTimeRange(interstitialRange.timeRange) {
                // Check if the ad is already watched or not , if not seek to the start / offset value of the ad
                if self.adBreaks[interstitialRange] == false {
                    // store user's scubbedPosition / targetTime, so that we can seek to this position when the ad break is over
                    self.scubbedPosition = targetTime
                    return interstitialRange.timeRange.start
                } else {
                    // Ad is already watched
                    // assign scubbedPosition to zero
                    self.scubbedPosition = CMTime.zero
                    
                    return targetTime
                    
                }
            }
        }
         */
        // No Ads found. Return the target time.
        // self.scubbedPosition = CMTime.zero
        return targetTime
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
