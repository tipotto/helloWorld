//
//  IncomingMessage.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/18.
//

import Foundation
import MessageKit
import CoreLocation

class IncomingMessage {
    
    var messageCollectionView: MessagesViewController
    
    init(_ collectionView: MessagesViewController) {
        messageCollectionView = collectionView
    }
    
    // MARK: - Create Message
    func createMessage(localMessage: LocalMessage) -> MKMessage? {
        
        let mkMessage = MKMessage(message: localMessage)
        
        if localMessage.type == kPHOTO {
            
            let photoItem = PhotoMessage(path: localMessage.pictureUrl)
            
            mkMessage.photoItem = photoItem
            mkMessage.kind = MessageKind.photo(photoItem)
            
            FileStorage.downloadImage(imageUrl: localMessage.pictureUrl) { [weak self] image in
                mkMessage.photoItem?.image = image
                self?.messageCollectionView.messagesCollectionView.reloadData()
            }
        }
        
        if localMessage.type == kVIDEO {
            FileStorage.downloadImage(imageUrl: localMessage.pictureUrl) { [weak self] thumbNail in
                FileStorage.downloadVideo(videoUrl: localMessage.videoUrl) { (isReadyToPlay, fileName) in
                    
                    let videoUrl = URL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
                    
                    let videoItem = VideoMessage(url: videoUrl)
                    mkMessage.videoItem = videoItem
                    mkMessage.kind = MessageKind.video(videoItem)
                }
                
                mkMessage.videoItem?.image = thumbNail
                self?.messageCollectionView.messagesCollectionView.reloadData()
            }
        }
        
        if localMessage.type == kLOCATION {
            let location = CLLocation(latitude: localMessage.latitude, longitude: localMessage.longitude)
            let locationItem = LocationMessage(location: location)
            mkMessage.kind = MessageKind.location(locationItem)
            mkMessage.locationItem = locationItem
        }
        
        if localMessage.type == kAUDIO {
            let audio = AudioMessage(duration: Float(localMessage.audioDuration))
            mkMessage.audioItem = audio
            mkMessage.kind = MessageKind.audio(audio)
            
            FileStorage.downloadAudio(audioUrl: localMessage.audioUrl) { fileName in
                let localFilePath = fileInDocumentsDirectory(fileName: fileName)
                let audioUrl = URL(fileURLWithPath: localFilePath)
                mkMessage.audioItem?.url = audioUrl
            }
            messageCollectionView.messagesCollectionView.reloadData()
        }
        
        return mkMessage
    }
}
