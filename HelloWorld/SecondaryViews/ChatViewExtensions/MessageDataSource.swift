//
//  MessageDataSource.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/17.
//

import Foundation
import MessageKit

extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        // currentUser（MKSender）はSenderTypeプロトコルを継承している
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        // 各messageはそれぞれ独立したsectionになっているため
        return mkMessages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mkMessages.count
    }
    
    // MARK: - Cell Top Labels
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        // メッセージ3つおきにラベルを表示する
        if indexPath.section % 3 != 0 { return nil }
        
        let showLoadMore = (indexPath.section == 0) && (allLocalMessages.count > displayingMessagesCount)
        let text = showLoadMore ? "Pull to load more" : MessageKitDateFormatter.shared.string(from: message.sentDate)
        let font = showLoadMore ? UIFont.systemFont(ofSize: 13) : UIFont.boldSystemFont(ofSize: 10)
        let color = showLoadMore ? UIColor.systemBlue : UIColor.darkGray
        
        return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    }
    
    // Cell Buttom Label
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isFromCurrentSender(message: message) { return nil }
        
        let message = mkMessages[indexPath.section]
        let status = message.readCounter == 1 ? "\(kREAD) \(message.readDate.time())" : ""
        let font = UIFont.boldSystemFont(ofSize: 10)
        let color = UIColor.darkGray
        
        return NSAttributedString(string: status, attributes: [.font: font, .foregroundColor: color])
    }
    
    // 最新のメッセージに対して、ステータスとタイムスタンプを表示
//    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        if !isFromCurrentSender(message: message) { return nil }
//
//        let message = mkMessages[indexPath.section]
//        let status = indexPath.section == mkMessages.count - 1 ? "\(message.status) \(message.readDate.time())" : ""
//        let font = UIFont.boldSystemFont(ofSize: 10)
//        let color = UIColor.darkGray
//
//        return NSAttributedString(string: status, attributes: [.font: font, .foregroundColor: color])
//    }
    
    // Message Buttom Label
    // 最新のメッセージ以外に対して、タイムスタンプを表示
//    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        if indexPath.section == mkMessages.count - 1 { return nil }
//
//        let time = message.sentDate.time()
//        let font = UIFont.boldSystemFont(ofSize: 10)
//        let color = UIColor.darkGray
//
//        return NSAttributedString(string: time, attributes: [.font: font, .foregroundColor: color])
//    }
}

extension ChannelChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        // currentUser（MKSender）はSenderTypeプロトコルを継承している
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        // 各messageはそれぞれ独立したsectionになっているため
        return mkMessages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mkMessages.count
    }
    
    // MARK: - Cell Top Labels
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        // メッセージ3つおきにラベルを表示する
        if indexPath.section % 3 != 0 { return nil }
        
        let showLoadMore = (indexPath.section == 0) && (allLocalMessages.count > displayingMessagesCount)
        let text = showLoadMore ? "Pull to load more" : MessageKitDateFormatter.shared.string(from: message.sentDate)
        let font = showLoadMore ? UIFont.systemFont(ofSize: 13) : UIFont.boldSystemFont(ofSize: 10)
        let color = showLoadMore ? UIColor.systemBlue : UIColor.darkGray
        
        return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    }
    
    // Cell Buttom Label
    // 最新のメッセージに対して、ステータス（Sent/Read）とタイムスタンプを表示
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isFromCurrentSender(message: message) { return nil }
        
        let message = mkMessages[indexPath.section]
        let status = message.readCounter >= 1 ? "\(kREAD)\(message.readCounter) \(message.readDate.time())" : ""
        let font = UIFont.boldSystemFont(ofSize: 10)
        let color = UIColor.darkGray
        
        return NSAttributedString(string: status, attributes: [.font: font, .foregroundColor: color])
    }
    
    // Message Buttom Label
    // 最新のメッセージ以外に対して、タイムスタンプを表示
//    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//
//        // 最新のメッセージにもタイムスタンプを表示するためにコメントアウト
//        // 最新のメッセージにはStatus + タイムスタンプを表示する場合は以下を追加
////        if indexPath.section == mkMessages.count - 1 { return nil }
//
//        let time = message.sentDate.time()
//        let font = UIFont.boldSystemFont(ofSize: 10)
//        let color = UIColor.darkGray
//
//        return NSAttributedString(string: time, attributes: [.font: font, .foregroundColor: color])
//    }
}
