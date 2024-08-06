//
//  AssetListCell.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2023-10-12.
//

import Foundation
import UIKit
import iOSClientExposure
import iOSClientExposurePlayback
import iOSClientExposureDownload


class AssetListCell: UITableViewCell {
    
    var startTime: NSNumber?
    
    let titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let assetPosterImage: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private var task: URLSessionDataTask?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.clear
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        assetPosterImage.image = nil
    }
    
    
    func setupValues( _ asset: Asset , programStartTime: Date? = nil , programEndTime: Date? = nil ) {
        
        self.titleLabel.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 20)
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.textAlignment = .left
        self.titleLabel.adjustsFontSizeToFitWidth = false
        self.titleLabel.text = asset.localized?.first?.title ?? asset.assetId
        
        
        self.descriptionLabel.font = UIFont(name: "AppleSDGothicNeo-light", size: 15)
        self.descriptionLabel.textColor = UIColor.black
        self.descriptionLabel.textAlignment = .left
        self.descriptionLabel.adjustsFontSizeToFitWidth = false
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "hh:mm:ss - dd MMM"
        
        if let programStartTime = programStartTime , let programEndTime = programEndTime {
            
            if programStartTime > programEndTime {
                self.titleLabel.textColor = UIColor.red
                self.descriptionLabel.textColor = UIColor.red
                
            } else {
                self.titleLabel.textColor = UIColor.black
                self.descriptionLabel.textColor = UIColor.black
            }
            
            self.descriptionLabel.text = "\(dateFormater.string(from: programStartTime)) - \(dateFormater.string(from: programEndTime))"
        } else {
            self.descriptionLabel.text = asset.assetId
        }
        
        
        
        guard let imageUrl = asset.localized?.first?.images?.first?.url, let url = URL(string: imageUrl) else { return }
        
        self.assetPosterImage.image = nil
        self.assetPosterImage.contentMode = .scaleAspectFit
        
        task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.assetPosterImage.image = image
                }
            }
        }
        task?.resume()
        
    }
    
    fileprivate func setupLayout() {
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(assetPosterImage)
        
        // Main View
        contentView.anchor(top: self.topAnchor, bottom: self.bottomAnchor, leading: self.leadingAnchor, trailing: self.trailingAnchor)
        
        titleLabel.anchor(top: contentView.topAnchor, bottom: nil, leading: contentView.leadingAnchor, trailing: nil, padding: .init(top: 10, left: 10, bottom: 0, right: -10))
        titleLabel.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        descriptionLabel.anchor(top: titleLabel.bottomAnchor, bottom: nil, leading: contentView.leadingAnchor, trailing: nil, padding: .init(top: 0, left: 10, bottom: 10, right: -10))
        descriptionLabel.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        assetPosterImage.anchor(top: contentView.topAnchor, bottom: nil, leading: nil, trailing: contentView.trailingAnchor, padding: .init(top: 10, left: 10, bottom: 0, right: -10))
        assetPosterImage.widthAnchor.constraint(equalToConstant: 60).isActive = true
        assetPosterImage.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        
    }
}
