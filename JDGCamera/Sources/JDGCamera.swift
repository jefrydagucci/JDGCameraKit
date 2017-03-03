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

class JDGCamera: UIViewController {
    
    let toolbarView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LLSimpleCamera.requestPermission { (permitted) in
            if(permitted){
                if let camera = LLSimpleCamera( quality: AVCaptureSessionPresetMedium, position: LLCameraPositionRear, videoEnabled: true){
                    let bound = UIScreen.main.bounds
                    camera.attach(to: self, withFrame: CGRect( x: 0, y: 0, width: bound.size.width, height: bound.size.height))
                    camera.start()
                    
                    self.setupBottomToolbar()
                    camera.view.sendSubview(toBack: self.toolbarView)
                }
                
            }
        }
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
    }
    
    func setupRecordingButton(){
        let frame = CGRect( x: 0, y: 0, width: 60, height: 60)
        let btn = SDRecordButton(frame: frame)
        btn.buttonColor = UIColor.blue
        
        if !toolbarView.subviews.contains(btn){
            toolbarView.addSubview(btn)
        }
        
        let toolbarFrame = toolbarView.frame
        let centerX = toolbarFrame.size.width/2
        let centerY = toolbarFrame.size.height/2
        btn.center  = CGPoint( x: centerX, y: centerY)
    }
    
}
