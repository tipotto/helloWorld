//
//  GlobalFunctions.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import Foundation
import UIKit
import AVFoundation

func fileNameFrom(fileUrl: String) -> String? {
    
    guard let shortUrl = fileUrl.components(separatedBy: "_").last else {
        return nil
    }
    
    guard let fileName = shortUrl.components(separatedBy: "?").first else {
        return nil
    }
    
    return fileName.components(separatedBy: ".").first
}

func timeElapsed(_ date: Date) -> String {
    
    let seconds = Date().timeIntervalSince(date)
    var elapsed = ""
    
    // 1分未満の場合
    if seconds < 60 {
        elapsed = "Just now"
    
    // 1時間（60分）未満の場合
    } else if seconds < 60 * 60 {
        let minutes = Int(seconds / 60)
        let minText = minutes > 1 ? "mins" : "min"
        elapsed = "\(minutes) \(minText) ago"
    
    // 1日（24時間）未満の場合
    } else if seconds < 60 * 60 * 24 {
        let hours = Int(seconds / (60 * 60))
        let hourText = hours > 1 ? "hours" : "hour"
        elapsed = "\(hours) \(hourText) ago"
    
    // 1日（24時間）以上の場合
    } else {
        elapsed = date.longDate()
    }
    
    return elapsed
}

func videoThumbnail(videoUrl: URL) -> UIImage {
    let asset = AVURLAsset(url: videoUrl)
    
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    
    var image: CGImage?
    
    do {
        image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
    
    } catch let error as NSError {
        print("Error making thumbnail", error.localizedDescription)
    }
    
    guard image != nil else {
        return UIImage(named: "photoPlaceholder")!
    }
    
    return UIImage(cgImage: image!)
}
