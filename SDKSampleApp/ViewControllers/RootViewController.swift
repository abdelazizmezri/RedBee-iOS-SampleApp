//
//  RootViewController.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-22.
//

import Foundation
import GoogleCast
import iOSClientExposure

let kCastControlBarsAnimationDuration: TimeInterval = 0.20

class RootViewController: UIViewController, GCKUIMiniMediaControlsViewControllerDelegate, GCKSessionManagerListener, GCKRequestDelegate {
    
    var _miniMediaControlsContainerView = UIView()
    var sessionManager: GCKSessionManager!
    var _miniMediaControlsHeightConstraint: NSLayoutConstraint = NSLayoutConstraint()
    
    private var miniMediaControlsViewController: GCKUIMiniMediaControlsViewController!
    var miniMediaControlsViewEnabled = false {
        didSet {
            if isViewLoaded {
                updateControlBarsVisibility()
            }
        }
    }
    
    var overridenNavigationController: UINavigationController?
    override var navigationController: UINavigationController? {
        get {
            return overridenNavigationController
        }
        set {
            overridenNavigationController = newValue
        }
    }
    
    var miniMediaControlsItemEnabled = false
    
    override func loadView() {
        super.loadView()
        
        addLogoutBarButtonItem()
        
        _miniMediaControlsHeightConstraint.constant = 75
        _miniMediaControlsHeightConstraint.priority = UILayoutPriority(rawValue: 1000)
        
        view.addSubview(_miniMediaControlsContainerView)
        _miniMediaControlsContainerView = UIView(frame: CGRect(x: 0, y: self.view.frame.height - 70 - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 70), width: self.view.frame.width, height: 70))
        _miniMediaControlsContainerView.addConstraint(_miniMediaControlsHeightConstraint)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sessionManager = GCKCastContext.sharedInstance().sessionManager
        sessionManager.add(self)
        
        let castContext = GCKCastContext.sharedInstance()
        miniMediaControlsViewController = castContext.createMiniMediaControlsViewController()
        miniMediaControlsViewController.delegate = self
        updateControlBarsVisibility()
        installViewController(miniMediaControlsViewController,
                              inContainerView: _miniMediaControlsContainerView)
        
        installViewController(miniMediaControlsViewController, inContainerView: _miniMediaControlsContainerView)
        
        let selectionlistViewController = SelectionTableViewController()
        
        self.add(asChildViewController: selectionlistViewController)

    }
    
    
    func installViewController(_ viewController: UIViewController?, inContainerView containerView: UIView) {
        if let viewController = viewController {
            addChild(viewController)
            viewController.view.frame = containerView.bounds
            containerView.addSubview(viewController.view)
            viewController.didMove(toParent: self)
        }
    }
    
    func uninstallViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    func updateControlBarsVisibility() {
        
        if miniMediaControlsViewEnabled, miniMediaControlsViewController.active {
            _miniMediaControlsHeightConstraint.constant = miniMediaControlsViewController.minHeight
            view.bringSubviewToFront(_miniMediaControlsContainerView)
        } else {
            _miniMediaControlsHeightConstraint.constant = 0
        }
        UIView.animate(withDuration: kCastControlBarsAnimationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        view.setNeedsLayout()
    }
    
    
    private func add(asChildViewController viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    func miniMediaControlsViewController(_ miniMediaControlsViewController: GCKUIMiniMediaControlsViewController, shouldAppear: Bool) {

        debugPrint(" miniMediaControlsViewController ")
        
        updateControlBarsVisibility()
        
    }
    
    
    
    /// Mini Controller
    func miniControllerDidTransitFromtheSuperView( ) {
        
        print(" Google cast mini controller has transit from the super view ")
        
        print(" Super view did disapper from the stack ")
        
        
    }
    
}

extension RootViewController {
    /// Add left bar button item
    fileprivate func addLogoutBarButtonItem() {
        let button = UIButton()
        button.addTarget(self, action:#selector(handleLogout), for: .touchUpInside)
        button.setTitle(NSLocalizedString("Logout", comment: ""), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.sizeToFit()
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    
    /// User confirmation for logout
    @objc fileprivate func handleLogout() {
        let title = NSLocalizedString("Log out", comment: "")
        let message = NSLocalizedString("Do you want to log out from the application ?", comment: "")
        
        let logOutAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.logoutUser()
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })
        
        self.popupAlert(title: title, message: message, actions: [logOutAction, cancelAction])
    }
    
    /// Log out the user from the application
    func logoutUser() {
        
        guard let environment = StorageProvider.storedEnvironment, let sessionToken = StorageProvider.storedSessionToken else {
            
            let navigationController = MainNavigationController()
            let castContainerVC = GCKCastContext.sharedInstance().createCastContainerController(for: navigationController)
              as GCKUICastContainerViewController
            castContainerVC.miniMediaControlsItemEnabled = true
            UIApplication.shared.keyWindow?.rootViewController = castContainerVC
            return
        }
        
        Authenticate(environment: environment)
            .logout(sessionToken: sessionToken)
            .request()
            .validate()
            .responseData{ data, error in
                if let error = error {
                    let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                        (alert: UIAlertAction!) -> Void in
                        
                        StorageProvider.store(environment: nil)
                        StorageProvider.store(sessionToken: nil)
                        
                        let navigationController = MainNavigationController()
                        let castContainerVC = GCKCastContext.sharedInstance().createCastContainerController(for: navigationController)
                          as GCKUICastContainerViewController
                        castContainerVC.miniMediaControlsItemEnabled = true
                        UIApplication.shared.keyWindow?.rootViewController = castContainerVC
                    })
                    
                    let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                    self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
                }
                else {
                    StorageProvider.store(environment: nil)
                    StorageProvider.store(sessionToken: nil)
                    
                    let navigationController = MainNavigationController()
                    let castContainerVC = GCKCastContext.sharedInstance().createCastContainerController(for: navigationController)
                      as GCKUICastContainerViewController
                    castContainerVC.miniMediaControlsItemEnabled = true
                    UIApplication.shared.keyWindow?.rootViewController = castContainerVC
                }
        }
    }
    
}
