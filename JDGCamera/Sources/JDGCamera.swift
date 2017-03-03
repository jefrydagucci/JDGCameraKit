//
//  JDGCamera.swift
//  JDGCamera
//
//  Created by Jefry Da Gucci on 3/3/17.
//  Copyright © 2017 jefrydagucci. All rights reserved.
//

import UIKit
import LLSimpleCamera
import SDRecordButton
import IoniconsSwift
import UIImage_Additions

protocol JDGCameraDelegate {
    func jdg_cameraDidCapture(_ image:UIImage?,_ info:[AnyHashable : Any]?,_ error:Error?)
    func jdg_cameraDidRecord(_ url:URL?,_ error:Error?)
}

class JDGCamera: UIViewController {
    
    private let toolbarView = UIView()
    private let topToolbarView = UIView()
    
    var defaultRecordButtonColor:UIColor = UIColor.white
    var defaultProgressColor:UIColor = UIColor.red
    var defaultRecordButtonImage:UIImage?
    
    var recordButton:SDRecordButton?
    private var flashButton:UIButton? = UIButton()
    private var cameraModeButton:UIButton? = UIButton()
    
    var recordButtonWidth  = 90
    
    var cameraPosition:LLCameraPosition = LLCameraPositionRear
    var cameraDelegate:JDGCameraDelegate?
    
    private var camera:LLSimpleCamera?
    
    private var timerRecording:Timer?
    private var timerLongPress:Timer?
    
    private let progressTimeRepeatingValue:CGFloat  = 0.05
    var maximumRecordingDuration:CGFloat    = 60
    var recordingDelay:CGFloat  = 1.0
    
    private var currentRecordingProgress:CGFloat  = 0
    
//    MARK:View
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCamera()
    }
    
