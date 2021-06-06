//
//  InputBarAccessoryViewDelegate.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/17.
//

import Foundation
import InputBarAccessoryView

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    // InputTextBarに文字を入力する度に実行
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        
        if !text.isEmpty {
//            updateTypingIndicator()
        }
        
        updateMicButtonStatus(show: text.isEmpty)
    }
    
    // 送信ボタンをクリックした時に実行
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        for component in inputBar.inputTextView.components {
            guard let text = component as? String else { continue }
            
            sendMessage(text: text, photo: nil, video: nil, location: nil, coordinate: nil, audio: nil)
        }
        
        // 送信テキストをクリア
        messageInputBar.inputTextView.text = ""
        messageInputBar.invalidatePlugins()
    }
}

extension ChannelChatViewController: InputBarAccessoryViewDelegate {
    
    // InputTextBarに文字を入力する度に実行
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        
//        if !text.isEmpty {
//            updateTypingIndicator()
//        }
        
        updateMicButtonStatus(show: text.isEmpty)
    }
    
    // 送信ボタンをクリックした時に実行
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        for component in inputBar.inputTextView.components {
            guard let text = component as? String else { continue }
            
            sendMessage(text: text, photo: nil, video: nil, location: nil, coordinate: nil, audio: nil)
        }
        
        // 送信テキストをクリア
        messageInputBar.inputTextView.text = ""
        messageInputBar.invalidatePlugins()
    }
}
