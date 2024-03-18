//
//  EPGListViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2019-05-06.
//  Copyright © 2019 emp. All rights reserved.
//

import Foundation
import UIKit
import iOSClientExposure
import iOSClientExposurePlayback


class EPGListViewController: UITableViewController  {
    
    var startDate: Date?
    var endDate: Date?
    var dateRangeSelectorButton: UIBarButtonItem!
    
    var programs = [Program]()
    var channel: Asset!
    let cellIdentifier = "cellIdentifier"
    
    var assetPageNumber: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateRangeSelectorButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(openDateRangeSelector))
        
        self.title = "\(channel.localized?.first?.title ?? "") - EPG"
        self.tableView.register(AssetListCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.white
        
        let next = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(loadNextPageAssets))
        let previous = UIBarButtonItem(title: "Previous", style: .plain, target: self, action: #selector(loadPreviousPageAssets))
        
        navigationItem.rightBarButtonItems = [next, previous, dateRangeSelectorButton]
        
        didSelectDateRange(startDate: Date(), endDate: Date())
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.programs.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AssetListCell else { return UITableViewCell() }
        
        let program = self.programs[indexPath.row]
        let current = Date()
        
        if let start = program.startDate, let _ = program.endDate {
            if start > current {
                
                cell.isUserInteractionEnabled = false
                cell.backgroundColor = UIColor.white
                cell.textLabel?.textColor = UIColor.red
                cell.tintColor = UIColor.blue
                
                
            } else {
                cell.isUserInteractionEnabled = true
                cell.backgroundColor = UIColor.white
                cell.textLabel?.textColor = UIColor.black
                cell.tintColor = UIColor.yellow
            }
        }
        cell.selectionStyle = .none
        guard let asset = program.asset else { return UITableViewCell() }
        cell.setupValues(asset, programStartTime: program.startDate , programEndTime: program.endDate)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let program = self.programs[indexPath.row]
        let current = Date()
        if let start = program.startDate, let _ = program.endDate {
            if start <= current {
                self.showOptions(program: program, channel: channel)
            }
        }
        
        
    }
}

extension EPGListViewController {
    
    
    /// Show options: Play Using ProgramPlayable or AssetPlayable
    ///
    /// - Parameters:
    ///   - program: program
    ///   - channel: channel
    fileprivate func showOptions(program: Program, channel: Asset) {
        
        let message = "Choose option"
        
        let playProgramPlayable = UIAlertAction(title: "Play Program Using Program Playable - Test Only", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let playable = ProgramPlayable(assetId: program.programId, channelId: channel.assetId)
            self.handleProgramPlay(playable: playable, asset: channel)
            
        })
        
        let playAssetPlayable = UIAlertAction(title: "Play Program Using Asset Playable", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let playable = AssetPlayable(assetId: program.assetId)
            self.handleProgramPlay(playable: playable, asset: channel)
        })
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        self.popupAlert(title: nil, message: message, actions: [playAssetPlayable ,playProgramPlayable, cancelAction], preferedStyle: .actionSheet)
    }
    
    func handleProgramPlay(playable : Playable, asset: Asset) {
        let destinationViewController = PlayerViewController()
        destinationViewController.environment = StorageProvider.storedEnvironment
        destinationViewController.sessionToken = StorageProvider.storedSessionToken
        destinationViewController.channel = asset
        
        /// Optional playback properties
        let properties = PlaybackProperties(autoplay: true,
                                            playFrom: .defaultBehaviour,
                                            language: .custom(text: "fr", audio: "en"),
                                            maxBitrate: 300000)
        
        destinationViewController.playbackProperties = properties
        destinationViewController.playable = playable
        
        self.navigationController?.pushViewController(destinationViewController, animated: false)
    }
}

// MARK: - DataSource
extension EPGListViewController {
    
    @objc fileprivate func loadNextPageAssets() {
        if assetPageNumber >= 1 {
            self.assetPageNumber = assetPageNumber + 1

            self.generateTableViewContent()
        }
    }
    
    @objc fileprivate func loadPreviousPageAssets() {
        if assetPageNumber > 1 {
            self.assetPageNumber = assetPageNumber - 1
            self.generateTableViewContent()
        }
    }
    
    /// Generate tableview content by loading assets from API
    fileprivate func generateTableViewContent() {
        guard let environment = StorageProvider.storedEnvironment, let sessionToken = StorageProvider.storedSessionToken else {
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                
            })
            
            let message = "Invalid Session Token, please login again"
            self.popupAlert(title: "Error" , message: message, actions: [okAction], preferedStyle: .alert)
            return
        }
        
        
        let date = Date()
        let start = (date.subtract(days: 1) ?? date).millisecondsSince1970
        let end = (date.add(hours: 4) ?? date).millisecondsSince1970
        
        fetchEpg(for: channel, from: startDate, to: endDate, environment: environment, sessionToken: sessionToken) { [weak self] epg, error in
            guard let `self` = self else { return }
            
            if let error = error {
                let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                })
                let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
            }
            
            self.programs = epg?.programs ?? []
            self.tableView.reloadData()
        }
        
    }
    
    
    /// Fetch EPG
    ///
    /// - Parameters:
    ///   - channel: channel
    ///   - start: start date
    ///   - end: end date
    ///   - environment: environment
    ///   - sessionToken: session token
    ///   - callback: callback
    fileprivate func fetchEpg(
        for channel: Asset,
        from start: Date? = nil,
        to end: Date? = nil,
        environment: Environment,
        sessionToken: SessionToken,
        callback: @escaping (ChannelEpg?, ExposureError?) -> Void
    ) {
        // Fetch Epg
        FetchEpg(environment: environment, version: .v2)
            .channel(id: channel.assetId)
            .filter(startDate: self.startDate ?? Date(), endDate: self.endDate ?? Date())
            .filter(onlyPublished: true)
            .show(page: assetPageNumber, spanning: 50)
            .request()
            .validate()
            .response{
                callback($0.value,$0.error)
            }
    }
}

// MARK: Date Range Selection
extension EPGListViewController: DateRangeSelectorDelegate {
    
    @objc func openDateRangeSelector() {
        let dateRangeSelectorViewController = DateRangeSelectorViewController()
        dateRangeSelectorViewController.delegate = self
        dateRangeSelectorViewController.startDate = self.startDate
        dateRangeSelectorViewController.endDate = self.endDate
        let navigationController = UINavigationController(rootViewController: dateRangeSelectorViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    func didSelectDateRange(startDate: Date, endDate: Date) {
        
        self.startDate = startDate
        self.endDate = endDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        dateRangeSelectorButton.title = "\(startDateString) - \(endDateString)"
        self.generateTableViewContent()
    }
}
