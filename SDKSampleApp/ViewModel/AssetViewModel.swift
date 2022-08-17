//
//  AssetViewModel.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2021-12-10.
//

import Foundation
import iOSClientExposure


public struct AssetViewModel {
    
    public let asset: Asset
    
    /// Pass all marker points / player cuepoints if available
    public var cuePoints: [MarkerPoint]? {
        return asset.markerPoints
    }
    
    public var title: String? {
        // Note : Use tranlsated titles in your implementation
        return asset.localized?.first?.title
    }
    
    public var description: String? {
        // Note : Use tranlsated titles in your implementation
        return asset.localized?.first?.description
    }
    
    public var image: Image? {
        // Note : Use tranlsated titles in your implementation
        return asset.localized?.first?.images?.first
    }
    
    public init(asset: Asset) {
        self.asset = asset
    }
    
}
