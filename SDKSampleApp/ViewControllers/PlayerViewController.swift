//
//  Player.swift
//  RefApp
//
//  Created by Karl Holmlöv on 11/1/18.
//  Copyright © 2018 amp. All rights reserved.
//

import UIKit
import iOSClientExposure
import iOSClientExposurePlayback
import iOSClientPlayer
import AVFoundation
import GoogleCast
import iOSClientCast
import AVKit


class PlayerViewController: UIViewController, GCKRemoteMediaClientListener, AVPictureInPictureControllerDelegate {
    
    var environment: Environment!
    var sessionToken: SessionToken!
    
    var playable: Playable?
    var program: Program?
    var channel: Asset?
    
    var newAssetType: AssetType?
    
    let audioSession = AVAudioSession.sharedInstance()
    var offlineMediaPlayable: OfflineMediaPlayable?
    
    // Play via direct URL
    fileprivate var urlPlayablePlayer: Player<HLSNative<ManifestContext>>!
    let urlPlayableTech = HLSNative<ManifestContext>()
    let urlPlayableContext = ManifestContext()
    var urlPlayable: URLPlayable?
    var shouldPlayWithUrl: Bool = false
    
    // Play via Exposure with assetId
    var playbackProperties = PlaybackProperties()
    fileprivate(set) var player: Player<HLSNative<ExposureContext>>!
    
    fileprivate(set) var avPlayerLayer: AVPlayerLayer? = nil
    
    /// Main ContentView which holds player view & player control views
    let mainContentView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    lazy var pausePlayButton: UIButton = {
        let button = UIButton()
        button.tintColor = ColorState.active.button
        button.addTarget(self, action: #selector(actionPausePlay(_:)), for: .touchUpInside)
        return button
    }()
    
    
    let playerView = UIView()
    let programBasedTimeline = ProgramBasedTimeline()
    let vodBasedTimeline = VodBasedTimeline()
    let controls  = PlayerControls()
    let castImage: UIImageView = {
        let image = UIImage(named: "cast")
        let imageView = UIImageView(image: image!)
        return imageView
    }()
    
    private var castButton: GCKUICastButton!
    
    var nowPlaying: Playable?
    var nowPlayingMetadata: Asset?
    var onChromeCastRequested: (Playable, Asset?, Int64?, Int64?) -> Void = { _,_,_,_ in }
    
    var castChannel: Channel = Channel()
    var castSession: GCKCastSession?
    
    var adsDuration: Int64?
    var checkedAdsDuration: Bool = false
    
    var playbackType : String = "VOD"
    
    var isOfflineMedia: Bool = false

    private var pictureInPictureController: AVPictureInPictureController?

    /// Hide status bar when player if in full screen mode
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func loadView() {
        super.loadView()
        setUpLayout()
        
        
        if !shouldPlayWithUrl {
            setupPlayerControls()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.vodBasedTimeline.isHidden = true
        self.programBasedTimeline.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        self.title = channel?.assetId
        
        self.vodBasedTimeline.isHidden = true
        self.programBasedTimeline.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dissmissKeyboard))
        view.addGestureRecognizer(tapGesture)
        view.bindToKeyboard()
        
        if shouldPlayWithUrl {
            setupURLPlayablePlayer()
        } else {
            setupPlayer(environment, sessionToken)
        }
        
        self.enableAudioSeesionForPlayer()
        
        // Google Cast
        self.showChromecastButton() // Show cast button in the navigation menu
        GCKCastContext.sharedInstance().sessionManager.add(self)
        showCastButtonInPlayer() // Hide player controls & Show cast button if there is any active cast session 
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.vodBasedTimeline.stopLoop()
        self.programBasedTimeline.stopLoop()
        if !shouldPlayWithUrl {
            self.player.stop()
        } else {
            self.urlPlayablePlayer.stop()
        }
        self.resumeBackgroundAudio()
        
    }
    
    @objc func dissmissKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        // view.unbindToKeyboard()
    }
}

// MARK: - Setup URLPlayable Player
extension PlayerViewController {
    fileprivate func setupURLPlayablePlayer() {
        urlPlayablePlayer = Player(tech: urlPlayableTech, context: urlPlayableContext)
        let _ = urlPlayablePlayer.configure(playerView: playerView)
        
        if let urlPlayable {
            urlPlayablePlayer.stream(url: urlPlayable.url)
            urlPlayablePlayer.play()
        }
    }
}

// MARK: - Setup Player
extension PlayerViewController: AVPlayerViewControllerDelegate {
        
