//
//  ContentProposalViewController.swift
//  SDKSampleAppTvOS
//
//  Created by Udaya Sri Senarathne on 2021-12-10.
//

import UIKit
import AVKit

class ContentProposalViewController: AVContentProposalViewController {

    lazy var imageView =  UIImageView()
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var titleLablel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .left
        label.numberOfLines = 5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    lazy var containerView  = UIView()
    
    
    lazy var playNextButton : UIButton = {
        let playNextButton = UIButton()
        playNextButton.titleEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
        playNextButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        playNextButton.addTarget(self, action: #selector(watchNext), for: .primaryActionTriggered)
        return playNextButton
    }()
    
   
    
    override var preferredPlayerViewFrame: CGRect {
        guard let _ = playerViewController?.view.frame else { return CGRect.zero }
        // Present the current video in a 960x540 window centered at the top of the window
        return CGRect(x: 50, y: 50, width: 400, height: 400)
    }

    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [playNextButton]
    }

    /* var viewModel : WLNextContentViewModel? {
        didSet {
            self.appendValues()
        }
    } */
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // print(#function)
        titleLablel.text = ""
        descriptionLabel.text = ""
       //  self.imageView.image = nil
        
        
    }
    
    private func appendValues() {
        
        // Read the AVMetadata for description value or pass this value sepereately through a viewModel or inject it when initialising
        if let items = self.contentProposal?.metadata{
            for item in items {
                print(item)
                if item.identifier == AVMetadataIdentifier.commonIdentifierDescription {
                    descriptionLabel.text = item.stringValue ?? ""
                }
            }
        }
        titleLablel.text = self.contentProposal?.title
        self.imageView = UIImageView(image: self.contentProposal?.previewImage)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        self.appendValues()
    }
    
    @objc func watchNext() {
        dismissContentProposal(for: .accept, animated: true, completion: nil)
    }

    private func setupLayout() {

        self.view.addSubview(containerView)
        
        containerView.addSubview(imageView)
        containerView.addSubview(titleLablel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(playNextButton)
        
        // containerView.frame = CGRect(x: 0, y: 0, width: 500, height: 594)
        containerView.anchor(top: nil, bottom: self.view.bottomAnchor, leading: self.view.leadingAnchor, trailing: self.view.trailingAnchor, padding: .init(top: 50, left: 400, bottom: -50, right: -50))
        containerView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.6).isActive = true
        containerView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.7).isActive = true
       
 
       let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
       let blurEffectView = UIVisualEffectView(effect: blurEffect)
       blurEffectView.frame = view.bounds
       blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // containerView.insertSubview(blurEffectView, at: 0)
        
        imageView.anchor(top: nil, bottom: containerView.bottomAnchor, leading: containerView.leadingAnchor, trailing: titleLablel.leadingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: -100 ))
        imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5).isActive = true
        imageView.contentMode = .scaleAspectFit

        titleLablel.anchor(top: containerView.topAnchor, bottom: titleLablel.topAnchor, leading: imageView.trailingAnchor, trailing: containerView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 100, right: 0))
        //titleLablel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5).isActive = true
        titleLablel.textColor = .white
        
        descriptionLabel.anchor(top: titleLablel.bottomAnchor, bottom: nil, leading: imageView.trailingAnchor, trailing: containerView.trailingAnchor, padding: .init(top: 0, left: 100, bottom: -50, right: 0))
        //descriptionLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5).isActive = true
        descriptionLabel.textColor = .white

        playNextButton.anchor(top: nil, bottom: imageView.bottomAnchor, leading: imageView.trailingAnchor, trailing: containerView.trailingAnchor, padding: .init(top: 0, left: 100, bottom: -120 ,right: 0), size: .init(width: 250, height: 80))
        
        playNextButton.backgroundColor = .red
        let title = "PLAY"
        playNextButton.setTitle(title, for: .normal)
        playNextButton.titleLabel?.textColor = .white
        playNextButton.tintColor = .white

    }
    
    deinit {
        print(#function)
    }
}

