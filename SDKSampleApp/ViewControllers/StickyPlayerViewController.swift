//
//  DemoPopupContentViewController.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2022-01-14.
//

import UIKit
import Player
import ExposurePlayback
import Exposure
import AVKit
import AVFoundation
import MediaPlayer
import LNPopupController
import GoogleCast
import Cast

class StickyPlayerViewController: UIViewController, AVAudioPlayerDelegate {
    
    
    static var player: Player<HLSNative<ExposureContext>>!
    
    var environment: Environment!
    var sessionToken: SessionToken!
    var playable: Playable?
    
    let programBasedTimeline = ProgramBasedTimeline()
    let vodBasedTimeline = VodBasedTimeline()
    
    var asset: Asset?
    
    let playerView = UIView()
    
    let largeConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold, scale: .default)
    
    lazy var descriptionLabel : UILabel = {
        let label = UILabel()
        label.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        label.numberOfLines = 10
        label.textAlignment = .left
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .black
        return label
    }()
    
    
    lazy var playButtonMiniPlayer : UIBarButtonItem = {
        let playButton = UIBarButtonItem()
        playButton.title = "play"
        playButton.image = UIImage(systemName: "play")
        playButton.target = self
        playButton.action = #selector(playPause)
        return playButton
    }()
    
    lazy var pauseButtonMiniPlayer : UIBarButtonItem = {
        let pauseButton = UIBarButtonItem()
        pauseButton.title = "pause"
        pauseButton.image = UIImage(systemName: "pause")
        pauseButton.target = self
        pauseButton.action = #selector(playPause)
        return pauseButton
    }()
    
    lazy var stopButtonMiniPlayer : UIBarButtonItem = {
        let stopButton = UIBarButtonItem()
        stopButton.title = "stop"
        stopButton.image = UIImage(systemName: "stop")
        stopButton.target = self
        stopButton.action = #selector(stopPlayBack)
        return stopButton
    }()
    
    
    var playerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    var timelineStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .vertical
        return stackView
    }()
    
    var playPauseButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 160, y: 0, width: 160, height: 160)
        button.addTarget(self, action: #selector(playPause), for: .touchUpInside)
        return button
    }()
    
    var nextButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 60)
        button.setImage(UIImage(systemName: "forward.end.fill"), for: .normal)
        button.addTarget(self, action: #selector(playPause), for: .touchUpInside)
        return button
    }()
    
    var previousButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 60)
        button.setImage(UIImage(systemName: "backward.end.fill"), for: .normal)
        button.addTarget(self, action: #selector(playPause), for: .touchUpInside)
        return button
    }()
    
    
    var mediaType: MediaType = .video
    let audioSession = AVAudioSession.sharedInstance()
    var assetImage: UIImage?
    
    private var castButton: GCKUICastButton!
    let airplayButton = MPVolumeView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        airplayButton.showsVolumeSlider = false
        
        descriptionLabel.text = asset?.localized?.first?.description
        
        castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        castButton.tintColor = UIColor.gray
        let castButtonMiniPlayer = UIBarButtonItem(customView: castButton)
        
        let airplayButtonMiniPlayer = UIBarButtonItem(customView: airplayButton)
        
        GCKCastContext.sharedInstance().sessionManager.add(self)
        self.popupItem.leadingBarButtonItems = [self.playButtonMiniPlayer]
        self.popupItem.trailingBarButtonItems = [stopButtonMiniPlayer, castButtonMiniPlayer, airplayButtonMiniPlayer]
        
        
        vodBasedTimeline.isHidden = true
        programBasedTimeline.isHidden = true
        
        self.playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: self.largeConfig), for: .normal)
        
        setUpUI()
        setupPlayer(environment, sessionToken)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    fileprivate func setupPlayer(_ environment: Environment, _ sessionToken: SessionToken) {
        
        /// This will configure the player with the `SessionToken` acquired in the specified `Environment`
        StickyPlayerViewController.player = Player(environment: environment, sessionToken: sessionToken)
        
        
        let _ = StickyPlayerViewController.player.configure(playerView: playerView)
        
        // The preparation and loading process can be followed by listening to associated events.
        StickyPlayerViewController.player
            .onPlaybackCreated{ [weak self] player, source in
                
            }
            .onPlaybackPrepared{ player, source in
                // Published when the associated MediaSource completed asynchronous loading of relevant properties.
                // Playback is not ready to start at this point.
            }
            .onPlaybackReady{ player, source in
                // When this event fires starting playback is possible (playback can optionally be set to autoplay instead)
                player.play()
                
            }
        
        // Once playback is in progress the Player continuously publishes events related media status and user interaction.
            .onPlaybackStarted { [weak self] player, source in
                // Published once the playback starts for the first time.
                // This is a one-time event.
                guard let `self` = self else { return }
                
                self.popupItem.leadingBarButtonItems = [self.pauseButtonMiniPlayer]
                self.playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: self.largeConfig), for: .normal)
                
                self.enableAudioSeesionForPlayer()
                self.setupNowPlaying(program: nil)
                self.updateProgress(program: nil)
                self.setupNotifications()
                self.setupRemoteCommands()
                
            }
            .onPlaybackPaused{ [weak self] player, source in
                // Fires when the playback pauses for some reason
                guard let `self` = self else { return }
                
                self.popupItem.leadingBarButtonItems = [self.playButtonMiniPlayer]
                
                self.playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: self.largeConfig), for: .normal)
                
                MPNowPlayingInfoCenter.default().playbackState = .paused
            }
            .onPlaybackResumed{ [weak self] player, source in
                // Fires when the playback resumes from a paused state
                guard let `self` = self else { return }
                
                self.popupItem.leadingBarButtonItems = [self.pauseButtonMiniPlayer]
                self.playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: self.largeConfig), for: .normal)
                
                MPNowPlayingInfoCenter.default().playbackState = .playing
                
            }
            .onPlaybackAborted{ player, source in
                // Published once the player.stop() method is called.
                // This is considered a user action
                
                self.popupItem.leadingBarButtonItems = [self.playButtonMiniPlayer]
                self.playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: self.largeConfig), for: .normal)
                
                MPNowPlayingInfoCenter.default().playbackState = .stopped
            }
            .onPlaybackCompleted{ player, source in
                // Published when playback reached the end of the current media.
                
                self.popupItem.leadingBarButtonItems = [self.playButtonMiniPlayer]
                self.playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: self.largeConfig), for: .normal)
                
                MPNowPlayingInfoCenter.default().playbackState = .stopped
            }
        
        
        
        // Besides playback control events Player also publishes several status related events.
            .onProgramChanged { [weak self] player, source, program in
                // Update user facing program information
                guard let `self` = self else { return }

                self.updateProgress(program: program)
                self.setupNowPlaying(program: program)
                self.programBasedTimeline.currentProgram = program
                
            }
        
            .onEntitlementResponse { [weak self] player, source, entitlement  in
                // Fires when a new entitlement is received, such as after attempting to start playback
                guard let `self` = self else { return }
                
            }
            .onBitrateChanged{ player, source, bitrate in
                // Published whenever the current bitrate changes
                //self?.updateQualityIndicator(with: bitrate)
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
        
        // Error handling can be done by listening to associated event.
            .onError{ [weak self] player, source, error in
                guard let `self` = self else { return }
                
                let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                })
                
                let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
            }
        
            .onWarning{ [weak self] player, source, warning in
                guard let `self` = self else { return }
                
                // self.showToastMessage(message: warning.message, duration: 5)
            }
        
        // Media Type
            .onMediaType { [weak self] type in
                
                guard let `self` = self else { return }
                
                self.mediaType = type
                self.setUpUI()
            }
        
        
        // External playback
            .onAirplayStatusChanged { [weak self] player, source, active in
                print(" Airplay status changed " , active )
                
            }
        
        // Playback Progress
        programBasedTimeline.onSeek = { [weak self] offset in
            StickyPlayerViewController.player.seek(toTime: offset)
        }
        
        programBasedTimeline.currentPlayheadTime = { [weak self] in
            return StickyPlayerViewController.player.playheadTime
        }
        
        programBasedTimeline.timeBehindLiveEdge = { [weak self] in
            return StickyPlayerViewController.player.timeBehindLive
        }
        programBasedTimeline.goLiveTrigger = { [weak self] in
            StickyPlayerViewController.player.seekToLive()
        }
        programBasedTimeline.startOverTrigger = { [weak self] in
            if let programStartTime = StickyPlayerViewController.player.currentProgram?.startDate?.millisecondsSince1970 {
                StickyPlayerViewController.player.seek(toTime: programStartTime)
            }
        }
        
        vodBasedTimeline.onSeek = { [weak self] offset in
            StickyPlayerViewController.player.seek(toPosition: offset)
        }
        
        vodBasedTimeline.currentPlayheadPosition = { [weak self] in
            return StickyPlayerViewController.player.playheadPosition
        }
        vodBasedTimeline.currentDuration = { [weak self] in
            return StickyPlayerViewController.player.duration
        }
        
        vodBasedTimeline.startOverTrigger = { [weak self] in
            StickyPlayerViewController.player.seek(toPosition:0)
        }
        
        self.startPlayBack()
    }
    
    // Update progress in Mini Player
    fileprivate func updateProgress(program: Program?) {
        
        let playheadTime = StickyPlayerViewController.player.playheadTime
        var programStart = program?.startDate?.millisecondsSince1970
        var programEnd = program?.endDate?.millisecondsSince1970
        
        // When playing a channel (no Epg ) , channel stream does not have any start Date, so we will use the startTime
        if programStart == nil {
            if let startTime = program?.startTime, let startTimeInUnix = Int(startTime) {
                programStart = Date(timeIntervalSince1970: TimeInterval(Int(startTimeInUnix))).millisecondsSince1970
            }
        }
        
        // If the program End time is missing we matched the end time to the current live time
        if programEnd == nil {
            let playheadTime = StickyPlayerViewController.player.playheadTime
            let timeBehindLive = StickyPlayerViewController.player.timeBehindLive
            programEnd = playheadTime != nil && timeBehindLive != nil ? playheadTime! - timeBehindLive! : nil
        }
        
        if let start = programStart, let end = programEnd {
            
            if let playhead = playheadTime {
                if start <= playhead && playhead <= end {
                    let progress = Float(playhead - start) / Float(end - start)
                    self.popupItem.progress = progress
                    
                }
            } else {
                let progress = Float(start) / Float(end - start)
                self.popupItem.progress = progress
            }
        }
        else {
            self.popupItem.progress = 1.0
        }
    }
    
    
    fileprivate func startPlayBack() {
        
        if let assetPlayable = playable {
            
            // Check if have a cast session
            if GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession() {
                self.chromecast(playable: assetPlayable, in: environment, sessionToken: sessionToken, currentplayheadTime: StickyPlayerViewController.player.playheadTime)
            } else {
                StickyPlayerViewController.player.startPlayback(playable: assetPlayable)
            }
            
            if let assetType = asset?.type {
                
                switch assetType {
                case .TV_CHANNEL:
                    showProgramTimeLine()
                case .MOVIE:
                    showVodTimeline()
                case .LIVE_EVENT:
                    showProgramTimeLine()
                case .TV_SHOW:
                    showVodTimeline()
                case .EPISODE:
                    showVodTimeline()
                case .CLIP:
                    showVodTimeline()
                case .AD:
                    showVodTimeline()
                case .OTHER:
                    showProgramTimeLine()
                case .COLLECTION:
                    showVodTimeline()
                @unknown default:
                    showVodTimeline()
                }
            }
        }
    }
    
    @objc func playPause() {
        if StickyPlayerViewController.player.isPlaying {
            self.popupItem.leadingBarButtonItems = [playButtonMiniPlayer]
            StickyPlayerViewController.player.pause()
        } else {
            self.popupItem.leadingBarButtonItems = [pauseButtonMiniPlayer]
            StickyPlayerViewController.player.play()
        }
    }
    
    @objc func stopPlayBack() {
        StickyPlayerViewController.player.stop()
        popupPresentationContainer?.dismissPopupBar(animated: true, completion: nil)
    }
    
    @objc func startCast() {
        
    }
}