    fileprivate func setupPlayer(_ environment: Environment, _ sessionToken: SessionToken) {
        
        /// This will configure the player with the `SessionToken` acquired in the specified `Environment`
        player = Player(environment: environment, sessionToken: sessionToken)
        
        let avPlayerLayer = player.configure(playerView: playerView)
        pictureInPictureController = AVPictureInPictureController(playerLayer: avPlayerLayer)
        pictureInPictureController?.delegate = self
        if #available(iOS 14.2, *) {
            pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        // The preparation and loading process can be followed by listening to associated events.
        player
            .onPlaybackCreated{ [weak self] player, source in
                // Fires once the associated MediaSource has been created.
                // Playback is not ready to start at this point.
            }
            .onPlaybackPrepared{ player, source in
                // Published when the associated MediaSource completed asynchronous loading of relevant properties.
                // Playback is not ready to start at this point.
            }
            .onPlaybackReady{ player, source in
                // When this event fires starting playback is possible (playback can optionally be set to autoplay instead)
                self.programBasedTimeline.seekableTimeRanges = self.player.seekableTimeRanges
                

                // Check if we are playing a Catchup Program by checking the playback type : playback type will be `VOD` for catchups even if the asset type is `LIVE_EVENT`
                if self.newAssetType == AssetType.LIVE_EVENT || self.newAssetType == AssetType.EVENT || self.newAssetType == AssetType.TV_CHANNEL {
                    
   
                    if self.player.playerItem?.accessLog()?.events.first?.playbackType == "LIVE" || self.player.playerItem?.accessLog()?.events.first?.playbackType == "Live"{
                        self.programBasedTimeline.playbackType = "LIVE"
                        self.playbackType = "LIVE"
                    } else {
                        self.programBasedTimeline.playbackType = "VOD"
                        self.playbackType = "VOD"
                    }
                } else {
                    if self.player.playerItem?.accessLog()?.events.first?.playbackType == "LIVE" || self.player.playerItem?.accessLog()?.events.first?.playbackType == "Live"{
                        
                        self.programBasedTimeline.isHidden = false
                        self.vodBasedTimeline.isHidden = true
                        
                        self.programBasedTimeline.playbackType = "LIVE"
                        self.playbackType = "LIVE"
                    } else {
                        self.programBasedTimeline.isHidden = true
                        self.vodBasedTimeline.isHidden = false
                        
                        self.programBasedTimeline.playbackType = "VOD"
                        self.playbackType = "VOD"
                    }
                }

            }
        
        // Once playback is in progress the Player continuously publishes events related media status and user interaction.
            .onPlaybackStarted{ [weak self] player, source in
                
                // Published once the playback starts for the first time.
                // This is a one-time event.
                guard let `self` = self else { return }

                // subtitle styling
                /* if let currentItem = player.playerItem ,
                  let textStyle = AVTextStyleRule(textMarkupAttributes: [kCMTextMarkupAttribute_OrthogonalLinePositionPercentageRelativeToWritingDirection as String: 10]), let textStyle1:AVTextStyleRule = AVTextStyleRule(textMarkupAttributes: [
                            kCMTextMarkupAttribute_CharacterBackgroundColorARGB as String: [0,0,1,0.3]
                            ]), let textStyle2:AVTextStyleRule = AVTextStyleRule(textMarkupAttributes: [
                                kCMTextMarkupAttribute_ForegroundColorARGB as String: [1,0,1,1.0]
                    ]), let textStyleSize3: AVTextStyleRule = AVTextStyleRule(textMarkupAttributes: [
                        kCMTextMarkupAttribute_RelativeFontSize as String: 200
                    ]) {
                    
                    currentItem.textStyleRules = [textStyle, textStyle1, textStyle2, textStyleSize3]
                } */
                
                
            }
            .onPlaybackPaused{ [weak self] player, source in
                // Fires when the playback pauses for some reason
                guard let `self` = self else { return }

                self.togglePlayPauseButton(paused: true)
            }
            .onPlaybackResumed{ [weak self] player, source in
                // Fires when the playback resumes from a paused state
                guard let `self` = self else { return }
                self.togglePlayPauseButton(paused: false)
            }
            .onPlaybackAborted{ player, source in

                // Published once the player.stop() method is called.
                // This is considered a user action
            }
            .onPlaybackCompleted { player, source in
                // Published when playback reached the end of the current media.
            }

            .onPlaybackStartWithAds { [weak self] vodDuration, adDuration, totalDurationInMs, adMarkers   in
                
                guard let `self` = self else { return }
                self.adsDuration = 0
                self.adsDuration = self.adsDuration ?? 0 + adDuration
                self.checkedAdsDuration = false
                self.vodBasedTimeline.adMarkers.removeAll()
                self.vodBasedTimeline.vodContentDuration = {
                    return ( totalDurationInMs - adDuration  )
                }
                
                // playback starts with ads which includes total actual clip duration (excluding ads ) & ad positions in the timeline
                if adMarkers.count != 0 {
                    
                    self.vodBasedTimeline.adMarkers = adMarkers
                    self.vodBasedTimeline.showAdTickMarks(adMarkers: adMarkers, totalDuration: totalDurationInMs, vodDuration: totalDurationInMs - adDuration )
                    
                    self.programBasedTimeline.adMarkers = adMarkers
                    self.programBasedTimeline.showAdTickMarks(adMarkers: adMarkers, totalDuration: totalDurationInMs, vodDuration: totalDurationInMs - adDuration )
                } else {
                    self.vodBasedTimeline.clearAdMarkerCache()
                    self.programBasedTimeline.clearAdMarkerCache()
                }
                
                // Clear sprite image cache
                self.updateSpriteImage(nil)
                
            }
        
            .onDateRangeMetadataChanged { metadataGroups, indexesOfNewGroups, indexesOfModifiedGroups in
                
                /* for metadataGroup in metadataGroups {

                    for metadata in metadataGroup.items {
          
                        if let value = metadata.value as? String {
                            
                            if let decodedData = Data(base64Encoded: value) {
                                
                   
                                if let decodedString = String(data: decodedData, encoding: .utf8) {
                                    print(" decoded Tracking Event  ==> ")
                                    print(decodedString)
                                    print("\n")
                                }

                                do {
                                    let eventDictionery = try JSONDecoder().decode( [String: [String]].self, from: decodedData)
                                    for(key, value ) in eventDictionery {
                                        
                                        if key ==  "breakStart" {
                                           print("breakStart value ==> ", value )
                                        }
                                        if key == "clickTracking" {
                                            print(" clickTracking value ==>> " , value )
                                        }
                                        if key == "clickThrough" {
                                            print(" clickThrough value ==>> " , value )
                                        }
                                    }
                                } catch {
                                    print(" json decoding error " , error )
                                }
                            }
                        }
                    }
                 } */

            }
        
            .onTimedMetadataChanged { context, source, metadataItems in
                guard let metadataItems = metadataItems else { return }
                
            }
        
            .onServerSideAdShouldSkip { [weak self] skipTime in
                guard let `self` = self else { return }
                self.player.seek(toPosition: skipTime )
            }
            .onWillPresentInterstitial { [weak self] contractRestrictionService, clickThroughUrl, adTrackingUrls, adClipDuration, noOfAds, adIndex in

                guard let `self` = self else { return }
                
                
                self.vodBasedTimeline.pausedTimer()
                self.programBasedTimeline.pausedTimer()
 
                self.programBasedTimeline.isHidden = true
                self.vodBasedTimeline.isHidden = true
                
                
                self.vodBasedTimeline.adDuration = self.vodBasedTimeline.adDuration + adClipDuration
                self.vodBasedTimeline.canFastForward = contractRestrictionService.contractRestrictionsPolicy?.fastForwardEnabled ?? false
                self.vodBasedTimeline.canRewind = contractRestrictionService.contractRestrictionsPolicy?.rewindEnabled ?? false
                
                
                self.programBasedTimeline.adDuration = self.programBasedTimeline.adDuration + adClipDuration
                self.programBasedTimeline.canFastForward = contractRestrictionService.contractRestrictionsPolicy?.fastForwardEnabled ?? false
                self.programBasedTimeline.canRewind = contractRestrictionService.contractRestrictionsPolicy?.rewindEnabled ?? false
                
                self.showToastMessage(message:" Ad Counter \(adIndex ) / \(noOfAds)", duration: 5)
                
            }
        
            .onDidPresentInterstitial { [weak self] contractRestrictionService  in
                guard let `self` = self else { return }

                self.vodBasedTimeline.resumeTimer()
                self.programBasedTimeline.resumeTimer()
                
                self.programBasedTimeline.isHidden = false
                self.vodBasedTimeline.isHidden = false
                
                self.vodBasedTimeline.canFastForward = contractRestrictionService.contractRestrictionsPolicy?.fastForwardEnabled ?? true
                self.vodBasedTimeline.canRewind = contractRestrictionService.contractRestrictionsPolicy?.rewindEnabled ?? true
                
                self.programBasedTimeline.canFastForward = contractRestrictionService.contractRestrictionsPolicy?.fastForwardEnabled ?? true
                self.programBasedTimeline.canRewind = contractRestrictionService.contractRestrictionsPolicy?.rewindEnabled ?? true
            }
        
        
        // Besides playback control events Player also publishes several status related events.
        player
            .onProgramChanged { [weak self] player, source, program in
                // Update user facing program information
                guard let `self` = self else { return }
                self.update(withProgram: program)
          
                
            }
            
            .onEntitlementResponse { [weak self] player, source, entitlement  in
                // Fires when a new entitlement is received, such as after attempting to start playback
                guard let `self` = self else { return }

                
                self.activateSprites(sprites: source.sprites)
                self.update(contractRestrictions: entitlement)
                
            }
            .onBitrateChanged{ player, source, bitrate in
                // Published whenever the current bitrate changes
            }
            .onBufferingStarted{ player, source in
                // Fires whenever the buffer is unable to keep up with playback
            }
            .onBufferingStopped{ player, source in
                // Fires when buffering is no longer needed
            }
            .onDurationChanged{ player, source in
                // Published when the active media received an update to its duration property
            }
            .onPlaybackScrubbed{ [weak self] player, source, timestamp in
                //
            }
        
        // Error handling can be done by listening to associated event.
        player
            .onError{ [weak self] player, source, error in
                
                guard let `self` = self else { return }

                let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                })
                
