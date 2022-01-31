## Sample implementation of `iOSClientExposurePlayback` sdk

#### Targets

Sample application provides three different targets for application developers to follow. 

- `SDKSampleApp` provides an UIKIt based iOS sample app 
- `SDKSampleAppTvOS` provides tvOS sample app with default / native skin
- `SDKSampleSwiftUI` provides an SwiftUI based iOS sample app 


#### PreRequisites

- You need to fill your production / pre stage url, Customer Unit Name / Business Unit Name in Environments Screen. Then you can fill in your username / email & Password in Login Screen. 

- You need a valid `ChromeCast receiver id` to enable chrome casting in the app. 

```Swift
// AppDelegate
let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: "")) // Set your chrome cast app id here
```


#### Player

You will find two sample player implementations inside the `SDKSampleApp` target. 
- `PlayerViewController` show all the available options / functions in the player 
- `StickyPlayerViewController`show how the player can be used as a sticky player within the app. This will be specially helpful if you are planning to add audio only player inside your own app. 


##### Sticky Player

Client application developers are responsible for creating their own sticky player implementation. SDK it self supports both video playback & audio only playback. You can create a UIView & assign the player to that view & use it inside your application without a video area.

Sample application provides an example sticky player implementation using [`LNPopupController`](https://github.com/LeoNatan/LNPopupController)


##### Enabling Background Audio

Please read more on Apple's documentation : [`Enabling Background Audio`](https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/creating_a_basic_video_player_ios_and_tvos/enabling_background_audio)

SDK supports playback of background audio. But as a client application developer you need to grant the permission for the background audio in your Xcode. 

*Enable “Audio, AirPlay and Picture in Picture” in your targets Capabilities.*

Then you can configure & add category to your `AVAudioSession`

```Swift
func enableAudioSeesionForPlayer() {
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
```


##### Controlling playback & showing display info in iOS Control Center

Please read more on Apple's documentation : [`Controlling Background Audio`](https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/creating_a_basic_video_player_ios_and_tvos/controlling_background_audio)


You need to add the Asset's Meta data to `MPNowPlayingInfoCenter` to show the correct meta data in iOS Control center. 


```Swift
func setupNowPlaying(program: Program? ) {

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
    
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = StickyPlayerViewController.player.isPlaying ? 1.0 : 0.0

    // Set the metadata
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
 }
```

You need to configure the Remote Command Handlers using `MPRemoteCommandCenter ` to control your playback controls via iOS control center. 


```Swift
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
            print(" Start playing previous track")
            return .commandFailed
        }
        
    }
```


##### Handle Audio Interruptions

Please read more on Apple's documentation : [`Responding to Audio Session Interruptions`](https://developer.apple.com/documentation/avfaudio/avaudiosession/responding_to_audio_session_interruptions)


First you need to observe the Interruption notifications & then respond accordingly. 

```Swift
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
```














