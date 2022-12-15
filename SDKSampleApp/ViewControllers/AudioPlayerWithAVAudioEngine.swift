//
//  AudioPlayerWithAVAudioEngine.swift
//  SDKSampleApp
//
//  Created by Udaya Sri Senarathne on 2022-12-15.
//

import Foundation
import AVFoundation
import UIKit

class AudioPlayerWithAVAudioEngine: UIViewController {
    
    var fileUrl: URL?
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let timeEffect = AVAudioUnitTimePitch()
    
    private var audioFile: AVAudioFile?
    private var audioSampleRate: Double = 0
    private var audioLengthSeconds: Double = 0
    
    private var seekFrame: AVAudioFramePosition = 0
    private var currentPosition: AVAudioFramePosition = 0
    private var audioLengthSamples: AVAudioFramePosition = 0
    
    var timer: Timer!
    
    private var needsFileScheduled = true
    var isPlaying = false
    var isPlayerReady = false
    
    var meterLevel: Float = 0
    var playerProgress: Double = 0
    var playerTime: PlayerTime = .zero
    
    private var displayLink: CADisplayLink?
    
    private var currentFrame: AVAudioFramePosition {
        guard
            let lastRenderTime = player.lastRenderTime,
            let playerTime = player.playerTime(forNodeTime: lastRenderTime)
        else {
            return 0
        }
        
        return playerTime.sampleTime
    }
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "MP3 Offline Player"
        setupUI()
        setupAudio()
        setupDisplayLink()
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        player.stop()
        
    }
    
    @objc func goFroward() {
        seek(to: 10)
    }
    
    @objc func goBackward() {
        seek(to: -10)
    }
    
    @objc func playPause() {
        if player.isPlaying {
            self.playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: self.largeConfig), for: .normal)
            player.pause()
            displayLink?.isPaused = true
        } else {
            self.playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: self.largeConfig), for: .normal)
            player.play()
            displayLink?.isPaused = false
        }
    }
    
    
    private func setupAudio() {
        do {
            if let url = fileUrl {
                let file = try AVAudioFile(forReading: url )
                let format = file.processingFormat
                
                audioLengthSamples = file.length
                audioSampleRate = format.sampleRate
                audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
                
                audioFile = file
                
                configureEngine(with: format)
            }
            
        } catch {
            print("Error reading the audio file: \(error.localizedDescription)")
        }
    }
    
    private func configureEngine(with format: AVAudioFormat) {
        engine.attach(player)
        
        engine.attach(timeEffect)
        
        engine.connect(
            player,
            to: timeEffect,
            format: format)
        engine.connect(
            timeEffect,
            to: engine.mainMixerNode,
            format: format)
        
        engine.prepare()
        
        do {
            try engine.start()
            
            scheduleAudioFile()
            isPlayerReady = true
            
            player.play()
            vodBasedTimeline.startLoop()
            
            vodBasedTimeline.currentPlayheadPosition = { [weak self] in
                return self?.currentPosition
            }
            vodBasedTimeline.currentDuration = { [weak self] in
                return self?.audioLengthSamples
            }
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {[unowned self] timer in
                
                guard let nodeTime = player.lastRenderTime,
                      let playerTime = player.playerTime(forNodeTime: nodeTime) else {
                          print("No player time ")
                          return
                      }
                
                let secs = Double(playerTime.sampleTime) / playerTime.sampleRate
                print(secs)
                
            }
            
            
        } catch {
            print("Error starting the player: \(error.localizedDescription)")
        }
    }
    
    
    
    private func scheduleAudioFile() {
        guard
            let file = audioFile,
            needsFileScheduled
        else {
            return
        }
        
        needsFileScheduled = false
        seekFrame = 0
        
        player.scheduleFile(file, at: nil) {
            self.needsFileScheduled = true
        }
    }
    
    private func seek(to time: Double) {
        guard let audioFile = audioFile else {
            return
        }
        
        let offset = AVAudioFramePosition(time * audioSampleRate)
        seekFrame = currentPosition + offset
        seekFrame = max(seekFrame, 0)
        seekFrame = min(seekFrame, audioLengthSamples)
        currentPosition = seekFrame
        
        let wasPlaying = player.isPlaying
        player.stop()
        
        if currentPosition < audioLengthSamples {
            updateDisplay()
            needsFileScheduled = false
            
            let frameCount = AVAudioFrameCount(audioLengthSamples - seekFrame)
            player.scheduleSegment(
                audioFile,
                startingFrame: seekFrame,
                frameCount: frameCount,
                at: nil
            ) {
                self.needsFileScheduled = true
            }
            
            if wasPlaying {
                player.play()
            }
        }
    }
    
    @objc private func updateDisplay() {
        
        currentPosition = currentFrame + seekFrame
        currentPosition = max(currentPosition, 0)
        currentPosition = min(currentPosition, audioLengthSamples)
        
        if currentPosition >= audioLengthSamples {
            player.stop()
            
            seekFrame = 0
            currentPosition = 0
            
            isPlaying = false
            
            disconnectVolumeTap()
        }
        
        playerProgress = Double(currentPosition) / Double(audioLengthSamples)
        
        let time = Double(currentPosition) / audioSampleRate
        playerTime = PlayerTime(
            elapsedTime: time,
            remainingTime: audioLengthSeconds - time)
    }
    
    private func disconnectVolumeTap() {
        engine.mainMixerNode.removeTap(onBus: 0)
        meterLevel = 0
    }
    
    private func connectVolumeTap() {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        
        engine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { buffer, _ in
            guard let channelData = buffer.floatChannelData else {
                return
            }
            
            let channelDataValue = channelData.pointee
            let channelDataValueArray = stride(
                from: 0,
                to: Int(buffer.frameLength),
                by: buffer.stride)
                .map { channelDataValue[$0] }
            
            let rms = sqrt(channelDataValueArray.map {
                return $0 * $0
            }
                            .reduce(0, +) / Float(buffer.frameLength))
            
            let avgPower = 20 * log10(rms)
            let meterLevel = self.scaledPower(power: avgPower)
            
            DispatchQueue.main.async {
                self.meterLevel = self.isPlaying ? meterLevel : 0
            }
        }
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateDisplay))
        displayLink?.add(to: .current, forMode: .default)
        displayLink?.isPaused = true
    }
    
    private func scaledPower(power: Float) -> Float {
        guard power.isFinite else {
            return 0.0
        }
        
        let minDb: Float = -80
        
        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
    
}

