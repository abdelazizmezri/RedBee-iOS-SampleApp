//
//  AssetListTableViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-21.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import iOSClientExposure
import iOSClientExposurePlayback
import iOSClientExposureDownload
import LNPopupController

class AssetListTableViewController: UITableViewController, EnigmaDownloadManager {
    
    var selectedAsssetType: String!
    var assets = [Asset]()
    var downloadedAssets: [OfflineMediaAsset]?
    var sessionToken: SessionToken?
    
    let cellId = "assetListTableViewCell"

    
    // MARK: Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .white
        
        
        self.generateTableViewContent()
        
        // All downloaded assets
        downloadedAssets = self.enigmaDownloadManager.getDownloadedAssets()
        
    }
}

// MARK: - DataSource
extension AssetListTableViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    /// Generate tableview content by loading assets from API
    fileprivate func generateTableViewContent() {
        
        guard let environment = StorageProvider.storedEnvironment, let _ = StorageProvider.storedSessionToken else {
            
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                
            })
            
            let message = "Invalid Session Token, please login again"
            self.popupAlert(title: "Error" , message: message, actions: [okAction], preferedStyle: .alert)
            return
        }
        
        if selectedAsssetType == "LIVE_EVENTS_USING_EVENT_ENDPOINT" {
            self.loadEvents(environment: environment)
        }
        else {
            // MOVIE / TV_CHANNEL
            let query = ""
            loadAssets(query: query, environment: environment, endpoint: "/content/asset?assetType=\(selectedAsssetType!)&pageSize=100&pageNumber=1", method: HTTPMethod.get)
        }
    }
    
    
    
    func refreshTableView() {
        downloadedAssets = self.enigmaDownloadManager.getDownloadedAssets()
        tableView.reloadData()
    }
    
    
    /// Navigate to EPG View
    func showEPGView(asset: Asset) {
        let destinationViewController = EPGListViewController()
        destinationViewController.channel = asset
        self.navigationController?.pushViewController(destinationViewController, animated: false)
    }
    
}


extension AssetListTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if assets.count == 0 {
            tableView.showEmptyMessage(message: NSLocalizedString("Sorry no data to show", comment: ""))
        } else {
            tableView.hideEmptyMessage()
        }
        return assets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        let asset = assets[indexPath.row]
        
        cell.selectionStyle = .none
        cell.backgroundColor = .white
        cell.textLabel?.textColor = .black
        cell.detailTextLabel?.textColor = .black
        
        cell.textLabel?.text = asset.localized?.first?.title ?? asset.assetId
        
        if let _ = downloadedAssets?.first(where: { $0.assetId == asset.assetId }) {
            cell.detailTextLabel?.text = "Available in downloads"
        } else {
            cell.detailTextLabel?.text = asset.assetId
        }
        
        return cell
    }
}


