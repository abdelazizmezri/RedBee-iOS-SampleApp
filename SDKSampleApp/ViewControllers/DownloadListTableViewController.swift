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
import SwiftUI

class DownloadListTableViewController: UITableViewController, EnigmaDownloadManager {
    
    var downloadedAssets: [OfflineMediaAsset]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Downloads"
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
        // downloadedAssets = enigmaDownloadManager.getDownloadedAssets()
        
        downloadedAssets = enigmaDownloadManager.getDownloadedAssets(userId: session.userId)
        
        // downloadedAssets = enigmaDownloadManager.getDownloadedAssets(accountId: session.accountId )
        
        // This will fetch all the downloaded media related to the current user from the exposure backend
        /* GetAllDownloads(environment: environment, sessionToken: session )
         .request()
         .validate()
         .response { result in
         
         // Handle your response here
         if let value = result.value, let allDownloads = value as? AllDownloads, let assets = allDownloads.assets {
         for abc in assets {
         if let downloads = abc.downloads {
         for download in downloads {
         print(" user id " , download.userId )
         }
         }
         }
         }
         } */
        
        
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
            
            /*
             
             // Check if a downloaded asset has expired or not
             // Get an expiry time of a downloaded asset
             
             */
            
            /* if let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment {
             
                // Check if a download has expired
                let _ = self.enigmaDownloadManager.isExpired(assetId: asset.assetId, environment: environment, sessionToken: session) { [weak self] expired, error in
                    print("IS EXPIRED " , expired)
                }
                
                let _ = self.enigmaDownloadManager.getExpiryTime(assetId: asset.assetId, environment: environment, sessionToken: session) { [weak self] expiryTime, error  in
                    
                    print(" Expiry Time " , expiryTime )
                    
                }
            } */
            
        }
        return cell
    }
    
    func showOptions(_ row:Int ) {
        
        if let asset = self.downloadedAssets?[row] {
            
            let downloadState = asset.getDownloadState()

            switch  downloadState {
            case .cancel:
                print(" Download was canceled , delete ? ")
                showDeleteOption(row)
            case .completed:
                showDownloadCompleteOptions(row)
            case .notDownloaded:
                print(" Asset has not downloaded / Should not appear in this list . Must clean up this record if available in the local records")
            case .started:
                print(" Download has started but never completed. Resume perhaps ? ")
                self.showDeleteOption(row)
            case .suspend:
                print("Download was suspended , resume ? ")
                self.showDeleteOption(row)
            case .downloading:
                    let _ = asset.state { playableState in
                    switch playableState {
                    case .completed(entitlement: let entitlement, url: let url):
                       print(" Playable ")
                    case .notPlayable(entitlement: let entitlement, url: _):
                        print(" Not playable ")
                    }
                }
            case .none:
                print(" Asset has not downloaded / Should not appear in this list . Must clean up this record if available in the local records")
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
                
                let _ = self.enigmaDownloadManager.renewLicense(assetId: asset.assetId, sessionToken: session, environment: environment) { [weak self ] offlineMediaAsset, error in
                    print(" OfflineMedia Asset  " , offlineMediaAsset )
                    print(" Error " , error )
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
                
                
                if let entitlement = downloadedAsset?.entitlement, let urlAsset = urlAsset, let format = downloadedAsset?.format {
                    
                    
                    if format == "MP3" || format == "mp3" {
                        
                        // Navigate to audio only player
                        
                        let destinationViewController = AudioPlayerViewController()
                        destinationViewController.fileUrl = urlAsset.url
                        self.navigationController?.pushViewController(destinationViewController, animated: false)
                        
                        // Play with AudioEngine
                        // let destinationViewController = AudioPlayerWithAVAudioEngine()
                        // destinationViewController.fileUrl = urlAsset.url
                        // self.navigationController?.pushViewController(destinationViewController, animated: false)
                        
                        
                    } else {
                        let destinationViewController = PlayerViewController()
                        destinationViewController.environment = StorageProvider.storedEnvironment
                        destinationViewController.sessionToken = StorageProvider.storedSessionToken
                        
                        // Optional : remeber previously selected audios & subs
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
                                                            playFrom: .bookmark)
                        
                        
                        destinationViewController.playbackProperties = properties
                        destinationViewController.offlineMediaPlayable = OfflineMediaPlayable(assetId: asset.assetId, entitlement: entitlement, url: urlAsset.url)
                        
                        self.navigationController?.pushViewController(destinationViewController, animated: false)
                    }
                    
                    
                }
            }
            
            
        })
        
        self.popupAlert(title: nil, message: message, actions: [playOffline, refreshAction, deletelAction, cancelAction], preferedStyle: .actionSheet)
    }
}
