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
    
    var defaultRecordButtonColor:UIColor = UIColor.clear
    var defaultRecordButtonImage:UIImage?
    
    var defaultCaptureButtonImage:UIImage?
    
    var recordButton:SDRecordButton?
    var captureButton:UIButton?
    
    var captureButtonWidth  = 70
    
    var cameraPosition:LLCameraPosition = LLCameraPositionRear
    var cameraDelegate:JDGCameraDelegate?
    
    private var camera:LLSimpleCamera?
    
    private var timerRecording:Timer?
    
    private let progressTimeRepeatingValue:CGFloat  = 0.05
    var maximumRecordingDuration:CGFloat    = 60
    
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
                            
                            self.setupBottomToolbar()
                            camera.view.sendSubview(toBack: self.toolbarView)
                            self.camera = camera
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
    
    func setupBottomToolbarView(){
        let screenBound = UIScreen.main.bounds
        let height:CGFloat = 120
        toolbarView.frame = CGRect( x: 0, y: screenBound.size.height - height, width: screenBound.size.width, height: height)
        toolbarView.autoresizingMask    = [.flexibleWidth, .flexibleBottomMargin]
        
        if !self.view.subviews.contains(toolbarView){
            self.view.addSubview(toolbarView)
        }
    }
    
    func setupButton(){
        self.setupRecordingButton()
        self.setupButtonAction()
    }
    
    @objc private func setupRecordingButton(){
        let frame = CGRect( x: 0, y: 0, width: captureButtonWidth, height: captureButtonWidth)
        let btn = SDRecordButton(frame: frame)
        captureButton = UIButton(frame: frame)
        btn.buttonColor = defaultRecordButtonColor
        if let btnImg = defaultRecordButtonImage{
            btn.buttonColor = UIColor.clear
            btn.setImage(btnImg, for: .normal)
        }
        
        recordButton = btn
        
        if !toolbarView.subviews.contains(btn){
            toolbarView.addSubview(btn)
        }
        
        let toolbarFrame = toolbarView.frame
        let centerX = toolbarFrame.size.width/2
        let centerY = toolbarFrame.size.height/2
        btn.center  = CGPoint( x: centerX, y: centerY)
        
        guard let captureButton = captureButton else{ return }
        captureButton.layer.cornerRadius    = captureButton.frame.size.width * 0.5
        captureButton.layer.masksToBounds   = true
        captureButton.setBackgroundImage(Ionicons.iosCircleFilled.image(captureButton.frame.size.width).add_tintedImage(with: .white, style: ADDImageTintStyleKeepingAlpha), for: .normal)
        if let btnImg = defaultCaptureButtonImage{
            captureButton.setImage(btnImg, for: .normal)
        }
        if !toolbarView.subviews.contains(captureButton){
            toolbarView.addSubview(captureButton)
        }
        captureButton.center = btn.center
    }
    
    @objc private func setupButtonAction(){
        if let captureButton = captureButton{
            let longPress = UILongPressGestureRecognizer( target: self, action: #selector(captureLongPress))
            longPress.minimumPressDuration  = 1.5
            longPress.numberOfTapsRequired  = 1
            
            captureButton.addGestureRecognizer(longPress)
            captureButton.addTarget(self, action: #selector(capture), for: .touchUpInside)
        }
        if let recordButton     = recordButton{
            recordButton.addTarget(self, action: #selector(startRecording), for: .touchDown)
            recordButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
            recordButton.addTarget(self, action: #selector(stopRecording), for: .touchUpOutside)
        }
    }
    
//    MARK:Timer
    func startRecordingTimer(){
        if let timer = timerRecording{
            timer.fire()
        }
        else{
            if #available(iOS 10.0, *) {
                timerRecording  = Timer( timeInterval: TimeInterval(progressTimeRepeatingValue), repeats: true, block: { (timer:Timer) in
                    self.updateRecordingProgress()
                })
            } else {
                timerRecording  = Timer( timeInterval: TimeInterval(progressTimeRepeatingValue), target: self, selector: #selector(updateRecordingProgress), userInfo: nil, repeats: true)
            }
        }
    }
    
    @objc private func updateRecordingProgress(){
        guard let btn = recordButton else{ return }
        btn.setProgress(progressTimeRepeatingValue/maximumRecordingDuration)
    }
    
//    MARK:Action
    
    @objc private func captureLongPress(){
        if let captureButton    = captureButton{
            captureButton.sendActions(for: .touchUpOutside)
        }
        if let recordButton     = recordButton{
            recordButton.sendActions(for: .touchDown)
        }
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
    
    func stopRecording(){
        guard let camera = camera else { return }
        camera.stopRecording()
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
            if(!camera.isRecording){
                camera.startRecording(withOutputUrl: videoFilePath, didRecord: { (camera:LLSimpleCamera?, url:URL?, error:Error?) in
                    
                    guard let delegate = self.cameraDelegate else{ return }
                    delegate.jdg_cameraDidRecord(url, error)
                })
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}
