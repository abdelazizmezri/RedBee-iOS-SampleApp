//
//  ProgramBasedTimeline.swift
//  iOSReferenceApp
//
//  Created by Fredrik Sjöberg on 2018-03-06.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import AVFoundation
import iOSClientExposure

class ProgramBasedTimeline: UIView {
    

    // Main content view which holds the blur view
    let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // Blur View which holds all the elements
    //    let blurView: UIView = {
    //        let view = UIView()
    //        view.backgroundColor = UIColor.black
    //        view.layer.opacity = 0.5
    //        view.layer.borderColor = PlayerColors.active.textFieldPlaceholder.cgColor
    //        view.layer.cornerRadius = 5
    //        view.layer.borderWidth = 0.2
    //        return view
    //    }()
    
    let blurView: UIStackView = {
        let stackview = UIStackView()
        stackview.distribution = .fillProportionally
        stackview.axis = .horizontal
        return stackview
    }()
    
    // Three container stack views to hold content
    let leftContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    let middleContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    let rightContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .horizontal
        return stackView
    }()
    
    
    // Views related to left
    let leftTimeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        return label
    }()
    let goLiveIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()
    
    let goLiveButton: UIButton = {
        let button = UIButton()
        button.setTitle("LIVE", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(goLiveAction), for: .touchUpInside)
        button.titleLabel?.font = button.titleLabel?.font.withSize(11)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        return button
    }()
    
    
    // Views related to middle
    let playheadSlider: CustomSlider = {
        let slider = CustomSlider()
        slider.isSelected = true
        slider.minimumTrackTintColor = .red
        slider.maximumTrackTintColor = .white
        slider.addTarget(self, action: #selector(seekAction(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(seekAction(_:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(playheadSliderAction(_:event:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderDidEndSliding), for: [.touchUpInside, .touchUpOutside])
        //slider.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        return slider
    }()
    
    let liveEdgeIndicator: UIProgressView = {
        let progressview = UIProgressView()
        progressview.progressTintColor = .white
        progressview.trackTintColor = .white
        return progressview
    }()
    
    
    // Views related right side
    let rightTimeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .white
        return label
    }()
    
    
    var spriteImageView: UIImageView = {
        let uiImageView = UIImageView()
        uiImageView.contentMode = .scaleAspectFill
        uiImageView.translatesAutoresizingMaskIntoConstraints = false
        return uiImageView
    }()
    
    private var spriteViewCenterXConstraint: NSLayoutConstraint!
    private var spriteViewCenterXConstraintConstant: Float = 0
    
    var adDuration: Int64 = 0
    var adMarkers = [MarkerPoint]()
    var isAdPlaying: Bool = false
    var playbackType : String = "LIVE"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
        // setup slider thumb
        let sliderThumbImage = UIImage(named: "sliderThumb")
        playheadSlider.minimumTrackTintColor = .red
        playheadSlider.maximumTrackTintColor = .white
        playheadSlider.setThumbImage(sliderThumbImage?.imageWithColor(color1: .red), for: .normal)
        playheadSlider.setThumbImage(sliderThumbImage?.imageWithColor(color1: .red), for: .highlighted)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.adDuration = 0
        stopLoop()
    }
    
    public func startLoop() {
        isAdPlaying = false
        
        timer = DispatchSource.makeTimerSource(queue: self.timerQueue)
        timer?.schedule(wallDeadline: .now(), repeating: .milliseconds(1000))
        timer?.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.updateLoop()
            }
        }
        timer?.resume()
    }
    
    public func stopLoop() {
        isAdPlaying = false
        timer?.setEventHandler{}
        timer?.cancel()
    }
    
    public func resumeTimer() {
        isAdPlaying = false
    }
    
    func pausedTimer() {
        isAdPlaying = true
    }
    
    @objc func goLiveAction(_ sender: UIButton) {
        
        // self.playheadSlider.value = 1
        // self.seekAction()
        
        goLiveTrigger()
    }
    
    @objc func startOverAction(_ sender: UIButton) {
        startOverTrigger()
    }
    
    fileprivate var isSliding: Bool = false
    fileprivate var lastPlayheadSliderValue: Float?
    
   
    
    @objc func playheadSliderAction(_ sender: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                isSliding = true
                onPlayheadStartAction(true)
                spriteViewCenterXConstraintConstant = Float(spriteViewCenterXConstraint.constant)
            case .moved:
                isSliding = true
                
                if let previousValue = lastPlayheadSliderValue {
                    if sender.value > previousValue && !canFastForward {
                        // sender.value = previousValue
                        return
                    }

                    if sender.value < previousValue && !canRewind {
                        // sender.value = previousValue
                        return
                    }
                }

                /* if !liveEdgeIndicator.isHidden {
                    if sender.value > liveEdgeIndicator.progress {
                        sender.value = liveEdgeIndicator.progress
                        return
                    }
                } */

            
                let getSeekDeltaValues = getSeekDelta(sender.value)
                guard let getSeekDeltaValues = getSeekDeltaValues else { return }
                
                // let leftTimeValue = getSeekDeltaValues.leftTimeValue
                // leftTimeLabel.text = timeFormat(time: leftTimeValue )
                
                let currentTime = timeFormat(time: getSeekDeltaValues.seekDelta)
                
                let trackRect = playheadSlider.trackRect(forBounds: playheadSlider.bounds)
                let thumbRect = playheadSlider.thumbRect(forBounds: playheadSlider.bounds, trackRect: trackRect, value: playheadSlider.value)

                spriteViewCenterXConstraint.constant = (thumbRect.maxX + thumbRect.minX)/2
                
                onScrubbing(currentTime)
                
                
                
            case .ended:
                isSliding = false
                onPlayheadStartAction(false)
                spriteViewCenterXConstraintConstant = Float(spriteViewCenterXConstraint.constant)
                spriteImageView.image = nil
                seekAction(sender)
            default:
                break
            }
        }
    }
    
    @objc func sliderDidEndSliding(_ sender: UISlider) {
        isSliding = false
        onPlayheadStartAction(false)
        spriteViewCenterXConstraintConstant = Float(spriteViewCenterXConstraint.constant)
        spriteImageView.image = nil
    }
    
    @objc func seekAction(_ sender: UISlider) {

        isSliding = false
        let getSeekDeltaValues = getSeekDelta(sender.value)
        guard let startTime = getSeekDeltaValues?.startTime , let seekDelta = getSeekDeltaValues?.seekDelta else {
            return
            
        }
        onSeek(startTime + seekDelta)
    }
    
    
    
    /// Calculate the  seek delta value
    /// - Parameter senderValue: seek value
    /// - Returns: start time & the seek delta value
    func getSeekDelta(_ senderValue: Float) -> (startTime:Int64, seekDelta:Int64, leftTimeValue: Int64 )?  {
        
        // Note : Assume , seekableTimeRanges end is curent live time & self.seekableTimeRanges start is seek end time
        guard let start = (self.seekableTimeRanges?.last?.start.milliseconds) , let end = (self.seekableTimeRanges?.last?.end.milliseconds) else {
            return nil
        }
        
        
        let seekDelta = Int64(senderValue * Float(end - start))
        let leftTimeValue = Int64(senderValue * Float( start - end ))
        // let seekDelta = Int64(senderValue * Float(endTime - startTime))
        return (start,seekDelta, leftTimeValue)
    }
    
    
    
    
    fileprivate var timerQueue = DispatchQueue(label: "com.emp.whitelabel.programBasedTimeLine", qos: DispatchQoS.background, attributes: DispatchQueue.Attributes.concurrent)
    fileprivate var timer: DispatchSourceTimer?
    fileprivate func updateLoop() {
        if let program = currentProgram {
            epgUpdateLoop(program: program)
        }
        else {
            noEpgUpdateLoop()
        }
    }
    
    /// MARK: Configuration
    var currentPlayheadTime: () -> Int64? = { return nil }
    var timeBehindLiveEdge: () -> Int64? = { return nil }
    var currentProgram: Program?
    var seekableTimeRanges: [CMTimeRange]?
    
    var contentDuration: () -> Int64? = { return nil }
    
    var canFastForward: Bool = true {
        didSet {
            // Update UI restrictions
            if !canFastForward && !canRewind {
                playheadSlider.isUserInteractionEnabled = false
            }
            else {
                playheadSlider.isUserInteractionEnabled = true
            }
        }
    }
    var canRewind: Bool = true {
        didSet {
            // Update UI restrictions
            if !canFastForward && !canRewind {
                playheadSlider.isUserInteractionEnabled = false
            }
            else {
                playheadSlider.isUserInteractionEnabled = true
            }
        }
    }
    
    /// MARK: Actions
    var goLiveTrigger: () -> Void = { }
    var startOverTrigger: () -> Void = { }
    var onSeek: (Int64) -> Void = { _ in }
    var onPlayheadStartAction:(Bool) ->Void = { _ in }
    var onScrubbing: (String) -> Void = { _ in }
}

