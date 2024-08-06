//
//  LoginViewController.swift
//  SDKSampleAppTvOS
//
//  Created by Udaya Sri Senarathne on 2021-11-24.
//

import Foundation
import UIKit
import TVUIKit
import iOSClientExposure
import iOSClientExposurePlayback

class LoginViewController: UIViewController {
    
    
    var enviornmentUrl: String!
    
    @IBOutlet weak var customerUnitLabel: UITextField!
    @IBOutlet weak var businessUnitLabel: UITextField!
    @IBOutlet weak var usernameLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.addTarget(self, action: #selector(login(_:)), for: .primaryActionTriggered)
        logoutButton.addTarget(self, action: #selector(logOut(_:)), for: .primaryActionTriggered)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        if let _ = StorageProvider.storedEnvironment, let _ = StorageProvider.storedSessionToken {
            // User has an enviornment & session
            self.showHideFields(true)
            
        } else {
            
            // User need to login
            self.showHideFields(false)
            
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    private func showHideFields(_ userhasLoggedIn: Bool ) {
        customerUnitLabel.isHidden = userhasLoggedIn
        businessUnitLabel.isHidden = userhasLoggedIn
        usernameLabel.isHidden = userhasLoggedIn
        passwordLabel.isHidden = userhasLoggedIn
        logoutButton.isHidden = !userhasLoggedIn
        
        if userhasLoggedIn == true {
            loginButton.setTitle("Play", for: .normal)
        } else {
            loginButton.setTitle("Login", for: .normal)
        }
    }
    
    
    @objc func logOut(_ sender: Any) {
        guard let environment = StorageProvider.storedEnvironment, let sessionToken = StorageProvider.storedSessionToken else {
            
            return
        }
        
        Authenticate(environment: environment)
            .logout(sessionToken: sessionToken)
            .request()
            .validate()
            .responseData{ data, error in
                if let error = error {
                    StorageProvider.store(environment: nil)
                    StorageProvider.store(sessionToken: nil)
                 
                    self.showHideFields(false)
                }
                else {
                    StorageProvider.store(environment: nil)
                    StorageProvider.store(sessionToken: nil)
                    
                    self.showHideFields(false)
                }
        }
    }
    
    @objc func login(_ sender: Any) {
        
        
        if let environment = StorageProvider.storedEnvironment, let sessionToken = StorageProvider.storedSessionToken {
            self.playAnyAsset(environment: environment, sessionToken: sessionToken)
        } else {
            
            // Dummy values
            customerUnitLabel.text = ""
            businessUnitLabel.text = ""
            
            usernameLabel.text = ""
            passwordLabel.text = ""
            
            
            if let customer = customerUnitLabel.text, let businessUnit = businessUnitLabel.text, let username = usernameLabel.text , let password = passwordLabel.text {
                
                let environment = Environment(baseUrl: enviornmentUrl, customer: customer, businessUnit: businessUnit)
  
                Authenticate(environment: environment)
                    .login(username: username, password: password)
                    .request()
                    .validate()
                    .response{ [weak self] in
                        if let error = $0.error {
                           print("Error " , error )
                        }
                        
                        if let credentials = $0.value {
                            StorageProvider.store(environment: environment)
                            StorageProvider.store(sessionToken: credentials.sessionToken)
       
                            self?.playAnyAsset(environment: environment, sessionToken: credentials.sessionToken)

                        }
                }
            }
        }

    }
    
    private func playAnyAsset(environment: Environment, sessionToken: SessionToken) {
        let playerVC = PlayerViewController()
        
        playerVC.environment = environment
        playerVC.sessionToken = sessionToken
        
        let assetId = ""
        
        playerVC.playerAssetDataSource = PlayerAssetDataSource(environment: environment, sessionToken: sessionToken)

        playerVC.playerAssetDataSource.assetId = assetId
        let playable = AssetPlayable(assetId:assetId)
        playerVC.playable = playable
        
        // fetching asset details 
        playerVC.playerAssetDataSource.onDataUpdated = { viewModel in
            playerVC.assetViewModel = viewModel
            
            // When using white labeled Asset End point, you should get pushNextCuePoint value
            // Pass pushNextCuePoint value
            playerVC.pushNextCuePoint = 10000 // dummy value : 10s
            
            DispatchQueue.main.async {
                self.present(playerVC, animated: false) {
                    playerVC.startPlayback()
                }
            }
        }
        
        playerVC.playerAssetDataSource.onErrorUpdating = { error in
            
            DispatchQueue.main.async {
                self.present(playerVC, animated: false) {
                    
                    // When using white labeled Asset End point, you should get pushNextCuePoint value
                    // Pass pushNextCuePoint value
                    playerVC.pushNextCuePoint = 0

                    self.present(playerVC, animated: false) {
                        playerVC.startPlayback()
                    }
                }
            }
        }
        
        
    }
    
    
}
