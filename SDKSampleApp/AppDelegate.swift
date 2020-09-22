//
//  AppDelegate.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-17.
//

import UIKit
import Cast
import GoogleCast

@main
class AppDelegate: UIResponder, UIApplicationDelegate, GCKRemoteMediaClientListener, GCKSessionManagerListener {

    var window: UIWindow?
    var castChannel: Channel = Channel()
    var castSession: GCKCastSession?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: ""))
        options.physicalVolumeButtonsWillControlDeviceVolume = true
        GCKCastContext.setSharedInstanceWith(options)
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(presentExpandedMediaControls), name: NSNotification.Name.gckExpandedMediaControlsTriggered, object: nil)
        
        GCKCastContext.sharedInstance().sessionManager.add(self)
        
//        let logFilter = GCKLoggerFilter()
//        logFilter.minimumLevel = .verbose
//        GCKLogger.sharedInstance().filter = logFilter
//        GCKLogger.sharedInstance().delegate = self
        
        
        let styler = GCKUIStyle.sharedInstance()
        styler.castViews.iconTintColor = .lightGray
        styler.castViews.mediaControl.expandedController.iconTintColor = .green
        styler.castViews.backgroundColor = .white
        styler.castViews.mediaControl.miniController.backgroundColor = .yellow
        styler.castViews.headingTextFont = UIFont.init(name: "Courier-Oblique", size: 16) ?? UIFont.systemFont(ofSize: 16)
        styler.castViews.mediaControl.headingTextFont = UIFont.init(name: "Courier-Oblique", size: 6) ?? UIFont.systemFont(ofSize: 6)
        let muteOnImage = UIImage.init(named: "volume0.png")
        if let muteOnImage = muteOnImage {
          styler.castViews.muteOnImage = muteOnImage
        }
        styler.apply()
        GCKUICastButton.appearance().tintColor = UIColor.gray
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // window = UIWindow()
        let navigationController = MainNavigationController()
        
        let castContainerVC = GCKCastContext.sharedInstance().createCastContainerController(for: navigationController)
          as GCKUICastContainerViewController
        castContainerVC.miniMediaControlsItemEnabled = true
        
        window?.rootViewController = castContainerVC
        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.gckExpandedMediaControlsTriggered, object: nil)
    }
    
    func hookChromecastListener() {
        
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }
        
        // Assign ChromeCast session listener
        GCKCastContext.sharedInstance().sessionManager.add(self)
        castSession = session
        session.add(castChannel)
        session.remoteMediaClient?.add(self)
        
        castChannel
            .onTracksUpdated { [weak self] tracksUpdated in
                let expandedControls = GCKCastContext.sharedInstance().defaultExpandedMediaControlsViewController
                guard let `self` = self else { return }
                let customButton = ChromeCastButton()
                customButton.setTitle("CC", for: .normal)
                customButton.setTitleColor(UIColor.white, for: .normal)
                
                customButton.addTarget(customButton, action: #selector(ChromeCastButton.trigger), for: UIControl.Event.touchUpInside)
                expandedControls.setButtonType(GCKUIMediaButtonType.custom, at: 0)
                expandedControls.setCustomButton(customButton, at: 0)
                
                customButton.triggerAction = {
                    
//                    let expandedControls = GCKCastContext.sharedInstance().defaultExpandedMediaControlsViewController
//                    let storyBoard = UIStoryboard(name: "TestEnv", bundle: nil)
//                    let ccViewController = storyBoard.instantiateViewController(withIdentifier: "TrackSelectionViewController") as! TrackSelectionViewController
//
//                    // ccViewController.assign(audio: tracksUpdated.audio)
//                    // ccViewController.assign(text: tracksUpdated.subtitles)
//                    ccViewController.onDidSelectAudio = { [weak self] track in
//                        guard let `self` = self, let track = track as? Cast.Track else { return }
//                        self.castChannel.use(audioTrack: track)
//                    }
//                    ccViewController.onDidSelectText = { [weak self] track in
//                        guard let `self` = self else { return }
//                        if let track = track as? Cast.Track {
//                            self.castChannel.use(textTrack: track)
//                        }
//                        else {
//                            self.castChannel.hideSubtitles()
//                        }
//                    }
//                    ccViewController.onDismissed = { [weak ccViewController] in
//                        ccViewController?.dismiss(animated: true)
//                    }
//                    expandedControls.present(ccViewController, animated: true)
                }
                
                print("Cast.Channel onTracksUpdated Audio",tracksUpdated.audio)
                print("Cast.Channel onTracksUpdated Subs ",tracksUpdated.subtitles)
            }
            .onTimeshiftEnabled{ timeshift in
                print("Cast.Channel onTimeshiftEnabled",timeshift)
            }
            .onVolumeChanged { volumeChanged in
                print("Cast.Channel onVolumeChanged",volumeChanged)
            }
            .onStartTimeLive{ startTime in
                print("Cast.Channel onStartTimeLive",startTime)
            }
            .onProgramUpdated{ program in
                print("Cast.Channel onProgramChanged",program)
            }
            .onEntitlementChange{ [weak self] entitlement in
                let expandedControls = GCKCastContext.sharedInstance().defaultExpandedMediaControlsViewController
                guard let `self` = self else { return }
                let rw = ChromeCastButton()
                rw.setTitle("RW10", for: .normal)
                rw.setTitleColor(UIColor.white, for: .normal)
                rw.setTitleColor(UIColor.gray, for: UIControl.State.disabled)
                
                rw.addTarget(rw, action: #selector(ChromeCastButton.trigger), for: UIControl.Event.touchUpInside)
                expandedControls.setButtonType(GCKUIMediaButtonType.custom, at: 1)
                expandedControls.setCustomButton(rw, at: 1)
                
                rw.isEnabled = entitlement.rwEnabled
                rw.triggerAction = { [weak self] in
                    if let position = self?.castSession?.remoteMediaClient?.approximateStreamPosition() {
                        let seekOptions = GCKMediaSeekOptions()
                        seekOptions.interval = position - 10
                        self?.castSession?.remoteMediaClient?.seek(with: seekOptions)
                    }
                }
                
                let ff = ChromeCastButton()
                ff.setTitle("FF10", for: .normal)
                ff.setTitleColor(UIColor.white, for: .normal)
                ff.setTitleColor(UIColor.gray, for: UIControl.State.disabled)
                
                ff.addTarget(ff, action: #selector(ChromeCastButton.trigger), for: UIControl.Event.touchUpInside)
                expandedControls.setButtonType(GCKUIMediaButtonType.custom, at: 2)
                expandedControls.setCustomButton(ff, at: 2)
                
                ff.isEnabled = entitlement.ffEnabled
                ff.triggerAction = { [weak self] in
                    if let position = self?.castSession?.remoteMediaClient?.approximateStreamPosition() {
                        let seekOptions = GCKMediaSeekOptions()
                        seekOptions.interval = position + 10
                        self?.castSession?.remoteMediaClient?.seek(with: seekOptions)
                    }
                }
            }
            .onSegmentMissing{ segment in
                print("Cast.Channel onSegmentMissing",segment)
            }
            .onAutoplay { autoplay in
                print("Cast.Channel onAutoplay",autoplay)
            }
            .onIsLive { isLive in
                print("Cast.Channel onIsLive",isLive)
            }
            .onError{ error in
                print("Cast.Channel onError",error)
        }
        
        castChannel.pull()
    }
    
    @objc func presentExpandedMediaControls() {
        print("present expanded media controls")
        // Segue directly to the ExpandedViewController.
        if let castContainerVC = window?.rootViewController as? GCKUICastContainerViewController {
            let expandedControls = GCKCastContext.sharedInstance().defaultExpandedMediaControlsViewController
            castContainerVC.present(expandedControls, animated: true)
        }
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        print(#function)
    }
}


// MARK: - GCKLoggerDelegate
extension AppDelegate: GCKLoggerDelegate {
    func logMessage(_ message: String, fromFunction function: String) {
        print("\(function)  \(message)")
    }
}

// MARK: - GCKSessionManagerListener
extension AppDelegate {
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        hookChromecastListener()
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        hookChromecastListener()
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        if error == nil {
            print("GCKSessionManagerListener Session ended")
        } else {
            print("GCKSessionManagerListener Session ended unexpectedly:\n \(error?.localizedDescription ?? "")")
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        print("GCKSessionManagerListener Failed to start session:\n\(error.localizedDescription)")
    }
}

class ChromeCastButton: UIButton {
    var triggerAction: () -> Void = { }
    
    @objc func trigger() {
        triggerAction()
    }
}
