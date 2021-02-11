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
    
    class func send(chatId: String, text: String?, photo: UIImage?, video: Video?, location: String?, coordinate: CLLocationCoordinate2D? ,audio: String?, audioDuration: Float = 0.0, memberIds: [String]) {
        
        guard let currentUser = User.currentUser else { return }
        
        let message = LocalMessage()
        message.id = UUID().uuidString
        message.chatRoomId = chatId
        message.senderId = currentUser.id
        message.senderName = currentUser.username
        message.senderInitials = String(currentUser.username.first!)
        message.date = Date()
        message.status = kSENT
        
        if text != nil {
            sendTextMessage(message: message, text: text!, memberIds: memberIds)
        }
        
        if photo != nil {
            sendPictureMessage(message: message, photo: photo!, memberIds: memberIds)
        }

        if video != nil {
            sendVideoMessage(message: message, video: video!, memberIds: memberIds)
        }
        
        if location != nil {
            sendLocationMessage(message: message, coordinate: coordinate, memberIds: memberIds)
        }
        
        if audio != nil {
            sendAudioMessage(message: message, filePath: audio!, duration: audioDuration, memberIds: memberIds)
        }
        
        // TODO: send push notification
        // TODO: update recent
        FirebaseRecentListener.shared.updateRecents(chatRoomId: chatId, lastMessage: message.message)
        
    }
    
    class func sendMessage(message: LocalMessage, memberIds: [String]) {
        // Realmに保存
        RealmManager.shared.saveToRealm(message)
        
        for id in memberIds {
            // Firestoreに保存
            FirebaseMessageListener.shared.addMessage(message, memberId: id)
        }
    }
    
    class func sendChannelMessage(message: LocalMessage, channel: Channel) {
        // Realmに保存
        RealmManager.shared.saveToRealm(message)
        FirebaseMessageListener.shared.addChannelMessage(message, channel: channel)
    }
    
    class func sendChannel(channel: Channel, text: String?, photo: UIImage?, video: Video?, location: String?, coordinate: CLLocationCoordinate2D? ,audio: String?, audioDuration: Float = 0.0) {
        
        guard let currentUser = User.currentUser else { return }
        var channel = channel
        
        let memberIds = channel.memberIds
        let message = LocalMessage()
        message.id = UUID().uuidString
        message.chatRoomId = channel.id
        message.senderId = currentUser.id
        message.senderName = currentUser.username
        message.senderInitials = String(currentUser.username.first!)
        message.date = Date()
        message.status = kSENT
        
        if text != nil {
            sendTextMessage(message: message, text: text!, memberIds: memberIds, channel: channel)
        }
        
        if photo != nil {
            sendPictureMessage(message: message, photo: photo!, memberIds: memberIds)
        }

        if video != nil {
            sendVideoMessage(message: message, video: video!, memberIds: memberIds)
        }
        
        if location != nil {
            sendLocationMessage(message: message, coordinate: coordinate, memberIds: memberIds)
        }
        
        if audio != nil {
            sendAudioMessage(message: message, filePath: audio!, duration: audioDuration, memberIds: memberIds)
        }
        
        // Send push notifications
        
        channel.lastMessageDate = Date()
        FirebaseChannelListener.shared.saveChannel(channel)
        
    }
}

func sendTextMessage(message: LocalMessage, text: String, memberIds: [String], channel: Channel? = nil) {
    message.message = text
    message.type = kTEXT
    
    if channel != nil {
        OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
        
    } else {
        OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
    }
}

func sendPictureMessage(message: LocalMessage, photo: UIImage, memberIds: [String], channel: Channel? = nil) {
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
        
        if channel != nil {
            OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
            
        } else {
            OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
        }
    }
}

func sendVideoMessage(message: LocalMessage, video: Video, memberIds: [String], channel: Channel? = nil) {
    
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
                
                if channel != nil {
                    OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
                    
                } else {
                    OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
                }

            }
        }
    }
}

func sendLocationMessage(message: LocalMessage, coordinate: CLLocationCoordinate2D?, memberIds: [String], channel: Channel? = nil) {

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
    
    if channel != nil {
        OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
        
    } else {
        OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
    }
}

func sendAudioMessage(message: LocalMessage, filePath: String, duration: Float, memberIds: [String], channel: Channel? = nil) {

    message.message = "Audio message"
    message.type = kAUDIO
    let fileName = Date().stringDate()
    let fileDirectory = "MediaMessages/Audio/\(message.chatRoomId)/_\(fileName).m4a"
    
    FileStorage.uploadAudio(filePath, fileName: fileName, directory: fileDirectory) { audioUrl in
        
        guard let url = audioUrl else { return }
        message.audioUrl = url
        message.audioDuration = Double(duration)
        
        if channel != nil {
            OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
            
        } else {
            OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
        }
    }
}
