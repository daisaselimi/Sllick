//
//  AudioViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 28.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Foundation
import IQAudioRecorderController

class AudioViewController {
    
    var delegate: IQAudioRecorderViewControllerDelegate
    
    init(delegate_: IQAudioRecorderViewControllerDelegate) {
        self.delegate = delegate_
    }
    
    func presentAudioRecorder(target: UIViewController) {
        let controller = IQAudioRecorderViewController()
        
        controller.delegate = delegate
        controller.title = "Record"
        controller.maximumRecordDuration = kAUDIOMAXDURATION
        controller.allowCropping = true
        controller.normalTintColor = UIColor.getAppColor(.dark)
        controller.highlightedTintColor = UIColor.getAppColor(.light)
        target.presentBlurredAudioRecorderViewControllerAnimated(controller)
    }
}
