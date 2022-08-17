//
//  DownloadListTableViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2020-05-25.
//  Copyright © 2020 emp. All rights reserved.
//

import UIKit
import iOSClientExposureDownload
import iOSClientExposure
import iOSClientExposurePlayback

class DownloadListTableViewController: UITableViewController, EnigmaDownloadManager {
    
    var downloadedAssets: [OfflineMediaAsset]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .white
        
        self.refreshTableView()
        
    }
    
    func refreshTableView() {
        guard let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment else {
          print("No Session token or enviornment provided ")
          return
        }
        
        
        // If you want to fetch all the downloaded Media , regardless of the user you can use `enigmaDownloadManager.getDownloadedAssets()`
        
        // This will fetch all the downloaded media related to the current user
        downloadedAssets = enigmaDownloadManager.getDownloadedAssets()
        
        // downloadedAssets = enigmaDownloadManager.getDownloadedAssets(accountId: session.accountId )
        
        // This will fetch all the downloaded media related to the current user from the exposure backend
        GetAllDownloads(environment: environment, sessionToken: session )
        .request()
        .validate()
        .response { _ in
            
            // Handle your response here
        }
        
        
        tableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if downloadedAssets?.count == 0 {
            tableView.showEmptyMessage(message: NSLocalizedString("No downloaded content", comment: ""))
        } else {
            tableView.hideEmptyMessage()
        }
        return downloadedAssets?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.showOptions(indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            
            cell.selectionStyle = .none
            cell.backgroundColor = .white
            cell.textLabel?.textColor = .black
            cell.detailTextLabel?.textColor = .black
            
            if let asset = downloadedAssets?[indexPath.row] {
                
            cell.textLabel?.text = asset.assetId
            cell.detailTextLabel?.text = asset.downloadState.rawValue // show download state of the offline media record
            
            // Check if a download has expired
            let expired = self.enigmaDownloadManager.isExpired(assetId: asset.assetId)
            if expired {
                print("Download has expired")
            }
        }
        return cell
    }
    
    func showOptions(_ row:Int ) {
        
        if let asset = self.downloadedAssets?[row] {
            switch  asset.downloadState {
            case .cancel:
                print(" Download was canceled , delete ? ")
                showDeleteOption(row)
            case .completed:
                print(" Download was completed " )
                showDownloadCompleteOptions(row)
            case .notDownloaded:
                print(" Asset has not downloaded / Should not appear in this list . Must clean up this record if available in the local records")
            case .started:
                print(" Download has started but never completed. Resume perhaps ? ")
                self.showDeleteOption(row)
            case .suspend:
                print("Download was suspended , resume ? ")
                self.showDeleteOption(row)
            }
        }
    }
    
    func showDeleteOption(_ row:Int) {
        let message = "Choose option"
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        let deletelAction = UIAlertAction(title: "Delete", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            if let asset = self.downloadedAssets?[row] {
                
                guard let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment else {
                    print("No Session token or enviornment provided ")
                    return
                }
                
                // Developers can use ExposureDownloadTask removeDownloadedAsset option to delete an already downloaded asset
                self.enigmaDownloadManager.removeDownloadedAsset(assetId: asset.assetId, sessionToken:session, environment: environment )
                self.refreshTableView()
            }
        })
        self.popupAlert(title: nil, message: message, actions: [ deletelAction, cancelAction], preferedStyle: .actionSheet)
    }
    
    
    /// Show options when the asset has completly downloaded
    /// - Parameter row: row
    func showDownloadCompleteOptions(_ row:Int) {
        let message = "Choose option"
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        let deletelAction = UIAlertAction(title: "Delete", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            if let asset = self.downloadedAssets?[row] {
                
                guard let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment else {
                    print("No Session token or enviornment provided ")
                    return
                }
                
                // Developers can use ExposureDownloadTask removeDownloadedAsset option to delete an already downloaded asset
                self.enigmaDownloadManager.removeDownloadedAsset(assetId: asset.assetId, sessionToken:session, environment: environment )
                self.refreshTableView()
            }
        })
        
        let refreshAction = UIAlertAction(title: "Refresh Liscence", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            guard let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment else {
                print("No Session token or enviornment providec ")
                return
            }
            
            if let asset = self.downloadedAssets?[row] {
                
                // Developers can use the same download task to refresh the licence if it has expired.
                let task = self.enigmaDownloadManager.download(assetId: asset.assetId, using: session, in: environment)
                task.renewLicence()
                task.onError {_, url, error in
                    print("📱 RefreshLicence Task failed with an error: \(error)",url ?? "")
                }
                .onLicenceRenewed { _, url in
                    print("📱 RefreshLicence Task completed: \(url)")
                }
            }
        })
        
        let playOffline = UIAlertAction(title: "Play Offline", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            if let asset = self.downloadedAssets?[row] {
                
                // Developers can check if an asset is already downloaded by passing an assetId.
                // If the asset is already downloaded, API will return OfflineMediaAsset which has assetId, entitlement, urlAsset etc.
                let downloadedAsset = self.enigmaDownloadManager.getDownloadedAsset(assetId: asset.assetId)
                let urlAsset = downloadedAsset?.urlAsset
                
                if let entitlement = downloadedAsset?.entitlement, let urlAsset = urlAsset {
                    

                    let destinationViewController = PlayerViewController()
                    destinationViewController.environment = StorageProvider.storedEnvironment
                    destinationViewController.sessionToken = StorageProvider.storedSessionToken
                    
                    
                    // Optional remeber previously selected audios & subs 
                    var sub = ""
                    var audio = ""
                    
                    let defaults = UserDefaults.standard
                    if let selectedSubtitleTrack = defaults.object(forKey: "selectedSubtitleTrack") as? String {
                        sub = selectedSubtitleTrack
                    }
                    
                    if let selectedAudioTrack = defaults.object(forKey: "selectedAudioTrack") as? String {
                        audio = selectedAudioTrack
                    }
                    
                    /// Optional playback properties
                    let properties = PlaybackProperties(autoplay: true,
                                                        playFrom: .beginning ,
                                                        language: .custom(text: sub, audio: audio))
                    
                    
                    destinationViewController.playbackProperties = properties
                    destinationViewController.offlineMediaPlayable = OfflineMediaPlayable(assetId: asset.assetId, entitlement: entitlement, url: urlAsset.url)
                    
                    self.navigationController?.pushViewController(destinationViewController, animated: false)
                    
                }
            }
            
            
        })
        
        self.popupAlert(title: nil, message: message, actions: [playOffline, refreshAction, deletelAction, cancelAction], preferedStyle: .actionSheet)
    }
}