// MARK: - Timeline Updates
extension ProgramBasedTimeline {
    
    fileprivate func epgUpdateLoop(program: Program) {
        
        let playheadTime = currentPlayheadTime()
        let timeBehindLive = timeBehindLiveEdge()
        var liveTime = playheadTime != nil && timeBehindLive != nil ? playheadTime! - timeBehindLive! : nil
        
      
        let programStart = seekableTimeRanges?.first?.start.milliseconds
        let programEndTime = seekableTimeRanges?.last?.end.milliseconds
        
        
        
        if !isAdPlaying {
            // Indicate time left
            updateTimelabels(playheadTime: playheadTime, programEnd: programEndTime ,programStart: programStart )
        }
       
        
        /// Update playheadSlider
        updatePlayheadSlider(startTime: programStart, playheadTime: playheadTime, endTime: programEndTime)
        
        
        if let start = seekableTimeRanges?.first?.start , let duration = seekableTimeRanges?.last?.duration {
            if let live =  ( start + duration ).milliseconds {
                liveTime = live
            }
        }
        
        /// Update liveEdge indicator
        updateLiveEdgeIndicator(startTime: programStart, liveTime: liveTime, endTime: programEndTime)
        
        // Update live indicator
        updateGoLiveIndicator(playheadTime: playheadTime, liveTime: liveTime)
    }
    
