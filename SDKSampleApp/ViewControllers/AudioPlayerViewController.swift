//
//  AudioPlayerViewController.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2022-12-09.
//

import Foundation
import AVFoundation
import UIKit

class AudioPlayerViewController: UIViewController {
    
    var fileUrl: URL?
    
    
    var isPlaying = false
    
    let vodBasedTimeline = VodBasedTimeline()
    
    var artwork: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "redbee")
        return imageView
    }()
    
    let largeConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold, scale: .default)
    
    var playerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    var timelineStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .vertical
        return stackView
    }()
    
    
    
    var playPauseButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 160, y: 0, width: 160, height: 160)
        button.addTarget(self, action: #selector(playPause), for: .touchUpInside)
        return button
    }()
    
    var nextButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 60)
        button.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        button.addTarget(self, action: #selector(goFroward), for: .touchUpInside)
        return button
    }()
    
    var previousButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 60)
        button.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        button.addTarget(self, action: #selector(goBackward), for: .touchUpInside)
        return button
    }()
    
    var audioPlayer =  AVAudioPlayer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "MP3 Offline Player"
        
        setupUI()
        
        
        if let url = fileUrl {
            do {
                
                self.audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: "MP3")
                self.audioPlayer.prepareToPlay()
                self.audioPlayer.play()
                
                self.playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: self.largeConfig), for: .normal)
                
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longForm)
                
                vodBasedTimeline.startLoop()
                
                
                vodBasedTimeline.currentPlayheadPosition = { [weak self] in
                    return Int64(self?.audioPlayer.currentTime ?? 0)*1000
                }
                vodBasedTimeline.currentDuration = { [weak self] in
                    return Int64(self?.audioPlayer.duration ?? 0)*1000
                }
                
                
                vodBasedTimeline.onSeek = { [weak self] offset in
                    self?.audioPlayer.play(atTime: self?.audioPlayer.currentTime ?? 0 + Double(offset) )
                }
                
            } catch {
                print(" Error " , error.localizedDescription)
            }
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        audioPlayer.stop()
        
    }
    
    @objc func goFroward() {
        
        var timeForward = audioPlayer.currentTime
        
        
        let duration = audioPlayer.duration
        
        
        timeForward += 10.0 // forward 10 secs
        
        if (timeForward > duration) {
            audioPlayer.currentTime = timeForward
        } else {
            audioPlayer.currentTime =  duration
        }
    }
    
    @objc func goBackward() {
        var timeBack = audioPlayer.currentTime * 1000
        timeBack += -10.0 // forward 10 secs
        
        if (timeBack > 0) {
            audioPlayer.currentTime = timeBack
        } else {
            audioPlayer.currentTime =  0
        }
        
    }
    
    @objc func playPause() {
        if audioPlayer.isPlaying {
            self.playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: self.largeConfig), for: .normal)
            audioPlayer.pause()
            
        } else {
            self.playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: self.largeConfig), for: .normal)
            audioPlayer.play()
        }
    }
    
}

extension AudioPlayerViewController {
    
    fileprivate func setupUI() {
        
        view.addSubview(artwork)
        view.addSubview(timelineStackView)
        timelineStackView.addArrangedSubview(vodBasedTimeline)
        view.addSubview(playerStackView)
        
        artwork.anchor(top: view.topAnchor, bottom: timelineStackView.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: .init(top: 100, left: 0, bottom: 0, right: 0))
        
        
        
        timelineStackView.anchor(top: artwork.bottomAnchor, bottom: playerStackView.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 20, left: 20, bottom: 0, right: -20), size: .init(width: self.view.frame.size.width, height: 100))
        
        timelineStackView.addArrangedSubview(vodBasedTimeline)
        
        vodBasedTimeline.anchor(top: timelineStackView.topAnchor, bottom: timelineStackView.bottomAnchor, leading: timelineStackView.leadingAnchor, trailing: timelineStackView.trailingAnchor, padding: .init(top: 0, left: 10, bottom: -10, right: -10))
        
        
        playerStackView.anchor(top: timelineStackView.bottomAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 20, bottom: 0, right: -20), size: .init(width: self.view.frame.size.width, height: 100))
        
        playerStackView.addArrangedSubview(previousButton)
        playerStackView.addArrangedSubview(playPauseButton)
        playerStackView.addArrangedSubview(nextButton)
        
        self.playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: self.largeConfig), for: .normal)
    }
}