                let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
            }
            
            .onWarning{ [weak self] player,  source, warning in
                guard let `self` = self else { return }
   
                // self.showToastMessage(message: warning.message, duration: 5)
            }
            .onAirplayStatusChanged { context , source , status  in
                ///  onAirplayStatusChanged 
                
                /// Switch to online playback as when airplaying user must have a wifi connection
                /* if self.isOfflineMedia == true && status == true {
                    
                    let  currentplayheadPosition = self.player.playheadPosition
                    self.player.stop()
                    
                    if let assetId = self.offlineMediaPlayable?.assetId {
                        let properties = PlaybackProperties(autoplay: true, playFrom: .customPosition(position: currentplayheadPosition))
                        let playable = AssetPlayable(assetId: assetId)
                        self.player.startPlayback(playable: playable, properties: properties)
                    }
                } */
            }
        
        // Media Type
        .onMediaType { [weak self] type in
            // Media Type : audio / video
        }
        
        programBasedTimeline.onSeek = { [weak self] offset in
            
            guard let `self` = self else { return }
            
            if self.newAssetType == AssetType.LIVE_EVENT  || self.newAssetType == AssetType.EVENT  ||  self.newAssetType == AssetType.TV_CHANNEL {
                if self.player.playerItem?.accessLog()?.events.first?.playbackType == "LIVE" || self.player.playerItem?.accessLog()?.events.first?.playbackType == "Live"{
                    self.programBasedTimeline.playbackType = "LIVE"
                    self.playbackType = "LIVE"
                } else {
                    self.programBasedTimeline.playbackType = "VOD"
                    self.playbackType = "VOD"
                }
            } else {
                if self.player.playerItem?.accessLog()?.events.first?.playbackType == "LIVE" || self.player.playerItem?.accessLog()?.events.first?.playbackType == "Live"{
                    self.programBasedTimeline.playbackType = "LIVE"
                    self.playbackType = "LIVE"
                } else {
                    self.programBasedTimeline.playbackType = "VOD"
                    self.playbackType = "VOD"
                }
            }
            
            self.player.seek(toPosition: offset)
        }
        
        programBasedTimeline.currentPlayheadTime = { [weak self] in
            self?.programBasedTimeline.seekableTimeRanges = self?.player.seekableTimeRanges
            return self?.player.playerItem?.currentTime().milliseconds ?? self?.player.playheadTime
        }
        
        programBasedTimeline.timeBehindLiveEdge = { [weak self] in
            return self?.player.timeBehindLive
        }
        programBasedTimeline.goLiveTrigger = { [weak self] in
            if let start = self?.player.seekableTimeRanges.first?.start , let duration = self?.player.seekableTimeRanges.last?.duration {
                if let liveTime =  (start + duration).milliseconds {
                    self?.player.seek(toPosition: liveTime)
                }
            }
        }
        programBasedTimeline.startOverTrigger = { [weak self] in
            if let programStartTime = self?.player.currentProgram?.startDate?.millisecondsSince1970 {
                self?.player.seek(toTime: programStartTime)
            }
        }
        
        programBasedTimeline.onScrubbing = { [weak self] time in
            if let assetId = self?.playable?.assetId {
                let _ = self?.player.getSprite(time: time, assetId: assetId,callback: { image,_,_  in
                    self?.updateSpriteImage(image)
                })
            }
            
        }
        
    
        vodBasedTimeline.onSeek = { [weak self] offset in
            self?.player.seek(toPosition: offset)
        }
        
        vodBasedTimeline.onScrubbing = { [weak self] time in
            if let assetId = self?.playable?.assetId {
                let _ = self?.player.getSprite(time: time, assetId: assetId,callback: { image, startTime, endTime in
                    guard let image = image else { return }
                    self?.updateSpriteImage(image)
                })
            }
        }
        
        vodBasedTimeline.currentPlayheadPosition = { [weak self] in
            return self?.player.playheadPosition
        }
        
        vodBasedTimeline.currentDuration = { [weak self] in
            return self?.player.playerItem?.duration.milliseconds
        }
        
        vodBasedTimeline.startOverTrigger = { [weak self] in
            self?.player.seek(toPosition:0)
        }
        
        // Start the playback
        self.startPlayBack(properties: playbackProperties)
        
    }
    
    /// Start the playback with given properties
    ///
    /// - Parameter properties: playback properties
    func startPlayBack(properties: PlaybackProperties = PlaybackProperties() ) {
        
        nowPlaying = playable
        
        if let offlineMediaPlayable = offlineMediaPlayable {
            
            isOfflineMedia = true
            player.startPlayback(offlineMediaPlayable: offlineMediaPlayable )
            
        } else {
            if let playable = playable {
                
                isOfflineMedia = false
                
                // Check for cast session
                if GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession() {
                    self.chromecast(playable: playable, in: environment, sessionToken: sessionToken, currentplayheadTime: self.player.playheadTime)
                } else {
                    
                    player.startPlayback(playable: playable, properties: properties)
                    
                }
            }
        }
        
        DispatchQueue.main.async {
            self.updateTimeLine()
        }
    }
    
    
    /// Update time line depend on the asset type the player is playing
    fileprivate func updateTimeLine() {
        
        if let assetType = newAssetType {
            switch assetType {
            case .TV_CHANNEL:
                handleLive()
            case .MOVIE:
                handleVod()
            case .LIVE_EVENT:
                handleLive()
            case .TV_SHOW:
                handleVod()
            case .EPISODE:
                handleVod()
            case .CLIP:
                handleVod()
            case .AD:
                handleVod()
            case .COLLECTION:
                handleVod()
            case .OTHER:
                handleVod()
            case .PODCAST:
                handleVod()
            case .PODCAST_EPISODE:
                handleVod()
            case .EVENT:
                handleLive()
            @unknown default:
                handleVod()
            }
        } else {
            handleVod()
        }
            
    }
    
    /// handle vod ( MOVIE, CLIP, EPISODE etc )
    fileprivate func handleVod() {
        
        programBasedTimeline.isHidden = true
        programBasedTimeline.stopLoop()
        vodBasedTimeline.isHidden = false
        vodBasedTimeline.startLoop()
    }
    
    
    /// Handle Live ( Channel / Program / Live Event )
    fileprivate func handleLive() {
        vodBasedTimeline.isHidden = true
        vodBasedTimeline.stopLoop()
        
        programBasedTimeline.isHidden = false
        programBasedTimeline.startLoop()
    }
    
    func activateSprites(sprites: [Sprites]?) {
        if let playable = playable, let sprites = sprites , let width = sprites.first?.width {
            let _ = self.player.activateSprites(assetId: playable.assetId, width: width, quality: .medium) {  spritesData, error in
                 // print(" Sprites have been Activated " , spritesData )
            }
        }
    }
    
    func updateSpriteImage(_ image: UIImage?) {
        if let image = image {
            self.vodBasedTimeline.spriteImageView.image = image
            self.programBasedTimeline.spriteImageView.image = image
        } else {
            self.vodBasedTimeline.spriteImageView.image = nil
            self.programBasedTimeline.spriteImageView.image = nil
            // self.vodBasedTimeline.spriteImageView.image = nil
        }
        
    }
    
    
    func update(withProgram program: Program?) {
        self.program = program
        controls.programIdLabel.text = (program?.programId ?? self.channel?.assetId) ?? "Unknown"
        controls.startTimeLabel.text = program?.startDate?.dateString(format: "HH:mm") ?? "n/a"
        controls.endTimeLabel.text = program?.endDate?.dateString(format: "HH:mm") ?? "n/a"
        programBasedTimeline.currentProgram = program
    }
    
    func update(contractRestrictions entitlement: PlaybackEntitlement) {
        controls.ffEnabledLabel.text = entitlement.ffEnabled ? "FF enabled" : "FF disabled"
        controls.ffEnabledLabel.textColor = entitlement.ffEnabled ? UIColor.green : UIColor.red
        
        controls.rwEnabledLabel.text = entitlement.rwEnabled ? "RW enabled" : "RW disabled"
        controls.rwEnabledLabel.textColor = entitlement.rwEnabled ? UIColor.green : UIColor.red
        
        controls.timeShiftEnabledLabel.text = entitlement.timeshiftEnabled ? "Timeshift enabled" : "Timeshift disabled"
        controls.timeShiftEnabledLabel.textColor = entitlement.timeshiftEnabled ? UIColor.green : UIColor.red
        
        programBasedTimeline.canFastForward = entitlement.ffEnabled
        programBasedTimeline.canRewind = entitlement.rwEnabled
    }
}


