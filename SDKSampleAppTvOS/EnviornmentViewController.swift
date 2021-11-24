//
//  EnviornmentViewController.swift
//  SDKSampleAppTvOS
//
//  Created by Udaya Sri Senarathne on 2021-11-24.
//

import Foundation
import UIKit
import TVUIKit

class EnviornmentViewController: UIViewController {
    
    @IBOutlet weak var loginToPrestageBtn: UIButton!
    @IBOutlet weak var loginToProductionBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loginToPrestageBtn.addTarget(self, action: #selector(loginToPrestage(_:)), for: .primaryActionTriggered)
        loginToProductionBtn.addTarget(self, action: #selector(loginToProduction(_:)), for: .primaryActionTriggered)
        
        
    }
    
    @objc func loginToPrestage(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginVC") as? LoginViewController {
            
            // Add your prestage url
            loginViewController.enviornmentUrl = ""
            self.present(loginViewController, animated: true, completion: nil)
        }
        
        
    }
    
    
    @objc func loginToProduction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginVC") as? LoginViewController {
            
            // Add your production url
            loginViewController.enviornmentUrl = ""
            self.present(loginViewController, animated: true, completion: nil)
        }
        
        
    }
    
}
