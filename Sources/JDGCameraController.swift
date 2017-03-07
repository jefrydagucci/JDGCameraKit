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
import KGNAutoLayout

public protocol JDGCameraDelegate {
    func jdg_cameraDidCapture(cameraController:JDGCameraController, _ image:UIImage?,_ info:[AnyHashable : Any]?,_ error:Error?)
    func jdg_cameraDidRecord(cameraController:JDGCameraController, _ url:URL?,_ error:Error?)
    func jdg_cameraDidSetup(cameraController:JDGCameraController, toolbarView:UIView)
    func jdg_cameraDidSetup(cameraController:JDGCameraController, topToolbarView:UIView)
    func jdg_cameraDidSetup(cameraController:JDGCameraController, recordButton:SDRecordButton)
    func jdg_cameraDidSetup(cameraController:JDGCameraController, flashButton:UIButton)
    func jdg_cameraDidSetup(cameraController:JDGCameraController, cameraModeButton:UIButton)
}

open class JDGCameraController: UIViewController {
    
    open let toolbarView = UIView()
    open let topToolbarView = UIView()
    
    open var defaultRecordButtonColor:UIColor = UIColor.white
    open var defaultProgressColor:UIColor = UIColor.red
    open var defaultRecordButtonImage:UIImage?
    
    open private(set) var recordButton:SDRecordButton? = nil
    private var flashButton:UIButton? = UIButton()
    private var cameraModeButton:UIButton? = UIButton()
    
    private let recordButtonWidth:CGFloat   = 50
    
    open var cameraDelegate:JDGCameraDelegate?
    
    private var camera:LLSimpleCamera?
    
    private var timerRecording:Timer?
    private var timerLongPress:Timer?
    
    private let progressTimeRepeatingValue:CGFloat  = 0.05
    open var maximumRecordingDuration:CGFloat    = 60
    open var recordingDelay:CGFloat  = 1.0
    
    private var currentRecordingProgress:CGFloat  = 0
    
