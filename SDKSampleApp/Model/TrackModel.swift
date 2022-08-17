//
//  TrackModel.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2020-09-17.
//

import Foundation
import iOSClientPlayer
import iOSClientCast

protocol TrackModel {
    var displayName: String { get }
    var extendedLanguageTag: String? { get }
    var id: Int? { get }
}



extension MediaTrack: TrackModel {
    var displayName: String { return  "\(name) - \(title ?? "")"  }
    var id : Int? { return mediaTrackId }
}



extension iOSClientCast.Track: TrackModel {
    var displayName: String { return label }
    var extendedLanguageTag: String? { return language }
    var id: Int? { return  trackId }
}