//    MARK:Setup
    
    func setupCamera(){
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: DispatchTime.now().rawValue + (3 * 1000000)), execute: {
            LLSimpleCamera.requestPermission { (permitted) in
                if(permitted){
                    if let camera = LLSimpleCamera( quality: AVCaptureSessionPresetMedium, position: self.cameraPosition, videoEnabled: true){
                        let bound = UIScreen.main.bounds
                        
                        DispatchQueue.main.async {
                            camera.attach(to: self, withFrame: CGRect( x: 0, y: 0, width: bound.size.width, height: bound.size.height))
                            camera.start()
                            
                            self.camera = camera
                            
                            self.setupBottomToolbar()
                            self.setupTopToolbar()
                            camera.view.sendSubview(toBack: self.toolbarView)
                            camera.view.sendSubview(toBack: self.topToolbarView)
                        }
                    }
                    
                }
            }
        })
    }
    
    func setupBottomToolbar(){
        self.setupBottomToolbarView()
        self.setupButton()
    }
    
    func setupTopToolbar(){
        self.setupTopToolbarView()
        self.setupFlashButton()
        self.setupCameraModeButton()
    }
    
    func setupBottomToolbarView(){
        let screenBound = UIScreen.main.bounds
        let height:CGFloat = 150
        toolbarView.frame = CGRect( x: 0, y: screenBound.size.height - height, width: screenBound.size.width, height: height)
        toolbarView.autoresizingMask    = [.flexibleWidth, .flexibleBottomMargin]
        
        if !self.view.subviews.contains(toolbarView){
            self.view.addSubview(toolbarView)
        }
    }
    
    let topToolbarButtonWidth:CGFloat   = 35
    func setupTopToolbarView(){
        let screenBound = UIScreen.main.bounds
        let height:CGFloat = topToolbarButtonWidth * 3.5
        topToolbarView.frame = CGRect( x: 0, y: 0, width: screenBound.size.width, height: height)
        topToolbarView.autoresizingMask    = [.flexibleWidth, .flexibleTopMargin]
        
        if !self.view.subviews.contains(topToolbarView){
            self.view.addSubview(topToolbarView)
        }
    }
    
    func setupButton(){
        self.setupRecordingButton()
        self.setupButtonAction()
    }
    
    @objc private func setupRecordingButton(){
        let frame = CGRect( x: 0, y: 0, width: recordButtonWidth, height: recordButtonWidth)
        let btn = SDRecordButton(frame: frame)
        btn.buttonColor = defaultRecordButtonColor
        if let btnImg = defaultRecordButtonImage{
            btn.buttonColor = UIColor.clear
            btn.setImage(btnImg, for: .normal)
        }
        btn.progressColor   = defaultProgressColor
        if !toolbarView.subviews.contains(btn){
            toolbarView.addSubview(btn)
        }
        
        let toolbarFrame = toolbarView.frame
        let centerX = toolbarFrame.size.width/2
        let centerY = toolbarFrame.size.height/2
        btn.center  = CGPoint( x: centerX, y: centerY)
        recordButton = btn
    }
    
    @objc private func setupFlashButton(){
        guard let camera = camera else{ return }
        if(camera.isFlashAvailable()){
            let frame = CGRect( x: 0, y: 0, width: topToolbarButtonWidth, height: topToolbarButtonWidth)
            guard let flashButton = flashButton else{ return }
            flashButton.frame = frame
            if !topToolbarView.subviews.contains(flashButton){ topToolbarView.addSubview(flashButton) }
            
            let toolbarFrame = topToolbarView.frame
            flashButton.center  = CGPoint( x: topToolbarButtonWidth * 2, y: toolbarFrame.size.height * 0.5)
            
            flashButton.setImage(Ionicons.flashOff.image(frame.size.width).add_tintedImage(with: .white, style: ADDImageTintStyleKeepingAlpha), for: .normal)
            flashButton.setImage(Ionicons.flash.image(frame.size.width).add_tintedImage(with: .white, style: ADDImageTintStyleKeepingAlpha), for: .selected)
            
            flashButton.removeTarget(self, action: nil, for: .allEvents)
            flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        }
    }
    
    @objc private func setupCameraModeButton(){
        if(LLSimpleCamera.isRearCameraAvailable() && LLSimpleCamera.isFrontCameraAvailable()){
        
            let flashButtonFrame = flashButton?.frame ?? CGRect( x: topToolbarButtonWidth, y: 0, width: 0, height: 0)
            let frame = CGRect( x: flashButtonFrame.origin.x + flashButtonFrame.size.width + topToolbarButtonWidth, y: 0, width: topToolbarButtonWidth, height: topToolbarButtonWidth)
            guard let cameraModeButton = cameraModeButton else{ return }
            cameraModeButton.frame = frame
            if !topToolbarView.subviews.contains(cameraModeButton){ topToolbarView.addSubview(cameraModeButton) }
            
            let toolbarFrame = topToolbarView.frame
            cameraModeButton.center  = CGPoint( x: UIScreen.main.bounds.size.width - (topToolbarButtonWidth * 2), y: toolbarFrame.size.height * 0.5)
            
            cameraModeButton.setImage(Ionicons.iosReverseCamera.image(frame.size.width).add_tintedImage(with: .white, style: ADDImageTintStyleKeepingAlpha), for: .normal)
            
            cameraModeButton.removeTarget(self, action: nil, for: .allEvents)
            cameraModeButton.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
        }
    }
    
    @objc private func setupButtonAction(){
        self.setupRecordButtonAction()
    }
    
    @objc private func setupRecordButtonAction(){
        guard let recordButton     = recordButton else{ return }
        recordButton.addTarget(self, action: #selector(recordButtonTapDown), for: .touchDown)
        recordButton.addTarget(self, action: #selector(captureOrStopRecord), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(captureOrStopRecord), for: .touchUpOutside)
    }
    
//    MARK:Timer
    func startRecordingTimer(){
        let isRepeat = true
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.timerRecording  = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.progressTimeRepeatingValue), repeats: isRepeat, block: { (timer:Timer) in
                    self.updateRecordingProgress()
                })
            } else {
                self.timerRecording  = Timer.scheduledTimer(timeInterval: TimeInterval(self.progressTimeRepeatingValue), target: self, selector: #selector(self.updateRecordingProgress), userInfo: nil, repeats: isRepeat)
            }
        }
    }
    
    @objc private func updateRecordingProgress(){
        guard let btn = recordButton else{ return }
        
        if(currentRecordingProgress >= maximumRecordingDuration){
            self.captureOrStopRecord()
            guard let recordButton  = recordButton else{ return }
            recordButton.endTracking(nil, with: nil)
            recordButton.sendActions(for: .touchUpOutside)
        }
        currentRecordingProgress += progressTimeRepeatingValue
        btn.setProgress(currentRecordingProgress/maximumRecordingDuration)
    }
    
