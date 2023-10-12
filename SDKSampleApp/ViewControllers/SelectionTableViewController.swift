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
    var sections = ["MOVIE","TV_SHOW","EPISODE","TV_CHANNEL","LIVE_EVENT","EVENT","PODCAST","DOWNLOADED", ]
    
    
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
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = sections[indexPath.row]
        cell.selectionStyle = .none
        cell.backgroundColor = .white
        cell.textLabel?.textColor = .black
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.row] == "DOWNLOADED"{
            let destinationViewController = DownloadListTableViewController()
            
            self.navigationController?.navigationItem.title = "Downloads"
            
            self.navigationController?.pushViewController(destinationViewController, animated: false)
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            let destinationViewController = AssetListTableViewController()
            destinationViewController.selectedAsssetType = sections[indexPath.row]
            
            destinationViewController.title = "\(sections[indexPath.row])"
            self.navigationController?.navigationItem.title = "\(sections[indexPath.row])"
            
            self.navigationController?.pushViewController(destinationViewController, animated: false)
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
}