extension StickyPlayerViewController {
    fileprivate func setUpUI() {
        
        self.view.addSubview(playerView)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        // Show the thumb image if it's an audio
        if mediaType == .audio {
            self.view.addSubview(imageView)
            
            imageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, bottom: nil, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: .init(top: 50, left: 0, bottom: 0, right: 0) , size: .init(width: 300, height: 150))
            
            if let asset = asset, let urlString = asset.localized?.first?.images?.first?.url, let url = URL(string: urlString) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        if let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                
                                imageView.image = image
                                
                            }
                        }
                    }
                }
            } else {
                // Show place holder image
                imageView.image = UIImage(named: "placeholder.png")
            }
            
            view.addSubview(descriptionLabel)
            descriptionLabel.anchor(top: imageView.bottomAnchor, bottom: nil, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: .init(top: 50, left: 20, bottom: 0, right: -20))
            
        } else {
            playerView.anchor(top: view.topAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, size: .init(width: view.frame.size.width, height: 400))
        }
        
        view.addSubview(timelineStackView)
        
        timelineStackView.anchor(top: playerView.bottomAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 20, left: 20, bottom: 0, right: -20), size: .init(width: self.view.frame.size.width, height: 100))
        
        
        timelineStackView.addArrangedSubview(vodBasedTimeline)
        timelineStackView.addSubview(programBasedTimeline)
        
        programBasedTimeline.anchor(top: timelineStackView.topAnchor, bottom: timelineStackView.bottomAnchor, leading: timelineStackView.leadingAnchor, trailing: timelineStackView.trailingAnchor, padding: .init(top: 0, left: 10, bottom: -10, right: -10))
        
        vodBasedTimeline.anchor(top: timelineStackView.topAnchor, bottom: timelineStackView.bottomAnchor, leading: timelineStackView.leadingAnchor, trailing: timelineStackView.trailingAnchor, padding: .init(top: 0, left: 10, bottom: -10, right: -10))
        
        view.addSubview(playerStackView)
        
        playerStackView.anchor(top: timelineStackView.bottomAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 20, bottom: 0, right: -20), size: .init(width: self.view.frame.size.width, height: 100))
        

        castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        castButton.tintColor = UIColor.gray
        
        castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))

        
        let volumeView = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 24, height: 24) )
        volumeView.showsVolumeSlider = false
        
        
        playerStackView.addArrangedSubview(previousButton)
        playerStackView.addArrangedSubview(playPauseButton)
        playerStackView.addArrangedSubview(nextButton)
        
        
        let shareButtonHolderView = UIStackView(arrangedSubviews: [volumeView, castButton])
        shareButtonHolderView.alignment = .fill
        shareButtonHolderView.axis = .horizontal
        shareButtonHolderView.distribution = .fillEqually
        shareButtonHolderView.spacing = 20
        
        view.addSubview(shareButtonHolderView)
        
        shareButtonHolderView.anchor(top: playerStackView.bottomAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
        
    }
}

