//
//  SelectionTableVIewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2019-05-06.
//  Copyright © 2019 emp. All rights reserved.
//

import Foundation
import UIKit
import iOSClientExposure

class SelectionTableViewController: UITableViewController {
    
    /// "MOVIE", "TV_CHANNEL", "LIVE_EVENTS" : => WILL USE ASSET ENDPOINT WITH FILTER : assetType
    /// "LIVE_EVENTS_USING_EVENT_ENDPOINT" :==> WILL USE EVENT ENDPOINT IN THE EXPOSURE
    enum Sections: String, CaseIterable {
        case movie = "MOVIE"
        case tvShow = "TV_SHOW"
        case episode = "EPISODE"
        case tvChannel = "TV_CHANNEL"
        case liveEvent = "LIVE_EVENT"
        case event = "EVENT"
        case podcast = "PODCAST"
        case downloaded = "DOWNLOADED"
        case externalURL = "EXTERNAL_URL"
    }
    
    let cellIdentifier = "cellIdentifier"
    
    var events = [Asset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Select Asset Type"
        tableView.tableFooterView = UIView()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Sections.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = Sections.allCases[indexPath.row].rawValue
        cell.selectionStyle = .none
        cell.backgroundColor = .white
        cell.textLabel?.textColor = .black
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.navigationController?.navigationItem.title = "\(Sections.allCases[indexPath.row])"
        switch Sections.allCases[indexPath.row] {
        case .downloaded:
            self.navigationController?.pushViewController(DownloadListTableViewController(), animated: false)
        case .externalURL:
            self.navigationController?.pushViewController(URLViewController(), animated: false)
        case .movie, .tvShow, .episode, .tvChannel, .liveEvent, .event, .podcast:
            let assetListTableViewController = AssetListTableViewController()
            assetListTableViewController.selectedAsssetType = Sections.allCases[indexPath.row].rawValue
            self.navigationController?.pushViewController(assetListTableViewController, animated: false)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
