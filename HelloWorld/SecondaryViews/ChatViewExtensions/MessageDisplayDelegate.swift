//
//  MessageDisplayDelegate.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/17.
//

import Foundation
import MessageKit

extension ChatViewController: MessagesDisplayDelegate {
    
    // メッセージのテキストカラー
    // デバイスのモード（Light/Dark）に合わせて変更
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return .label
    }
    
    // メッセージのバックグラウンドカラー
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? MessageDefaults.bubbleColorOutgoing : MessageDefaults.bubbleColorIncoming
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        
        return .bubbleTail(tail, .curved)
    }
}

extension ChannelChatViewController: MessagesDisplayDelegate {
    
    // メッセージのテキストカラー
    // デバイスのモード（Light/Dark）に合わせて変更
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return .label
    }
    
    // メッセージのバックグラウンドカラー
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? MessageDefaults.bubbleColorOutgoing : MessageDefaults.bubbleColorIncoming
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        
        return .bubbleTail(tail, .curved)
    }
}