// MARK: - Enable Background Audio
extension StickyPlayerViewController {
    /// Enable the audio session for player
    fileprivate func enableAudioSeesionForPlayer() {
        do {
            if #available(iOS 11.0, *) {
                if self.mediaType == .audio {
                    try audioSession.setCategory(AVAudioSession.Category.playback, mode: .moviePlayback, policy: .longFormAudio)
                } else {
                    try audioSession.setCategory(AVAudioSession.Category.playback, mode: .moviePlayback, policy: .longFormVideo)
                }
                
            }
            else {
                try audioSession.setCategory(AVAudioSession.Category.playback)
            }
            
            try audioSession.setActive(true)
            
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
}

// MARK: - Control Background Audio from Control Center
extension StickyPlayerViewController {
    
    func setupNowPlaying(program: Program? ) {

        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = asset?.localized?.first?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] =  asset?.localized?.first?.description
        
        if let image = self.assetImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }
        
        if self.mediaType == .audio  {
            nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = NSNumber(value: MPNowPlayingInfoMediaType.audio.rawValue) }
        else { nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = NSNumber(value: MPNowPlayingInfoMediaType.video.rawValue) }
        

        // Play an program as live : This may not be true for catchup programs.
        if let program = program {
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        } else {
            if let playheadTime = StickyPlayerViewController.player.playheadTime, let duration = StickyPlayerViewController.player.duration, duration > 0 {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: Double(duration )/1000)
                //  info[MPNowPlayingInfoPropertyPlaybackProgress] = Float(playhead) / Float(duration)
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: Double(playheadTime-0)/1000)
            } else {
                nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
            }
        }
        
        
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = StickyPlayerViewController.player.isPlaying ? 1.0 : 0.0
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func setupRemoteCommands() {
        
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            
            if !StickyPlayerViewController.player.isPlaying {
                StickyPlayerViewController.player.play()
                
                self.popupItem.leadingBarButtonItems = [self.pauseButtonMiniPlayer]
                self.playPauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
                
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if StickyPlayerViewController.player.isPlaying {
                
                self.popupItem.leadingBarButtonItems = [self.playButtonMiniPlayer]
                self.playPauseButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
                
                StickyPlayerViewController.player.pause()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Next Track Command
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            print(" Start playing next track")
            return .commandFailed
        }
        
        // Add handler for previous Track Command
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            print(" Stop playing previous track")
            return .commandFailed
        }
        
    }
    
}