// MARK: - Actions
extension PlayerViewController {
    
    /// Play - Pause Action
    ///
    /// - Parameter sender: pausePlayButton
    @objc fileprivate func actionPausePlay(_ sender: UIButton) {
        if player.isPlaying {
            player.pause()
        }
        else {
            player.play()
        }
    }
    
    /// Change play - pause image depending on user action
    ///
    /// - Parameter paused: user paused or not
    fileprivate func togglePlayPauseButton(paused: Bool) {
        if !paused {
            pausePlayButton.setImage(UIImage(named: "pause"), for: .normal)
        }
        else {
            pausePlayButton.setImage(UIImage(named: "play"), for: .normal)
        }
    }
}



// MARK: - Player Controls
extension PlayerViewController {
    
    func setupPlayerControls() {
        controls.onTimeTick = { [weak self] in
            guard let `self` = self else { return }
            if let currentTime = self.player.serverTime {
                let date = Date(milliseconds: currentTime)
                self.controls.wallClockTimeValueLabel.text = date.dateString(format: "HH:mm:ss")
            }
            else {
                self.controls.wallClockTimeValueLabel.text = "n/a"
            }
            
            let seekableRange = self.player.seekableRanges.map{ ($0.start.seconds, $0.end.seconds) }.first
            let bufferedRange = self.player.bufferedRanges.map{ ($0.start.seconds, $0.end.seconds) }.first
            if let seekable = seekableRange, !seekable.0.isNaN, !seekable.1.isNaN {
                self.controls.seekableStartLabel.text = String(Int64(seekable.0))
                self.controls.seekableEndLabel.text = String(Int64(seekable.1))
            }
            if let buffered = bufferedRange, !buffered.0.isNaN, !buffered.1.isNaN {
                self.controls.bufferedStartLabel.text = String(Int64(buffered.0))
                self.controls.bufferedEndLabel.text = String(Int64(buffered.1))
            }
            
            let seekableTimeRange = self.player.seekableTimeRanges.first
            let bufferedTimeRange = self.player.bufferedTimeRanges.first
            if let seekableTime = seekableTimeRange, let start = seekableTime.start.milliseconds, let end = seekableTime.end.milliseconds {
                let start = Date(milliseconds: start).dateString(format: "HH:mm:ss")
                let end = Date(milliseconds: end).dateString(format: "HH:mm:ss")
                self.controls.seekableStartTimeLabel.text = start
                self.controls.seekableEndTimeLabel.text = end
            }
            else {
                self.controls.seekableStartTimeLabel.text = "n/a"
                self.controls.seekableEndTimeLabel.text = "n/a"
            }
            
            if let bufferedTime = bufferedTimeRange, let start = bufferedTime.start.milliseconds, let end = bufferedTime.end.milliseconds  {
                let start = Date(milliseconds: start).dateString(format: "HH:mm:ss")
                let end = Date(milliseconds: end).dateString(format: "HH:mm:ss")
                self.controls.bufferedStartTimeLabel.text = start
                self.controls.bufferedEndTimeLabel.text = end
            }
            else {
                self.controls.bufferedStartTimeLabel.text = "n/a"
                self.controls.bufferedEndTimeLabel.text = "n/a"
            }
            
            if let playheadTime = self.player.playheadTime {
                let date = Date(milliseconds: playheadTime)
                self.controls.PlayHeadTimeValueLabel.text = date.dateString(format: "HH:mm:ss")
            }
            else {
                self.controls.PlayHeadTimeValueLabel.text = "n/a"
            }
            
            self.controls.playHeadPositionValueLabel.text = String(self.player.playheadPosition/1000)
            
            
        }
        
        controls.onStartOver = { [weak self] in
            guard let `self` = self else { return }
            if let programStartTime = self.player.currentProgram?.startDate?.millisecondsSince1970 {
                self.player.seek(toTime: programStartTime)
            }
            
            if self.playable is AssetPlayable {
                self.player.seek(toPosition:0)
            }
        }
        
        controls.onPauseResumed = { [weak self] paused in
            guard let `self` = self else { return }
            let _ = paused ? self.player.play(): self.player.pause()
        }
        
        controls.onGoLive = { [weak self] in
            guard let `self` = self else { return }
            self.player.seekToLive()
        }
        
        controls.onSeeking = { [weak self] seekDelta in
            guard let `self` = self else { return }
            let currentTime = self.player.playheadPosition
            self.player.seek(toPosition: currentTime + seekDelta * 1000)
        }
        
        controls.onSeekingTime = { [weak self] seekDelta in
            guard let `self` = self else { return }
            
            if self.newAssetType == AssetType.LIVE_EVENT {
                if self.player.playerItem?.accessLog()?.events.first?.playbackType == "LIVE" || self.player.playerItem?.accessLog()?.events.first?.playbackType == "Live"{
                    self.programBasedTimeline.playbackType = "LIVE"
                    self.playbackType = "LIVE"
                } else {
                    self.programBasedTimeline.playbackType = "VOD"
                    self.playbackType = "VOD"
                }
            } else {
                if self.player.playerItem?.accessLog()?.events.first?.playbackType == "LIVE" || self.player.playerItem?.accessLog()?.events.first?.playbackType == "Live"{
                    self.programBasedTimeline.playbackType = "LIVE"
                    self.playbackType = "LIVE"
                } else {
                    self.programBasedTimeline.playbackType = "VOD"
                    self.playbackType = "VOD"
                }
            }
            
            if let currentTime = self.player.playheadTime {

                let Ctime = currentTime
                let seek = seekDelta * 1000
                
                self.player.seek(toTime: Ctime + seek )
            }
        }
        
        controls.onCC = { [weak self] in
            guard let `self` = self else { return }
            let trackSelectionVC = TrackSelectionViewController()
            
            trackSelectionVC.assign(audio: self.player.audioGroup)
            trackSelectionVC.assign(text: self.player.textGroup)
            

            trackSelectionVC.onDidSelectAudio = { [weak self] track in
                
                guard let `self` = self, let track = track as? MediaTrack else {
                    self?.player.selectAudio(track: nil)
                    UserDefaults.standard.removeObject(forKey: "selectedAudioTrack")
                    return
                    
                }
              
                let language = track.extendedLanguageTag
                
               
                UserDefaults.standard.set(language, forKey: "selectedAudioTrack")
                self.player.selectAudio(track: track)
                
            }
            trackSelectionVC.onDidSelectText = { [weak self] track in
                guard let `self` = self, let track = track as? MediaTrack else {
                    self?.player.selectText(track: nil)
                    UserDefaults.standard.removeObject(forKey: "selectedSubtitleTrack")
                    return
                }

                let language = track.extendedLanguageTag
                UserDefaults.standard.set(language, forKey: "selectedSubtitleTrack")
                self.player.selectText(track: track)
            }
            trackSelectionVC.onDismissed = { [weak trackSelectionVC] in
                trackSelectionVC?.dismiss(animated: true)
            }
            
            self.present(trackSelectionVC, animated: false, completion: nil)
            
        }
        
        controls.onNextProgram = { [weak self] in
            guard let `self` = self else { return }
            
            /* let newPlayable = AssetPlayable(assetId: "25384_929372c", assetType: AssetType.MOVIE)
            self.player.startPlayback(playable: newPlayable, properties: PlaybackProperties(autoplay: true, playFrom: .defaultBehaviour)) */
            self.player.nextProgram()
           
        }
        
        controls.onPreviousProgram = { [weak self] in
            guard let `self` = self else { return }
            self.player.previousProgram()
        }
        
        controls.onPiP = { [weak self ] in
            guard AVPictureInPictureController.isPictureInPictureSupported() else {
                print("Picture in Picture mode is not supported")
                return
            }
            
            if let pipController = self?.pictureInPictureController {
                if pipController.isPictureInPicturePossible {
                    pipController.startPictureInPicture()
                } else {
                    pipController.addObserver(pipController, forKeyPath: "isPictureInPicturePossible", options: [.new], context: nil)
                }
            }
        }
    }
    
