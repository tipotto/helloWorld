//
//  MKMessage.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/17.
//

import Foundation
import MessageKit
import CoreLocation

class MKMessage: NSObject, MessageType {
    
    var messageId: String
    var kind: MessageKind
    var sentDate: Date
    var incoming: Bool
    var mkSender: MKSender
    
    // mkSender（MKSender）はSenderTypeプロトコルを継承している
    var sender: SenderType { return mkSender }
    var senderInitials: String
    var status: String
    var readDate: Date
    
    var photoItem: PhotoMessage?
    var videoItem: VideoMessage?
    var locationItem: LocationMessage?
    var audioItem: AudioMessage?
    
    init(message: LocalMessage) {
        messageId = message.id
        mkSender = MKSender(senderId: message.senderId, displayName: message.senderName)
        status = message.status
        kind = MessageKind.text(message.message)
        senderInitials = message.senderInitials
        sentDate = message.date
        readDate = message.readDate
        incoming = User.currentId != message.senderId
        
        switch message.type {
        case kTEXT:
            kind = MessageKind.text(message.message)
            
        case kPHOTO:
            let photo = PhotoMessage(path: message.pictureUrl)
            kind = MessageKind.photo(photo)
            photoItem = photo
            
        case kVIDEO:
            let video = VideoMessage(url: nil)
            kind = MessageKind.video(video)
            videoItem = video
            
        case kLOCATION:
            let location = LocationMessage(location: CLLocation(latitude: message.latitude, longitude: message.longitude))
            kind = MessageKind.location(location)
            locationItem = location
            
        case kAUDIO:
            let audio = AudioMessage(duration: 2.0)
            kind = MessageKind.audio(audio)
            audioItem = audio
            
        default:
            kind = MessageKind.text(message.message)
            print("unknown message type")
        }
    }
}
