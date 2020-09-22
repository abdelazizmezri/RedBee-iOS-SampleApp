//
//  UIViewController+Extension.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-21.
//

import Foundation
import UIKit
import GoogleCast


extension UIViewController {
    func showChromecastButton() {
        let button = GCKUICastButton(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(24), height: CGFloat(24)))
        button.sizeToFit()
        button.tintColor = .white
        var navItems = navigationItem.rightBarButtonItems ?? []
        navItems.append(UIBarButtonItem(customView: button))
        navigationItem.rightBarButtonItems = navItems
    }
}