    @objc func clickedAd() {
        self.player.trackClickedAd(adTrackingUrls: ["ads"])
    }
}

extension PlayerViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "isPictureInPicturePossible" else {
            return
        }
        
        if let pipController = object as? AVPictureInPictureController {
            if pipController.isPictureInPicturePossible {
                pipController.startPictureInPicture()
            }
        }
    }
    
    func picture(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        //Update video controls of main player to reflect the current state of the video playback.
        //You may want to update the video scrubber position.
    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        //Handle PIP will start event
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        //Handle PIP did start event
    }
    
    func picture(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        //Handle PIP failed to start event
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        //Handle PIP will stop event
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        //Handle PIP did start event
    }
    
    /// Enable the audio session for player
    fileprivate func enableAudioSeesionForPlayer() {
        do {
            if #available(iOS 11.0, *) {
                try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, policy: .longForm)
            }
            else {
                try audioSession.setCategory(AVAudioSession.Category.playback)
            }
            try audioSession.setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    
    /// Disable player audio session & continue the background playback
    fileprivate func resumeBackgroundAudio() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print ("setActive(false) ERROR : \(error)")
        }
    }
}


// MARK: - Layout
extension PlayerViewController {
    fileprivate func setUpLayout() {
        
        view.addSubview(mainContentView)
        mainContentView.addArrangedSubview(playerView)
        
        if #available(iOS 11, *) {
            mainContentView.anchor(top: view.safeAreaLayoutGuide.topAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
        } else {
            mainContentView.anchor(top: view.topAnchor, bottom: view.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor)
        }
        
        playerView.addSubview(programBasedTimeline)
        playerView.addSubview(vodBasedTimeline)
        
        programBasedTimeline.anchor(top: nil, bottom: playerView.bottomAnchor, leading: playerView.leadingAnchor, trailing: playerView.trailingAnchor, padding: .init(top: 0, left: 4, bottom: -10, right: -4))
        
        vodBasedTimeline.anchor(top: nil, bottom: playerView.bottomAnchor, leading: playerView.leadingAnchor, trailing: playerView.trailingAnchor, padding: .init(top: 0, left: 4, bottom: -10, right: -4))
        
        playerView.addSubview(pausePlayButton)
        
        pausePlayButton.anchor(top: nil, bottom: nil, leading: playerView.leadingAnchor, trailing: playerView.trailingAnchor)
        pausePlayButton.centerXAnchor.constraint(equalTo: playerView.centerXAnchor).isActive = true
        pausePlayButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor).isActive = true
        