    fileprivate func noEpgUpdateLoop() {

        playheadSlider.isHidden = false

        // rightTimeLabel.isHidden = true
        
        let playheadTime = currentPlayheadTime()

        let timeBehindLive = timeBehindLiveEdge()
        
        let liveTime = playheadTime != nil && timeBehindLive != nil ? playheadTime! - timeBehindLive! : nil

        if let start = (self.seekableTimeRanges?.first?.start.milliseconds) , let end = (self.seekableTimeRanges?.last?.end.milliseconds) {
            updatePlayheadSlider(startTime: start, playheadTime: playheadTime, endTime: end)
            updateLiveEdgeIndicator(startTime:start, liveTime: liveTime, endTime: end)
            
            if !isAdPlaying {
                // Indicate time left
                updateTimelabels(playheadTime: playheadTime, programEnd: end ,programStart: start )
            }
            
        } else {
            updatePlayheadSlider(startTime: nil, playheadTime: playheadTime, endTime: currentProgram?.endDate?.millisecondsSince1970)
            updateLiveEdgeIndicator(startTime: nil, liveTime: liveTime, endTime: currentProgram?.endDate?.millisecondsSince1970)
        }
        
       
                
        
        updateGoLiveIndicator(playheadTime: playheadTime, liveTime: liveTime)
    }
    