// MARK: - TableView Delegate
extension AssetListTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let asset = assets[indexPath.row]
        
        if let type = asset.type {
            switch type {
            case AssetType.LIVE_EVENT:
                let playable = AssetPlayable(assetId: asset.assetId)
                self.handlePlay(playable: playable, asset: asset)
            case AssetType.TV_CHANNEL:
                self.showOptions(asset: asset)
            case AssetType.MOVIE:
                self.showOptions(asset: asset)
            default:
                let playable = AssetPlayable(assetId: asset.assetId)
                self.handlePlay(playable: playable, asset: asset)
                
                break
            }
        }
    }
    
    /// Show options for the channel: Play using AssetPlay / ChannelPlay / Navigate to EPG View / Show Download options
    ///
    /// - Parameter asset: asset
    fileprivate func showOptions(asset: Asset) {
        if asset.type == AssetType.MOVIE {
            let destinationVC = AssetDetailsViewController()
            destinationVC.assetId =  asset.assetId

            self.navigationController?.pushViewController(destinationVC, animated: false)
        } else {
            let gotoEPG = UIAlertAction(title: "Go to EPG View", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.showEPGView(asset: asset)
            })
            
            let playChannelPlayable = UIAlertAction(title: "Play Channel Using Channel Playable - Test Only", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                let playable = ChannelPlayable(assetId: asset.assetId)
                self.handlePlay(playable: playable, asset: asset)
                
            })
            
            let playAssetPlayable = UIAlertAction(title: "Play Channel Using Asset Playable", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                let playable = AssetPlayable(assetId: asset.assetId)
                self.handlePlay(playable: playable, asset: asset)
            })
            
            let message = "Choose option"
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            
            self.popupAlert(title: nil, message: message, actions: [gotoEPG, playAssetPlayable, playChannelPlayable, cancelAction], preferedStyle: .actionSheet)
        }
    }
    
    /// Handle the play : ChannelPlayable or AssetPlayable
    ///
    /// - Parameters:
    ///   - playable: channelPlayable / AssetPlayable
    ///   - asset: asset
    func handlePlay(playable : Playable, asset: Asset?) {
        
        // Use showStickyPlayer to see the sticky player ( ex : Audio / Podcast apps )
        // Fetching asset details is optional. You can directly call `showStickyPlayer`
        // self?.showStickyPlayer(environment: env, session: session, playable: playable, asset: asset)
        // self.getExposureAsset(assetId: playable.assetId, playable: playable)
        
        let _ = self.getExposureAsset(assetId: playable.assetId, playable: playable) { asset in
            
            // Use below implementation to see the detailed Player View
            
            let destinationViewController = PlayerViewController()
            
            destinationViewController.environment = StorageProvider.storedEnvironment
            destinationViewController.sessionToken = StorageProvider.storedSessionToken

            if let asset = asset {
                destinationViewController.newAssetType = asset.type
            }
            
            /// Optional playback properties
            let properties = PlaybackProperties(autoplay: true,
                                                playFrom: .defaultBehaviour)
            
            destinationViewController.playbackProperties = properties
            destinationViewController.playable = playable
            
            self.navigationController?.pushViewController(destinationViewController, animated: false)
        }
        
    }

    
    
    /// Fetch the Asset  details to pass to the player  : Optional
    /// - Parameters:
    ///   - assetId: asset id
    ///   - playable: playable
    private func getExposureAsset(assetId: String, playable: Playable, completion: @escaping (Asset?)->Void) {
        guard let env = StorageProvider.storedEnvironment, let session = StorageProvider.storedSessionToken else {
            return
        }
        
        let query = "fieldSet=ALL&&&onlyPublished=true"
        ExposureApi<Asset>(environment: env, endpoint: "/content/asset/"+assetId, query: query, method: .get, sessionToken: session)
            .request()
            .validate()
            .response{ [weak self] in

                if let asset = $0.value {
                    completion(asset)
                    // self?.showMiniPlayer(environment: env, session: session, playable: playable, asset: asset)
                    
                } else {
                    completion(nil)
                }
                if let error = $0.error {
                    print("Error on fetching Asset " , error)
                    completion(nil)
                }
            }
    }
    
    
    
    /// Sticky Player
    /// - Parameters:
    ///   - environment: env
    ///   - session: session
    ///   - playable: playable
    ///   - asset: asset
    func showStickyPlayer(environment: Environment, session: SessionToken, playable: Playable, asset: Asset) {
        let demoVC = StickyPlayerViewController()
        demoVC.environment = StorageProvider.storedEnvironment
        demoVC.sessionToken = StorageProvider.storedSessionToken
        
        if let player = StickyPlayerViewController.player {
            player.stop()
        }

        demoVC.asset = asset
        
        demoVC.popupItem.title = asset.localized?.first?.title ?? asset.assetId
        demoVC.popupItem.subtitle = asset.localized?.first?.description ?? asset.assetId
        
        demoVC.playable = playable
        
        let playButton = UIBarButtonItem()
        playButton.title = "play"
        playButton.image = UIImage(systemName: "play")

        let stopButton = UIBarButtonItem()
        stopButton.title = "stop"
        stopButton.image = UIImage(systemName: "stop")
        
        
        demoVC.popupItem.leadingBarButtonItems = [playButton]
        demoVC.popupItem.trailingBarButtonItems = [stopButton]
        
        demoVC.view.backgroundColor = .white
        
        // Customise popupBar appearance
        let appearance = LNPopupBarAppearance()
        appearance.backgroundColor = UIColor.clear

        navigationController?.popupBar.inheritsAppearanceFromDockingView = false
        navigationController?.popupBar.backgroundColor = .white
        navigationController?.popupBar.standardAppearance.backgroundColor = UIColor.white
        navigationController?.popupBar.progressViewStyle = .top
        navigationController?.popupBar.progressView.tintColor = .red
        navigationController?.popupBar.standardAppearance = appearance
        
        
        if let urlString = asset.localized?.first?.images?.first?.url, let url = URL(string: urlString) {
            DispatchQueue.global().async { [weak self] in
                if let data = try? Data(contentsOf: url) {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            demoVC.popupItem.image = image
                            demoVC.assetImage = image
                        }
                    }
                }
            }
        }

        navigationController?.presentPopupBar(withContentViewController: demoVC, openPopup:true, animated: true, completion: nil)
    }
    
}