        playerView.addSubview(castImage)
        castImage.anchor(top: nil, bottom: nil, leading: nil, trailing: nil, padding: .init(top: 10, left: 10, bottom: -10, right: -10), size: .init(width: 100, height: 100))
        castImage.centerXAnchor.constraint(equalTo: playerView.centerXAnchor).isActive = true
        castImage.centerYAnchor.constraint(equalTo: playerView.centerYAnchor).isActive = true
        
        mainContentView.addArrangedSubview(controls)
        
    }
    
    func showCastButtonInPlayer() {
        if GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession() {
            
            programBasedTimeline.isHidden = true
            vodBasedTimeline.isHidden = true
            pausePlayButton.isHidden = true
            castImage.isHidden = false
            
        } else {
            programBasedTimeline.isHidden = false
            vodBasedTimeline.isHidden = false
            pausePlayButton.isHidden = false
            castImage.isHidden = true
        }
    }
}


// MARK: - Chrome cast
extension PlayerViewController: GCKSessionManagerListener {
    
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        sessionManager.remove(self)
        
        // HACK: Instruct the relevant analyticsProviders that startCasting event took place
        // TODO: We do not have nor want a strong coupling between the Cast and Player framework.
        player.tech.currentSource?.analyticsConnector.providers
            .compactMap{ $0 as? ExposureAnalytics }
            .forEach{ $0.startedCasting() }
        