    private func updateTimelabels(playheadTime: Int64?, programEnd: Int64?, programStart : Int64? ) {
        guard !isSliding else { return }
        
        // Indicate current offset
        if let endTime = programEnd, let playhead = playheadTime, let _ = programStart  {
            
            if self.playbackType == "VOD" {
                rightTimeLabel.isHidden = false
                rightTimeLabel.text = timeFormat(time: endTime )
            } else {
                
                if endTime >= playhead {
                    leftTimeLabel.isHidden = true

                    // Ignore if the time behind live is considerably low
                    if  abs(playhead - endTime) <= 10000 {
                        rightTimeLabel.text = ""
                        rightTimeLabel.isHidden = true
                    } else {
                        rightTimeLabel.isHidden = false
                        rightTimeLabel.text = timeFormat(time: playhead - endTime )
                    }
                    
                }
                else {
                    // Warning. Program has ended, request new program
                    rightTimeLabel.isHidden = true
                    leftTimeLabel.isHidden = true
                }
            }

        }
        else {
            rightTimeLabel.isHidden = true
            leftTimeLabel.isHidden = true
        }
    }
    
    private func updateGoLiveIndicator(playheadTime: Int64?, liveTime: Int64?) {
        
        if let playhead = playheadTime, let live = liveTime {
            if isLive(playhead: playhead, live: live) {
                leftTimeLabel.isHidden = true
                rightTimeLabel.isHidden = true
                self.goLiveButton.isHidden = false
                goLiveIndicator.isHidden = false
                goLiveIndicator.backgroundColor = .red
            }
            else {
                if self.playbackType == "VOD" {
                    self.goLiveButton.isHidden = true
                    goLiveIndicator.isHidden = true
                    leftTimeLabel.isHidden = false
                    rightTimeLabel.isHidden = false
                    leftTimeLabel.text = timeFormat(time: playhead)
                } else {
                    
                    /// Indicate the time behind live
                    rightTimeLabel.isHidden = false
                    leftTimeLabel.isHidden = false
                    goLiveIndicator.isHidden = false
                    self.goLiveButton.isHidden = false
                    goLiveIndicator.backgroundColor = .white
                }
           
            }
        }
        else {
            if self.playbackType == "VOD" {
                self.goLiveButton.isHidden = true
                goLiveIndicator.isHidden = true
                rightTimeLabel.isHidden = false
                if let playhead = playheadTime {
                    leftTimeLabel.isHidden = false
                    leftTimeLabel.text = timeFormat(time: playhead)
                }
            } else {
                goLiveIndicator.backgroundColor = .white
                leftTimeLabel.isHidden = true
                rightTimeLabel.isHidden = true
            }
            
        }
    }
    
    private func updateLiveEdgeIndicator(startTime: Int64?, liveTime: Int64?, endTime: Int64?) {
        if let live = liveTime, let start = startTime, let end = endTime {
            liveEdgeIndicator.isHidden = false
            if start <= live {
                let progress = live <= end ? Float(live - start) / Float(end - start) : 1
                liveEdgeIndicator.setProgress(Float(progress), animated: false)
            }
            else {
                /// Warning, the program has not started yet
                liveEdgeIndicator.setProgress(0, animated: false)
            }
        }
        else {
            liveEdgeIndicator.isHidden = true
        }
    }
    