extension AudioPlayerWithAVAudioEngine {
    
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


struct PlayerTime {
    let elapsedText: String
    let remainingText: String
    
    static let zero: PlayerTime = .init(elapsedTime: 0, remainingTime: 0)
    
    init(elapsedTime: Double, remainingTime: Double) {
        elapsedText = PlayerTime.formatted(time: elapsedTime)
        remainingText = PlayerTime.formatted(time: remainingTime)
    }
    
    private static func formatted(time: Double) -> String {
        var seconds = Int(ceil(time))
        var hours = 0
        var mins = 0
        
        if seconds > TimeConstant.secsPerHour {
            hours = seconds / TimeConstant.secsPerHour
            seconds -= hours * TimeConstant.secsPerHour
        }
        
        if seconds > TimeConstant.secsPerMin {
            mins = seconds / TimeConstant.secsPerMin
            seconds -= mins * TimeConstant.secsPerMin
        }
        
        var formattedString = ""
        if hours > 0 {
            formattedString = "\(String(format: "%02d", hours)):"
        }
        formattedString += "\(String(format: "%02d", mins)):\(String(format: "%02d", seconds))"
        return formattedString
    }
}

enum TimeConstant {
  static let secsPerMin = 60
  static let secsPerHour = TimeConstant.secsPerMin * 60
}