    //    MARK:View
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCamera()
    }
    
    //    MARK:Setup
    open func setupCamera(){
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: DispatchTime.now().rawValue + (3 * 1000000)), execute: {
            LLSimpleCamera.requestPermission { (permitted) in
                if(permitted){
                    if let camera = LLSimpleCamera( quality: AVCaptureSessionPresetMedium, position: LLCameraPositionRear, videoEnabled: true){
                        let bound = UIScreen.main.bounds
                        
                        DispatchQueue.main.async {
                            camera.attach(to: self, withFrame: CGRect( x: 0, y: 0, width: bound.size.width, height: bound.size.height))
                            camera.start()
                            
                            let subview = camera.view
                            subview?.translatesAutoresizingMaskIntoConstraints   = false
                            subview?.pinToEdgesOfSuperview()
                            
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
    
    @objc private func setupBottomToolbar(){
        self.setupBottomToolbarView()
        self.setupButton()
    }
    
    @objc private func setupTopToolbar(){
        self.setupTopToolbarView()
        self.setupFlashButton()
        self.setupCameraModeButton()
    }
    
    @objc private func setupBottomToolbarView(){
        let screenBound = self.view.bounds
        let height:CGFloat = recordButtonWidth * 1.6
        
        if !self.view.subviews.contains(toolbarView){
            self.view.addSubview(toolbarView)
        }
        toolbarView.translatesAutoresizingMaskIntoConstraints   = false
        toolbarView.pinToSideEdgesOfSuperview()
        toolbarView.pinToBottomEdgeOfSuperview()
        toolbarView.size(toHeight: height)
        
        jdg_cameraDidSetup(cameraController:self, toolbarView: toolbarView)
    }
    
    open func jdg_cameraDidSetup(cameraController:JDGCameraController, toolbarView:UIView){
        guard let delegate = self.cameraDelegate else { return }
        delegate.jdg_cameraDidSetup(cameraController: self, toolbarView:toolbarView)
    }
    
    let topToolbarButtonWidth:CGFloat   = 35
    @objc private func setupTopToolbarView(){
        let screenBound = UIScreen.main.bounds
        let height:CGFloat = topToolbarButtonWidth * 3.5
        if !self.view.subviews.contains(topToolbarView){
            self.view.addSubview(topToolbarView)
        }
        topToolbarView.translatesAutoresizingMaskIntoConstraints   = false
        topToolbarView.pinToSideEdgesOfSuperview()
        topToolbarView.pinToTopEdgeOfSuperview()
        topToolbarView.size(toHeight: height)
        
        jdg_cameraDidSetup(cameraController: self, topToolbarView:toolbarView)
    }
    
    open func jdg_cameraDidSetup(cameraController: JDGCameraController, topToolbarView:UIView){
        guard let delegate = self.cameraDelegate else { return }
        delegate.jdg_cameraDidSetup(cameraController: self, topToolbarView:toolbarView)
    }
    
    @objc private func setupButton(){
        self.setupRecordingButton()
        self.setupButtonAction()
    }
    
    @objc private func setupRecordingButton(){
        let btn = SDRecordButton( frame: CGRect( x: 0, y: 0, width: recordButtonWidth, height: recordButtonWidth))
        recordButton    = btn
        
        guard let recordButton = recordButton else{ return }
        recordButton.buttonColor = defaultRecordButtonColor
        if let btnImg = defaultRecordButtonImage{
            recordButton.buttonColor = UIColor.clear
            recordButton.setImage(btnImg, for: .normal)
        }
        recordButton.progressColor   = defaultProgressColor
        if !toolbarView.subviews.contains(recordButton){
            toolbarView.addSubview(recordButton)
        }
    
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.centerInSuperview()
        recordButton.size(toHeight: recordButtonWidth)
        recordButton.size(toWidth: recordButtonWidth)
        
        jdg_cameraDidSetup(cameraController: self, recordButton:recordButton)
    }
    
    open func jdg_cameraDidSetup(cameraController: JDGCameraController, recordButton: SDRecordButton){
        guard let delegate = self.cameraDelegate else { return }
        delegate.jdg_cameraDidSetup(cameraController: self, recordButton:recordButton)
    }
    
    @objc private func setupFlashButton(){
        guard let camera = camera else{ return }
//        if(camera.isFlashAvailable()){
            guard let flashButton = flashButton else{ return }
            if !topToolbarView.subviews.contains(flashButton){ topToolbarView.addSubview(flashButton) }
            
            let toolbarFrame = topToolbarView.frame
            flashButton.translatesAutoresizingMaskIntoConstraints   = false
            flashButton.size(toHeight: topToolbarButtonWidth)
            flashButton.sizeWidthToHeight(withAspectRatio: 1)
            flashButton.pinToLeftEdgeOfSuperview(withOffset: topToolbarButtonWidth, priority: UILayoutPriorityRequired)
            flashButton.pinToTopEdgeOfSuperview(withOffset: topToolbarButtonWidth, priority: UILayoutPriorityRequired)
            
            flashButton.setImage(Ionicons.flashOff.image(topToolbarButtonWidth).add_tintedImage(with: .white, style: ADDImageTintStyleKeepingAlpha), for: .normal)
            flashButton.setImage(Ionicons.flash.image(topToolbarButtonWidth).add_tintedImage(with: .white, style: ADDImageTintStyleKeepingAlpha), for: .selected)
            
            flashButton.removeTarget(self, action: nil, for: .allEvents)
            flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
            
            jdg_cameraDidSetup(cameraController: self, flashButton: flashButton)
//        }
    }
    
    open func jdg_cameraDidSetup(cameraController: JDGCameraController, flashButton: UIButton){
        guard let delegate = self.cameraDelegate else { return }
        delegate.jdg_cameraDidSetup(cameraController: self, flashButton: flashButton)
    }
    
    @objc private func setupCameraModeButton(){
        if(LLSimpleCamera.isRearCameraAvailable() && LLSimpleCamera.isFrontCameraAvailable()){
            
            let flashButtonFrame = flashButton?.frame ?? CGRect( x: topToolbarButtonWidth, y: 0, width: 0, height: 0)
            let frame = CGRect( x: flashButtonFrame.origin.x + flashButtonFrame.size.width + topToolbarButtonWidth, y: 0, width: topToolbarButtonWidth, height: topToolbarButtonWidth)
            guard let cameraModeButton = cameraModeButton else{ return }
            if !topToolbarView.subviews.contains(cameraModeButton){ topToolbarView.addSubview(cameraModeButton) }
            
            let toolbarFrame = topToolbarView.frame
            
            cameraModeButton.translatesAutoresizingMaskIntoConstraints   = false
            cameraModeButton.size(toHeight: topToolbarButtonWidth)
            cameraModeButton.sizeWidthToHeight(withAspectRatio: 1)
            cameraModeButton.pinToRightEdgeOfSuperview(withOffset: topToolbarButtonWidth, priority: UILayoutPriorityRequired)
            cameraModeButton.pinToTopEdgeOfSuperview(withOffset: topToolbarButtonWidth, priority: UILayoutPriorityRequired)
            
            cameraModeButton.setImage(Ionicons.iosReverseCamera.image(frame.size.width).add_tintedImage(with: .white, style: ADDImageTintStyleKeepingAlpha), for: .normal)
            
            cameraModeButton.removeTarget(self, action: nil, for: .allEvents)
            cameraModeButton.addTarget(self, action: #selector(toggleCameraPosition), for: .touchUpInside)
            
            jdg_cameraDidSetup(cameraController: self, cameraModeButton: cameraModeButton)
        }
    }
    
    open func jdg_cameraDidSetup(cameraController: JDGCameraController, cameraModeButton: UIButton){
        guard let delegate = self.cameraDelegate else { return }
        delegate.jdg_cameraDidSetup(cameraController: self, cameraModeButton: cameraModeButton)
    }
    
    @objc private func setupButtonAction(){
        self.setupRecordButtonAction()
    }
    
    @objc private func setupRecordButtonAction(){
        guard let recordButton = recordButton else{ return }
        
        recordButton.addTarget(self, action: #selector(recordButtonTapDown), for: .touchDown)
        recordButton.addTarget(self, action: #selector(captureOrStopRecord), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(captureOrStopRecord), for: .touchUpOutside)
    }
    
    //    MARK:Timer
    @objc private func startRecordingTimer(){
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
        guard let recordButton = recordButton else{ return }
        
        if(currentRecordingProgress >= maximumRecordingDuration){
            self.captureOrStopRecord()
            
            recordButton.endTracking(nil, with: nil)
            recordButton.sendActions(for: .touchUpOutside)
        }
        currentRecordingProgress += progressTimeRepeatingValue
        recordButton.setProgress(currentRecordingProgress/maximumRecordingDuration)
    }
    
    //    MARK:Action
    
    open func toggleFlash(){
        guard let flashButton = flashButton else{ return }
        flashButton.isSelected  = !flashButton.isSelected
        
        _ = camera?.updateFlashMode(flashButton.isSelected ? LLCameraFlashOn : LLCameraFlashOff)
    }
    
    open func toggleCameraPosition(){
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
    
    open func capture(){
        camera?.capture({ (camera:LLSimpleCamera?, image:UIImage?, info:[AnyHashable : Any]?, error:Error?) in
            
            guard let delegate = self.cameraDelegate else{ return }
            delegate.jdg_cameraDidCapture(cameraController:self, image, info, error)
            
        }, exactSeenImage: true)
    }
    
    @objc private func startRecording(){
        guard let camera = camera else { return }
        if !camera.isRecording{
            self.record()
        }
    }
    
    open func captureOrStopRecord(){
        guard let camera = camera else { return }
        if (camera.isRecording){
            self.stopRecording()
        }
        else{
            self.cancelWillStartRecording()
            self.capture()
        }
    }
    
    open func stopRecording(){
        currentRecordingProgress = 0
        self.timerRecording?.invalidate()
        
        guard let camera = camera else { return }
        camera.stopRecording()
    }
    
    @objc private func endRecording(){
        guard let camera = camera else { return }
        camera.stopRecording()
        self.timerRecording?.invalidate()
        currentRecordingProgress = 0
        guard let recordButton = recordButton else{ return }
        recordButton.setProgress(currentRecordingProgress)
    }
    
    open func record(){
        do {
            let docDir  = try FileManager.default.url(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
            var fileURL = docDir.appendingPathComponent("JDGCameraTemp")
            
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
                delegate.jdg_cameraDidRecord(cameraController:self, url, error)
                
            })
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}