// MARK: Load Assets
extension AssetListTableViewController {
    /// Load the assets from the Exposure API
    ///
    /// - Parameters:
    ///   - query: The optional query to filter by Ex:assetType=TV_CHANNEL
    ///   - environment: Customer specific *Exposure* environment
    ///   - endpoint: Base exposure url. This isStaticCachupAsLiveis the customer specific URL to Exposure
    ///   - method: http method - GET
    fileprivate func loadAssets(query: String, environment: Environment, endpoint: String, method: HTTPMethod) {
        
        ExposureApi<AssetList>(environment: environment,
                               endpoint: endpoint,
                               query: query,
                               method: method)
            .request()
            .validate()
            .response { [weak self] in
                
                if let value = $0.value {
                    self?.assets = value.items ?? []
                    
                    self?.assets.sort(by:{ $0.localized?.first?.title ?? "" < $1.localized?.first?.title ?? "" })
                    
                    self?.refreshTableView()
                }
                
                if let error = $0.error {
                    let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                        (alert: UIAlertAction!) -> Void in
                        self?.refreshTableView()
                    })
                    
                    let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                    self?.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
                }
        }
        
        
        /* let _ = FetchAsset(environment: environment)
         .list()
         .show(page: 1, spanning: 100)
         .filter(onlyPublished: true)
         .use(fieldSet: .all)
         .sort(on: "-created")
         .filter(on:query)
         .request()
         .validate()
         .response { [weak self] in
         guard let `self` = self else { return }
         if let _ = $0.value, let allAssets = $0.value?.items {
         
         self.assets = allAssets
         self.assetsDidLoad(allAssets)
         }
         
         if let error = $0.error {
         let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
         (alert: UIAlertAction!) -> Void in
         self.assetsDidLoad([])
         })
         
         let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
         self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
         }
         } */
        
    }
    
}

// MARK: Load Events
extension AssetListTableViewController {
    /// This is a sample implementation of how to fetch live events from the Exposure `Event` EndPoint
    ///
    /// - Parameter environment: Customer specific *Exposure* environment
    fileprivate func loadEvents(environment: Environment) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        FetchEvent(environment: environment)
            .list(date: formatter.string(from: date) )
            .filter(daysBackward: 2, daysForward: 85)
            .sort(on: "-created")
            .show(page: 1, spanning: 100)
            .request()
            .validate()
            .response { [weak self] in
                
                guard let `self` = self else { return }
                if let _ = $0.value, let allAssets = $0.value?.items {
                    
                    var eventAssets = [Asset]()
                    
                    for event in allAssets {
                        if let asset = event.asset {
                            eventAssets.append(asset)
                        }
                    }
                    
                    self.assets = eventAssets
                    self.refreshTableView()
                    
                }
                
                if let error = $0.error {
                    let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                        (alert: UIAlertAction!) -> Void in
                        self.refreshTableView()
                    })
                    
                    let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                    self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
                }
                
        }
    }
}