        player.stop()
        
        showCastButtonInPlayer()
        
        guard let env = environment, let token = sessionToken , let playable = nowPlaying else { return }
        let currentplayheadTime = self.player.playheadTime
        self.chromecast(playable: playable, in: env, sessionToken: token, currentplayheadTime : currentplayheadTime)
        
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        //
    }
    
    
    func chromecast(playable: Playable, in environment: iOSClientExposure.Environment, sessionToken: SessionToken, localOffset: Int64? = nil, localTime: Int64? = nil, currentplayheadTime : Int64?) {
        

        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }
        
        let customData = CustomData(customer: environment.customer, businessUnit: environment.businessUnit).toJson
    
        let mediaInfoBuilder = GCKMediaInformationBuilder()
        mediaInfoBuilder.contentID = playable.assetId
        mediaInfoBuilder.textTrackStyle = .createDefault()
        
        let mediaInfo = mediaInfoBuilder.build()
        
        if let remoteMediaClient = session.remoteMediaClient {
            
            let mediaQueueItemBuilder = GCKMediaQueueItemBuilder()
            mediaQueueItemBuilder.mediaInformation = mediaInfo
            let mediaQueueItem = mediaQueueItemBuilder.build()
            let queueDataBuilder = GCKMediaQueueDataBuilder(queueType: .generic)
            queueDataBuilder.items = [mediaQueueItem]
            queueDataBuilder.repeatMode = remoteMediaClient.mediaStatus?.queueRepeatMode ?? .off
            
    

            let mediaLoadRequestDataBuilder = GCKMediaLoadRequestDataBuilder()
            mediaLoadRequestDataBuilder.credentials = "\(sessionToken.value)"
            mediaLoadRequestDataBuilder.queueData = queueDataBuilder.build()
            mediaLoadRequestDataBuilder.customData = customData
            
            
//            if let playheadTime = currentplayheadTime {
//                mediaLoadRequestDataBuilder.startTime = TimeInterval(playheadTime/1000)
//            }
            let _ = remoteMediaClient.loadMedia(with: mediaLoadRequestDataBuilder.build())

        }
    
    }
    
    private func localTime(playable: Playable) -> (Int64?, Int64?) {
        if playable is ChannelPlayable || playable is ProgramPlayable {
            return (nil, player.playheadTime)
        }
        else if playable is AssetPlayable {
            return (player.playheadPosition, nil)
        }
        return (nil, nil)
    }
}


