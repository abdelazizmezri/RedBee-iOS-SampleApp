//
//  PlayerAssetDataSource.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2021-12-10.
//

import Foundation

import iOSClientExposure

public protocol PlayerAssetDataSourceProtocol {
    var onDataUpdated: (AssetViewModel?) -> Void { get set }
    var onErrorUpdating: (ExposureError) -> Void { get set }
    var data: (AssetViewModel?) { get }
}


/// Handles Fetching Asset from Exposure for player : This will fetch Asset & pass to the player before start playing the content
public class PlayerAssetDataSource: PlayerAssetDataSourceProtocol {
    public var data: (AssetViewModel?)
    public var onDataUpdated: (AssetViewModel?) -> Void = { _ in }
    public var onErrorUpdating: (ExposureError) -> Void = { _ in }
    
    public var environment: Environment
    public var sessionToken: SessionToken
    
    public var assetId: String? {
        didSet {
            self.getExposureAsset()
        }
    }
    
    public init(environment: Environment , sessionToken: SessionToken) {
        self.environment = environment
        self.sessionToken = sessionToken
    }
    
    
    public func getExposureAsset() {
        guard let assetId = self.assetId else {
            onDataUpdated(nil)
            data = nil
            return
        }
        
        let query = "fieldSet=ALL&&&onlyPublished=true"
        ExposureApi<Asset>(environment: self.environment, endpoint: "/content/asset/"+assetId, query: query, method: .get, sessionToken: self.sessionToken)
            .request()
            .validate()
            .response{ [weak self] in
                
                if let asset = $0.value {
                    let viewModel = AssetViewModel(asset: asset)
                    self?.data = viewModel
                    self?.onDataUpdated(viewModel)
                }
                if let error = $0.error {
                    self?.data = nil
                    self?.onErrorUpdating(error)
                    
                }
            }
    }
}


