//
//  AudioRecorder.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/28.
//

import Foundation
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
//    var isAudioRecordingGranted: Bool!
    var isAudioRecordingGranted = false
    
    static let shared = AudioRecorder()
    
    private override init() {
        super.init()
        print("### init start ###")
        checkForRecordPermission()
    }
    
    func checkForRecordPermission() {
        
        let permissionType = AVAudioSession.sharedInstance().recordPermission
        
        switch permissionType {
        case .granted:
            isAudioRecordingGranted = true
        case .denied:
            isAudioRecordingGranted = false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] isAllowed in
                self?.isAudioRecordingGranted = isAllowed
            }
        default:
            break
        }
    }
    
    func setupRecorder() {
        if !isAudioRecordingGranted { return }
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
        } catch {
            print("error setting up audio recorder", error.localizedDescription)
        }
    }
    
    func startRecording(fileName: String) {
        
        let audioFileName = getDocumentsURL().appendingPathComponent(fileName + ".m4a", isDirectory: false)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch {
            print("Error recording", error.localizedDescription)
            finishRecording()
        }
    }
    
    func finishRecording() {
        if audioRecorder == nil { return }
        audioRecorder.stop()
        audioRecorder = nil
    }
}
