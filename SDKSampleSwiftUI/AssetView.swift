//
//  AssetView.swift
//  SDKSampleSwiftUI
//
//  Created by Udaya Sri Senarathne on 2022-01-11.
//

import SwiftUI
import ExposurePlayback

struct AssetView: View {
    
    // add the `assetId`
    @State var assetId: String = ""
    
    @State var shouldStartPlay: Bool = false
    
    var body: some View {
        
        VStack {
            
            let playable = AssetPlayable(assetId: assetId)
            NavigationLink(destination: CustomVideoPlayer(playable: playable), isActive: $shouldStartPlay) { EmptyView() }
            
            Text("Add your assetId")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.bottom, 20)
            
            TextField("Asset Id", text: $assetId)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            Button(action: play){
                Text("Play")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 220, height: 60)
                    .background(Color.green)
                    .cornerRadius(15.0)
            }
        }
    }
    
    fileprivate func play() {
        shouldStartPlay = true
    }
}