    private func updatePlayheadSlider(startTime: Int64?, playheadTime: Int64?, endTime: Int64?) {

        guard !isSliding else { return }
        
        guard let start = (self.seekableTimeRanges?.first?.start.milliseconds) , let end = (self.seekableTimeRanges?.last?.end.milliseconds) else {
            
            DispatchQueue.main.async {
                self.playheadSlider.setNeedsLayout()
                self.playheadSlider.layoutIfNeeded()
                self.playheadSlider.isHidden = true
                self.playheadSlider.value = 1.0
                self.lastPlayheadSliderValue = nil
            }
            
            return
        }

            if let playhead = playheadTime {
                playheadSlider.isHidden = false
                if start <= playhead && playhead <= end {
                    let progress = Float(playhead - start) / Float(end - start)
                    lastPlayheadSliderValue = Float(progress)
                    
                    DispatchQueue.main.async {
                        self.playheadSlider.setNeedsLayout()
                        self.playheadSlider.layoutIfNeeded()
                        self.playheadSlider.setValue(Float(progress), animated: false)
                    }
                   
                }
                else {
                    if playhead > end {
                        rightTimeLabel.isHidden = true
                        lastPlayheadSliderValue = 1
                        DispatchQueue.main.async {
                            self.playheadSlider.setNeedsLayout()
                            self.playheadSlider.layoutIfNeeded()
                            self.playheadSlider.setValue(1, animated: false)
                        }
                    } else {
                        /// Warning, the program has ended
                        rightTimeLabel.isHidden = true
                        lastPlayheadSliderValue = 1
                        
                        DispatchQueue.main.async {
                            self.playheadSlider.setNeedsLayout()
                            self.playheadSlider.layoutIfNeeded()
                            self.playheadSlider.setValue(1, animated: false)
                        }
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    self.playheadSlider.setNeedsLayout()
                    self.playheadSlider.layoutIfNeeded()
                    self.playheadSlider.isHidden = false
                    self.playheadSlider.value = 1.0
                }
                lastPlayheadSliderValue = nil
            }
    }
}


// MARK: - Timeformat
extension ProgramBasedTimeline {
    fileprivate func timeFormat(time: Int64) -> String {
        return time.timeFormat()
    }
    
    fileprivate func isLive(playhead: Int64, live: Int64) -> Bool {
        let closeEnough: Int64 = 2 * 6000
        let delta = playhead - live
        return abs(delta) < closeEnough
    }
}

extension ProgramBasedTimeline {
    
    func clearAdMarkerCache() {
        // Remove any previously added subViews with tag `101`
        self.playheadSlider.subviews.filter({$0.tag == 101 }).forEach({$0.removeFromSuperview()})
    }
    
