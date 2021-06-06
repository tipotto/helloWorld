//
//  MessageCellDelegate.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/17.
//

import Foundation
import MessageKit
import AVFoundation
import AVKit
import SKPhotoBrowser

extension ChatViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar is tapped...")
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let mkSender = mkMessages[indexPath.section].mkSender
        
        FirebaseUserListener.shared.fetchUserFromFirebase(userId: mkSender.senderId) { [weak self] user in
            
            let profileView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ProfileView") as! ProfileTableViewController
            
            profileView.user = user
            self?.navigationController?.pushViewController(profileView, animated: true)
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        
        let mkMessage = mkMessages[indexPath.section]
        
        if mkMessage.photoItem != nil && mkMessage.photoItem!.image != nil {
            var images = [SKPhoto]()
            let photo = SKPhoto.photoWithImage(mkMessage.photoItem!.image!)
            images.append(photo)
            
            let browser = SKPhotoBrowser(photos: images)
            browser.initializePageIndex(0)
            present(browser, animated: true)
        }
        
        if mkMessage.videoItem != nil && mkMessage.videoItem!.url != nil {
            let player = AVPlayer(url: mkMessage.videoItem!.url!)
            let moviePlayer = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            
            try? session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            
            moviePlayer.player = player
            
            present(moviePlayer, animated: true) {
                moviePlayer.player!.play()
            }
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        if let indexPath = messagesCollectionView.indexPath(for: cell) {
            let mkMessage = mkMessages[indexPath.section]
            if mkMessage.locationItem == nil { return }
            
            let mapView = MapViewController()
            mapView.location = mkMessage.locationItem!.location
            navigationController?.pushViewController(mapView, animated: true)
        }
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }
}

extension ChannelChatViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar is tapped...")
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let mkSender = mkMessages[indexPath.section].mkSender
        
        FirebaseUserListener.shared.fetchUserFromFirebase(userId: mkSender.senderId) { [weak self] user in
            
            let profileView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ProfileView") as! ProfileTableViewController
            
            profileView.user = user
            self?.navigationController?.pushViewController(profileView, animated: true)
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        
        let mkMessage = mkMessages[indexPath.section]
        
        if mkMessage.photoItem != nil && mkMessage.photoItem!.image != nil {
            var images = [SKPhoto]()
            let photo = SKPhoto.photoWithImage(mkMessage.photoItem!.image!)
            images.append(photo)
            
            let browser = SKPhotoBrowser(photos: images)
            browser.initializePageIndex(0)
            present(browser, animated: true)
        }
        
        if mkMessage.videoItem != nil && mkMessage.videoItem!.url != nil {
            let player = AVPlayer(url: mkMessage.videoItem!.url!)
            let moviePlayer = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            
            try? session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            
            moviePlayer.player = player
            
            present(moviePlayer, animated: true) {
                moviePlayer.player!.play()
            }
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        if let indexPath = messagesCollectionView.indexPath(for: cell) {
            let mkMessage = mkMessages[indexPath.section]
            if mkMessage.locationItem == nil { return }
            
            let mapView = MapViewController()
            mapView.location = mkMessage.locationItem!.location
            navigationController?.pushViewController(mapView, animated: true)
        }
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }
}
