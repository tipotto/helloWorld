//
//  AudioViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/28.
//

import Foundation
import IQAudioRecorderController

class AudioViewController {
    
    var delegate: IQAudioRecorderViewControllerDelegate
    
    init(delegate: IQAudioRecorderViewControllerDelegate) {
        self.delegate = delegate
    }
    
    func presentAudioRecorder(target: UIViewController) {
        
        let controller = IQAudioRecorderViewController()
        
        controller.delegate = delegate
        controller.title = "Record"
        controller.maximumRecordDuration = 120.0
        controller.allowCropping = true
//        controller.audioQuality = .high
        
        target.presentBlurredAudioRecorderViewControllerAnimated(controller)
    }
    
}