    /// Show ad markers to the timeline
    /// - Parameters:
    ///   - adMarkers: adMarkers
    ///   - totalDuration: total duration including ads
    func showAdTickMarks(adMarkers: [MarkerPoint] , totalDuration:Int64, vodDuration: Int64 ) {

        // Remove any previously added subViews with tag `101`
        self.playheadSlider.subviews.filter({$0.tag == 101 }).forEach({$0.removeFromSuperview()})
        
        self.playheadSlider.minimumValue = 0

        for (_, adMarker) in adMarkers.enumerated() {
                    
            if (adMarker.type == "Ad" ) {
                
                if let offset = adMarker.offset {
                    
                    if offset == 0 {
                        let tick = UIView(frame: CGRect(x: 0 , y: 0, width: 5, height: self.playheadSlider.trackRect(forBounds: playheadSlider.bounds).height))
                        tick.tag = 101
                        tick.backgroundColor = UIColor.yellow
                        self.playheadSlider.insertSubview(tick, belowSubview: self.playheadSlider)
                        
                    } else {
                        
                        if offset < vodDuration {
                            let adMarkerStartingTimeinSeconds =  CGFloat(offset)
                            
                            let playheaderSliderLength = self.middleContainerView.layer.frame.size.width - 2

                            let markerPoint = playheaderSliderLength * (adMarkerStartingTimeinSeconds / CGFloat (totalDuration))
    
                            let tick = UIView(frame: CGRect(x: markerPoint , y: 0, width: 5, height: self.playheadSlider.trackRect(forBounds: playheadSlider.bounds).height))
                            tick.tag = 101
                            tick.backgroundColor = UIColor.yellow
                            self.playheadSlider.insertSubview(tick, belowSubview: self.playheadSlider)
                        }
                    }
                }
                
                // Check if we have post roll ads, if so Ad the marker to the end of the timeline.
                if let endoffset = adMarker.endOffset {
                   if(endoffset >= totalDuration) {

                       let tick = UIView(frame: CGRect( x: (playheadSlider.layer.bounds.size.width - 5 ) , y: 0, width: 5, height: self.playheadSlider.trackRect(forBounds: playheadSlider.bounds).height))
                        tick.tag = 101
                        tick.backgroundColor = UIColor.yellow
                        self.playheadSlider.insertSubview(tick, belowSubview: self.playheadSlider)
                    }
                }
            }
        }
    }
}


// MARK: - Layout
extension ProgramBasedTimeline {
    fileprivate func setupLayout() {
        
        addSubview(contentView)
        addSubview(blurView)
        
        addSubview(leftContainerView)
        
        leftContainerView.addArrangedSubview(goLiveIndicator)
        leftContainerView.addArrangedSubview(goLiveButton)
        leftContainerView.addArrangedSubview(leftTimeLabel)

        addSubview(middleContainerView)
        middleContainerView.addArrangedSubview(playheadSlider)
        
        addSubview(rightContainerView)
        rightContainerView.addArrangedSubview(rightTimeLabel)
        // rightContainerView.addArrangedSubview(startOverButton)
        
        contentView.addSubview(spriteImageView)
        
        // Main View
        contentView.anchor(top: self.topAnchor, bottom: self.bottomAnchor, leading: self.leadingAnchor, trailing: self.trailingAnchor)
        
        blurView.anchor(top: contentView.topAnchor, bottom: contentView.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor)
        
        // Left ContainerView
        leftContainerView.anchor(top: blurView.topAnchor, bottom: blurView.bottomAnchor, leading: blurView.leadingAnchor, trailing: nil, padding: .init(top: 0, left: 4, bottom: -20, right: 0))
        
        // Right Container
        rightContainerView.anchor(top: blurView.topAnchor, bottom: blurView.bottomAnchor, leading: nil, trailing: contentView.trailingAnchor, padding: .init(top: 0, left:0, bottom: -20, right: 0))
        
        goLiveIndicator.anchor(top: nil, bottom: nil, leading: nil, trailing: nil, padding: .init(top: 0, left: 4, bottom: 0, right: 0), size: .init(width: 4, height: 4))
        goLiveIndicator.centerYAnchor.constraint(equalTo: leftContainerView.centerYAnchor).isActive = true
        
        // Middle container
        middleContainerView.anchor(top: blurView.topAnchor, bottom: blurView.bottomAnchor, leading: leftContainerView.trailingAnchor, trailing: rightContainerView.leadingAnchor, padding: .init(top: 0, left: 3, bottom: 0, right: -5))
        
        //middleContainerView.widthAnchor.constraint(equalTo: blurView.widthAnchor, multiplier: 6/10).isActive = true
        middleContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        leftContainerView.heightAnchor.constraint(equalToConstant: 20 ).isActive = true
        middleContainerView.heightAnchor.constraint(equalToConstant: 20 ).isActive = true
        playheadSlider.heightAnchor.constraint(equalToConstant: 20 ).isActive = true
        rightContainerView.heightAnchor.constraint(equalToConstant: 20 ).isActive = true
        
//        goLiveIndicator.anchor(top: leftContainerView.topAnchor, bottom: nil, leading: nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 20, right: 0), size: .init(width: 4, height: 4))
//        goLiveButton.anchor(top: leftContainerView.topAnchor, bottom: nil, leading:nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 20, right: 0))
//        leftTimeLabel.anchor(top: leftContainerView.topAnchor, bottom: nil, leading: nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 20, right: 0))
        
        

        
        /* startOverButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
         startOverButton.heightAnchor.constraint(equalToConstant: 18).isActive = true */
        
        spriteImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -80).isActive = true
        spriteViewCenterXConstraint = spriteImageView.centerXAnchor.constraint(equalTo: playheadSlider.leadingAnchor, constant: CGFloat(0))
        spriteViewCenterXConstraint.isActive = true
        
        self.setupAppearance()
    }
    
    func setupAppearance() {
        
        goLiveButton.tintColor = .white
        leftTimeLabel.textColor = .white
        rightTimeLabel.textColor = .white
        
        //playheadSlider.minimumTrackTintColor = PlayerColors.active.accent
        playheadSlider.thumbTintColor = .white
        //playheadSlider.maximumTrackTintColor = .clear
        liveEdgeIndicator.progressTintColor = .red
        liveEdgeIndicator.trackTintColor = .red
        
        rightTimeLabel.text = ""
        leftTimeLabel.text = ""
        
    }
}
