//
//  UIImageView+constraint.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-17.
//

import UIKit

extension UIImageView {
    convenience init(image: UIImage, constrainedByHeight heightConstraint: CGFloat) {
        self.init(image: image)
        let size = image.size
        let aspect = size.width / size.height
        let width = aspect * heightConstraint
        self.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: heightConstraint))
        
        self.widthAnchor.constraint(equalToConstant: width).isActive = true
        self.heightAnchor.constraint(equalToConstant: heightConstraint).isActive = true
    }
}