//    MARK:Action
    
    func toggleFlash(){
        guard let flashButton = flashButton else{ return }
        flashButton.isSelected  = !flashButton.isSelected
        
        _ = camera?.updateFlashMode(flashButton.isSelected ? LLCameraFlashOn : LLCameraFlashOff)
    }
    
    func toggleCameraPosition(){
        guard let camera = camera else{ return }
        camera.togglePosition()
    }
    
    @objc private func recordButtonTapDown(){
        let isRepeat = false
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.timerLongPress  = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.recordingDelay), repeats: isRepeat, block: { (timer:Timer) in
                    self.captureLongPress()
                })
            } else {
                self.timerLongPress  = Timer.scheduledTimer(timeInterval: TimeInterval(self.recordingDelay), target: self, selector: #selector(self.captureLongPress), userInfo: nil, repeats: isRepeat)
            }
        }
    }
    
    @objc private func cancelWillStartRecording(){
        timerLongPress?.invalidate()
        timerLongPress  = nil
    }
    
    @objc private func captureLongPress(){
        self.startRecording()
    }
    
    func capture(){
        camera?.capture({ (camera:LLSimpleCamera?, image:UIImage?, info:[AnyHashable : Any]?, error:Error?) in
            
            guard let delegate = self.cameraDelegate else{ return }
            delegate.jdg_cameraDidCapture(image, info, error)
            
        }, exactSeenImage: true)
    }
    
    @objc private func startRecording(){
        guard let camera = camera else { return }
        if !camera.isRecording{
            self.record()
        }
    }
    
    func captureOrStopRecord(){
        guard let camera = camera else { return }
        if (camera.isRecording){
            camera.stopRecording()
            
            currentRecordingProgress = 0
            self.timerRecording?.invalidate()
        }
        else{
            self.cancelWillStartRecording()
            self.capture()
        }
    }
    
    @objc private func endRecording(){
        guard let camera = camera else { return }
        camera.stopRecording()
        self.timerRecording?.invalidate()
        currentRecordingProgress = 0
        guard let btn = recordButton else{ return }
        btn.setProgress(currentRecordingProgress)
    }
    
    func record(){
        do {
            let docDir  = try FileManager.default.url(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
            var fileURL = docDir.appendingPathComponent("temp")
            
            var idx:Int = 1
            while FileManager.default.fileExists(atPath: fileURL.path) {
                idx += 1
                let str = fileURL.absoluteString.appending((idx as NSNumber).stringValue)
                guard let url = URL( string: str) else { break }
                fileURL = url
            }
            let videoFilePath = fileURL.appendingPathExtension("mp4")
            
            guard let camera = self.camera else{ return }
            self.startRecordingTimer()
            camera.startRecording(withOutputUrl: videoFilePath, didRecord: { (camera:LLSimpleCamera?, url:URL?, error:Error?) in
                
                self.endRecording()
                guard let delegate = self.cameraDelegate else{ return }
                delegate.jdg_cameraDidRecord(url, error)
                
            })
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}
