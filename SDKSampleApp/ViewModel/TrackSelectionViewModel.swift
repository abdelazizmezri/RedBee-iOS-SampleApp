//
//  TrackSelectionViewModel.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-17.
//

import Foundation

class TrackSelectionViewModel: Equatable {
    let model: TrackModel?
    
    init(model: TrackModel?) {
        self.model = model
    }
    
    var displayName: String {
        return model?.displayName ?? "Off"
    }
    
    public static func == (lhs: TrackSelectionViewModel, rhs: TrackSelectionViewModel) -> Bool {
        return lhs.model?.extendedLanguageTag == rhs.model?.extendedLanguageTag
    }
}
