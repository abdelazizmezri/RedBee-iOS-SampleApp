//
//  TrackModel.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-17.
//

import Foundation
import Player
import Cast

protocol TrackModel {
    var displayName: String { get }
    var extendedLanguageTag: String? { get }
}



extension MediaTrack: TrackModel {
    var displayName: String { return name }
}

extension Cast.Track: TrackModel {
    var displayName: String { return label }
    var extendedLanguageTag: String? { return language }
}
