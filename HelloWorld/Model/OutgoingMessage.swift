//
//  OutgoingMessage.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/18.
//

import Foundation
import UIKit
import FirebaseFirestoreSwift
import Gallery
import CoreLocation

class OutgoingMessage {
    
    class func send(roomId: String, text: String?, photo: UIImage?, video: Video?, location: String?, coordinate: CLLocationCoordinate2D? ,audio: String?, audioDuration: Float = 0.0, recipientInfo: [String: String] = [:]) {
        
        guard let currentUser = User.currentUser else { return }
        
        let message = LocalMessage()
        message.id = UUID().uuidString
        message.chatRoomId = roomId
        message.senderId = currentUser.id
        message.senderName = currentUser.name
        message.senderLang = currentUser.lang
        message.senderInitials = String(currentUser.name.first!)
        message.date = Date()
        
        if text != nil {
            sendTextMessage(message: message, text: text!, recipientInfo: recipientInfo)
        }
        
        if photo != nil {
            sendPictureMessage(message: message, photo: photo!, recipientInfo: recipientInfo)
        }

        if video != nil {
            sendVideoMessage(message: message, video: video!, recipientInfo: recipientInfo)
        }
        
        if location != nil {
            sendLocationMessage(message: message, coordinate: coordinate, recipientInfo: recipientInfo)
        }
        
        if audio != nil {
            sendAudioMessage(message: message, filePath: audio!, duration: audioDuration, recipientInfo: recipientInfo)
        }
        
        // TODO: send push notification
        
    }
    
    class func sendMessage(message: LocalMessage, recipientInfo: [String: String]) {
        // Realmに保存
        RealmManager.shared.save(message)

        // Firestoreに保存
        if recipientInfo.isEmpty {
            FirebaseMessageListener.shared.createChannelMessage(message)
        
        } else {
            FirebaseMessageListener.shared.createMessage(message, recipientInfo: recipientInfo)
        }
    }
}



func sendTextMessage(message: LocalMessage, text: String, recipientInfo: [String: String] = [:]) {
    
    message.message = text
    message.type = kTEXT
    OutgoingMessage.sendMessage(message: message, recipientInfo: recipientInfo)
}

func sendPictureMessage(message: LocalMessage, photo: UIImage, recipientInfo: [String: String] = [:]) {
    
    print("sending photo message...")
    
    message.message = "Picture Message"
    message.type = kPHOTO
    
    let fileName = Date().stringDate()
    let fileDirectory = "MediaMessages/Photo/\(message.chatRoomId)/_\(fileName).jpg"
    
    // 画像（UIImage）をjpegに変換
    guard let jpegData = photo.jpegData(compressionQuality: 0.6) else { return }
    
    // iPhoneのDocumentsディレクトリに保存
    FileStorage.saveFileLocally(fileData: jpegData as NSData, fileName: fileName)
    
    // Firebase Storageに保存し、保存先のURLをダウンロード
    FileStorage.uploadImage(photo, directory: fileDirectory) { imageUrl in
        guard let url = imageUrl else { return }
        message.pictureUrl = url
        
        OutgoingMessage.sendMessage(message: message, recipientInfo: recipientInfo)
    }
}

func sendVideoMessage(message: LocalMessage, video: Video, recipientInfo: [String: String] = [:]) {
    
    message.message = "Video Message"
    message.type = kVIDEO
    
    let fileName = Date().stringDate()
    let thumbnailDirectory = "MediaMessages/Photo/\(message.chatRoomId)/_\(fileName).jpg"
    let videoDirectory = "MediaMessages/Video/\(message.chatRoomId)/_\(fileName).mov"
    
    let editor = VideoEditor()
    editor.process(video: video) { (processedVideo, videoUrl) in
        guard let url = videoUrl else { return }
        let thumbnail = videoThumbnail(videoUrl: url)
        guard let jpegThumbnail = thumbnail.jpegData(compressionQuality: 0.7) else { return }
        
        // サムネイルをiPhoneのDocumentsフォルダに保存
        FileStorage.saveFileLocally(fileData: jpegThumbnail as NSData, fileName: fileName)
        
        // サムネイルをFirebase Storageに保存し、保存先のURLを取得
        FileStorage.uploadImage(thumbnail, directory: thumbnailDirectory) { imageLink in
            
            guard let videoData = NSData(contentsOfFile: url.path) else { return }
            
            // 動画データをiPhoneのDocumentsフォルダに保存
            FileStorage.saveFileLocally(fileData: videoData, fileName: "\(fileName).mov")
            
            // 動画データをFirebase Storageに保存し、保存先のURLを取得
            FileStorage.uploadVideo(videoData, directory: videoDirectory) { videoLink in
                message.pictureUrl = imageLink ?? ""
                message.videoUrl = videoLink ?? ""
                
                OutgoingMessage.sendMessage(message: message, recipientInfo: recipientInfo)
            }
        }
    }
}

func sendLocationMessage(message: LocalMessage, coordinate: CLLocationCoordinate2D?, recipientInfo: [String: String] = [:]) {

    var currentLocation: CLLocationCoordinate2D?
    if coordinate != nil {
        currentLocation = coordinate!
        
    } else {
        currentLocation = LocationManager.shared.currentLocation
    }
    
    message.message = "Location message"
    message.type = kLOCATION
    message.latitude = currentLocation?.latitude ?? 0.0
    message.longitude = currentLocation?.longitude ?? 0.0
    
    OutgoingMessage.sendMessage(message: message, recipientInfo: recipientInfo)
}

func sendAudioMessage(message: LocalMessage, filePath: String, duration: Float, recipientInfo: [String: String] = [:]) {

    message.message = "Audio message"
    message.type = kAUDIO
    let fileName = Date().stringDate()
    let fileDirectory = "MediaMessages/Audio/\(message.chatRoomId)/_\(fileName).m4a"
    
    FileStorage.uploadAudio(filePath, fileName: fileName, directory: fileDirectory) { audioUrl in
        
        guard let url = audioUrl else { return }
        message.audioUrl = url
        message.audioDuration = Double(duration)
        
        OutgoingMessage.sendMessage(message: message, recipientInfo: recipientInfo)
    }
}