// MARK: Handle Notifications
extension StickyPlayerViewController {
    
    func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(handleInterruption),
                                       name: AVAudioSession.interruptionNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(handleRouteChange),
                                       name: AVAudioSession.routeChangeNotification,
                                       object: nil)
    }
    
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                  return
              }
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                DispatchQueue.main.sync {
                    StickyPlayerViewController.player.play()
                }
                break
            }
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                    DispatchQueue.main.sync {
                        StickyPlayerViewController.player.pause()
                    }
                    break
                }
            }
        default: ()
        }
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                  return
              }
        
        if type == .began {
            // An interruption began. Update the UI as necessary.
            print("Interruption began")
        }
        else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // An interruption ended. Resume playback.
                    StickyPlayerViewController.player.play()
                } else {
                    // An interruption ended. Don't resume playback.
                    print("Interruption Ended")
                }
            }
        }
    }
}

extension StickyPlayerViewController {
    
    private func showVodTimeline() {
        programBasedTimeline.isHidden = true
        programBasedTimeline.stopLoop()
        
        vodBasedTimeline.isHidden = false
        vodBasedTimeline.startLoop()
        
    }
    
    private func showProgramTimeLine() {
    
        programBasedTimeline.isHidden = false
        programBasedTimeline.startLoop()
        
        vodBasedTimeline.isHidden = true
        vodBasedTimeline.stopLoop()
    }
}


