//
//  AppDelegate.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-17.
//

import UIKit
import iOSClientCast
import GoogleCast
import iOSClientExposureDownload
import iOSClientDownload
import AVFoundation
import BackgroundTasks
import iOSClientExposure

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GCKRemoteMediaClientListener, GCKSessionManagerListener {
    
    var window: UIWindow?
    var castChannel: Channel = Channel()
    var castSession: GCKCastSession?
    
    
    let tabBarController = UITabBarController()
    var mainNavCtrl: UINavigationController?
    
    let appRefreshTaskId = "com.emp.ExposurePlayback.SampleApp.analyticsFlush"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        application.beginReceivingRemoteControlEvents()
        
//        var paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        let documentsDirectory = paths[0]
//        let fileName = "\(Date()).log"
//        let logFilePath = (documentsDirectory as NSString).appendingPathComponent(fileName)
//        freopen(logFilePath.cString(using: String.Encoding.ascii)!, "a+", stderr)
        
        
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: "")) // Set your chrome cast app id here
        options.physicalVolumeButtonsWillControlDeviceVolume = true
        GCKCastContext.setSharedInstanceWith(options)
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(presentExpandedMediaControls), name: NSNotification.Name.gckExpandedMediaControlsTriggered, object: nil)
        
        GCKCastContext.sharedInstance().sessionManager.add(self)
        
        // Read more about the background processing for offline analytics in the documentation:
        // https://github.com/EricssonBroadcastServices/iOSClientExposurePlayback/blob/master/Documentation/offlineAnalytics.md
        BGTaskScheduler.shared.register(forTaskWithIdentifier: self.appRefreshTaskId, using: nil) { task in
            self.handleFlusingOfflineAnalytics(task: task as! BGProcessingTask)
            
        }
        
        
        // Enable all the logs if needed
        //        let logFilter = GCKLoggerFilter()
        //        logFilter.minimumLevel = .verbose
        //        GCKLogger.sharedInstance().filter = logFilter
        //        GCKLogger.sharedInstance().delegate = self
        
        
        //        let styler = GCKUIStyle.sharedInstance()
        //        styler.castViews.iconTintColor = .lightGray
        //        styler.castViews.mediaControl.expandedController.iconTintColor = .green
        //        styler.castViews.backgroundColor = .white
        //        styler.castViews.mediaControl.miniController.backgroundColor = .yellow
        //        styler.castViews.headingTextFont = UIFont.init(name: "Courier-Oblique", size: 16) ?? UIFont.systemFont(ofSize: 16)
        //        styler.castViews.mediaControl.headingTextFont = UIFont.init(name: "Courier-Oblique", size: 6) ?? UIFont.systemFont(ofSize: 6)
        //        let muteOnImage = UIImage.init(named: "volume0.png")
        //        if let muteOnImage = muteOnImage {
        //          styler.castViews.muteOnImage = muteOnImage
        //        }
        //
        //        styler.apply()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let navigationController = MainNavigationController()
        
        let castContainerVC = GCKCastContext.sharedInstance().createCastContainerController(for: navigationController)
        as GCKUICastContainerViewController
        castContainerVC.miniMediaControlsItemEnabled = true
        
        window?.rootViewController = castContainerVC
        window?.makeKeyAndVisible()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.scheduleAppRefresh(minutes: 2)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.cancelAllPendingBGTask()
    }
    
    func cancelAllPendingBGTask() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    func scheduleAppRefresh(minutes: Int) {
        
        let seconds = TimeInterval(minutes * 60)
        
        let request = BGProcessingTaskRequest(identifier: self.appRefreshTaskId )
        request.earliestBeginDate = Date(timeIntervalSinceNow: seconds)
        request.requiresNetworkConnectivity = true
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh task \(error.localizedDescription)")
        }
    }
    
    func handleFlusingOfflineAnalytics(task: BGProcessingTask) {
        
        // Schedule a new refresh task : Define the minutes
        scheduleAppRefresh(minutes: 2)
        
        let manager = iOSClientExposure.BackgroundAnalyticsManager()
        manager.flushOfflineAnalytics()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
            task.setTaskCompleted(success: true)
        }
        
        task.expirationHandler = {
            
            self.cancelAllPendingBGTask()
        }
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
                    
                    let expandedControls = GCKCastContext.sharedInstance().defaultExpandedMediaControlsViewController
                    
                    let ccViewController = TrackSelectionViewController()
                    
                    // ccViewController.assign(audio: tracksUpdated.audio)
                    // ccViewController.assign(text: tracksUpdated.subtitles)
                    
                    ccViewController.onDidSelectAudio = { [weak self] track in
                        guard let `self` = self, let track = track as? iOSClientCast.Track else { return }
                        self.castChannel.use(audioTrack: track)
                    }
                    ccViewController.onDidSelectText = { [weak self] track in
                        guard let `self` = self else { return }
                        if let track = track as? iOSClientCast.Track {
                            self.castChannel.use(textTrack: track)
                        }
                        else {
                            self.castChannel.hideSubtitles()
                        }
                    }
                    ccViewController.onDismissed = { [weak ccViewController] in
                        ccViewController?.dismiss(animated: true)
                    }
                    expandedControls.present(ccViewController, animated: true)
                }
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


// MARK: - Enable Background Downloads
extension AppDelegate {
    
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        if identifier == SessionConfigurationIdentifier.default.rawValue {
            print("🛏 Rejoining session \(identifier)")
            let sessionManager = ExposureSessionManager.shared.manager
            sessionManager.backgroundCompletionHandler = completionHandler
            
            sessionManager.restoreTasks { downloadTasks in
                downloadTasks.forEach {
                    print("🛏 found",$0.taskDescription ?? "")
                    // Restore state
                    // self.log(downloadTask: $0)
                }
            }
            
            sessionManager.backgroundErrorCompletionHandler = { error in
                print(" backgroundErrorCompletionHandler in app Delegate " , error)
            }
        }
    }
    
    private func log(downloadTask: AVAssetDownloadTask) {
        print(" Download task state " , downloadTask )
    }
}


class ExposureSessionManager {
    static let shared = ExposureSessionManager()
    let manager = iOSClientDownload.SessionManager<ExposureDownloadTask>()
}
