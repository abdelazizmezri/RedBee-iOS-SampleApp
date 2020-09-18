//
//  AppDelegate.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-17.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow()
        let rootViewController = MainNavigationController()
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        return true
    }

}

