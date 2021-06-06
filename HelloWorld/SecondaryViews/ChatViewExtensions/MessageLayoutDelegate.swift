//
//  MessageLayoutDelegate.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/17.
//

import Foundation
import MessageKit

extension ChatViewController: MessagesLayoutDelegate {
    
    // MARK: - Cell Top Label
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        if indexPath.section % 3 != 0 { return 0 }
        if (indexPath.section == 0) && (allLocalMessages.count > displayingMessagesCount) {
            return 40
        }
        return 35
    }
    
    // MARK: - Cell Bottom Label
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        return isFromCurrentSender(message: message) ? 17 : 0
        return isFromCurrentSender(message: message) ? 10 : 0
    }
    
    // MARK: - Message Bottom Label
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        return indexPath.section != mkMessages.count - 1 ? 17 : 0
        return 5
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

        let initials = mkMessages[indexPath.section].senderInitials
        avatarView.set(avatar: Avatar(initials: initials))
    }
}

extension ChannelChatViewController: MessagesLayoutDelegate {
    
    // MARK: - Cell Top Label
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        if indexPath.section % 3 != 0 { return 0 }
        if (indexPath.section == 0) && (allLocalMessages.count > displayingMessagesCount) {
            return 40
        }
        return 35
    }
    
    // MARK: - Cell Bottom Label
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        return isFromCurrentSender(message: message) ? 17 : 0
        return isFromCurrentSender(message: message) ? 10 : 0
    }
    
    // MARK: - Message Bottom Label
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        // 最新のメッセージにもタイムスタンプを表示するためにコメントアウト
        // 最新のメッセージにはStatus + タイムスタンプを表示する場合は以下を追加
//        return indexPath.section != mkMessages.count - 1 ? 17 : 0
        return 5
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let initials = mkMessages[indexPath.section].senderInitials
        avatarView.set(avatar: Avatar(initials: initials))
        
        
    }
}
