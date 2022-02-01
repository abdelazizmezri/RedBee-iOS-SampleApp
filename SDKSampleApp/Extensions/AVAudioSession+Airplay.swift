//
//  AVAudioSession+Airplay.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2022-01-25.
//

import AVFoundation

extension AVAudioSession {
    var hasActiveAirplayRoute: Bool {
        return currentRoute.outputs.reduce(false) { $0 || $1.portType == AVAudioSession.Port.airPlay }
    }
}