// MARK: - Chrome Cast
extension StickyPlayerViewController: GCKRemoteMediaClientListener, GCKSessionManagerListener {
    
    
    func sessionManager(_: GCKSessionManager, didResumeSession session: GCKSession) {
        print("sessionManager didResumeSession \(session)")
    }
    
    func sessionManager(_: GCKSessionManager, didFailToStartSessionWithError error: Error?) {
        if let error = error {
            print( "Failed to start a session", error.localizedDescription)
        }
        
    }
    
    func requestDidComplete(_ request: GCKRequest) {
        print("request \(Int(request.requestID)) completed")
    }
    
    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        print("request \(Int(request.requestID)) failed with error \(error)")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        if error == nil {
            print("GCKSessionManagerListener Session ended")
            
        } else {
            print("GCKSessionManagerListener Session ended unexpectedly:\n \(error?.localizedDescription ?? "")")
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        sessionManager.remove(self)
        
        // HACK: Instruct the relevant analyticsProviders that startCasting event took place
        // TODO: We do not have nor want a strong coupling between the Cast and Player framework.
        StickyPlayerViewController.player.tech.currentSource?.analyticsConnector.providers
            .compactMap{ $0 as? ExposureAnalytics }
            .forEach{ $0.startedCasting() }
        
        StickyPlayerViewController.player.stop()
        
        popupPresentationContainer?.dismissPopupBar(animated: true, completion: nil)
        
        guard let env = environment, let token = sessionToken else { return }
        let currentplayheadTime = StickyPlayerViewController.player.playheadTime
        if let playable = playable {
            self.chromecast(playable: playable, in: env, sessionToken: token, currentplayheadTime : currentplayheadTime)
        }
        
        // testing
        
    }
    
    
    func chromecast(playable: Playable, in environment: Exposure.Environment, sessionToken: SessionToken, localOffset: Int64? = nil, currentplayheadTime : Int64?) {
        
        
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
            
            if let playheadTime = currentplayheadTime {
                mediaLoadRequestDataBuilder.startTime = TimeInterval(playheadTime/1000)
            }
            let _ = remoteMediaClient.loadMedia(with: mediaLoadRequestDataBuilder.build())
            
        }
        
    }
    
}
