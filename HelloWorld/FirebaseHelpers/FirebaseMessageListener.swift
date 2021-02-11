//
//  FirebaseMessageListener.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/18.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class FirebaseMessageListener {
    
    static let shared = FirebaseMessageListener()
    var newChatListener: ListenerRegistration!
    var updatedChatListener: ListenerRegistration!
    
    private init() {}
    
    // documentId: userId
    // collectionId: chatId
    func listenForNewChats(_ documentId: String, collectionId: String, lastMessageDate: Date) {
        
        newChatListener = FirebaseReference(.Messages).document(documentId).collection(collectionId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener { (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            for change in snapshot.documentChanges {
                if change.type != .added { continue }
                print("New document is added")
                
                let result = Result {
                    try? change.document.data(as: LocalMessage.self)
                }
                
                switch result {
                case .success(let message):
                    guard let message = message else { break }
                    
                    // Outgoing ModelのsendMessageメソッド
                    // Outgoingメッセージは、送信時にローカルストレージに保存済み
                    // そのため、ここではIncomingメッセージのみを保存する
                    if message.senderId == User.currentId { break }
                    
                    RealmManager.shared.saveToRealm(message)
                    print("Finish saving message to realm")
                    
                case .failure(let error):
                    print("error decoding local messages", error.localizedDescription)
                }
            }
        }
    }
    
    func listenForReadStatusChange(_ documentId: String, collectionId: String, completion: @escaping (_ updatedMessage: LocalMessage) -> Void) {
        
        updatedChatListener = FirebaseReference(.Messages).document(documentId).collection(collectionId).addSnapshotListener { (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            for change in snapshot.documentChanges {
                if change.type != .modified { continue }
                
                print("detect read status change")
                
                let result = Result {
                    try? change.document.data(as: LocalMessage.self)
                }
                
                switch result {
                case .success(let message):
                    guard let message = message else {
                        print("Document does not exist in chat")
                        break
                    }
                    completion(message)
                    
                case .failure(let error):
                    print("Error decoding local message", error.localizedDescription)
                }
            }
        }
    }
    
    // documentId: userId
    // collectionId: chatRoomId
    // 通常系とソート方法が異なるからか、全てのメッセージに「sent」ステータスが表示される。
    func checkForOldChats(_ documentId: String, collectionId: String) {
        print("Checking for old chats...")
        FirebaseReference(.Messages).document(documentId).collection(collectionId).getDocuments { (snapshot, error) in
            
            guard let documents = snapshot?.documents else {
                print("No documents for old chats")
                return
            }
            
//            var oldMessages = documents.compactMap { (snapshot) -> LocalMessage? in
//                return try? snapshot.data(as: LocalMessage.self)
//            }
            
            var oldMessages = documents.compactMap {
                try? $0.data(as: LocalMessage.self)
            }
            
            oldMessages.sort { $0.date < $1.date }
            
            for message in oldMessages {
                print("Save old chats to realm")
                RealmManager.shared.saveToRealm(message)
            }
            
        }
    }
    
    // MARK: - Add, Update, Delete
    func addMessage(_ message: LocalMessage, memberId: String) {
        
        do {
            let _ = try FirebaseReference(.Messages).document(memberId).collection(message.chatRoomId).document(message.id).setData(from: message)
            
        } catch {
            print("error saving messages", error.localizedDescription)
        }
    }
    
    func addChannelMessage(_ message: LocalMessage, channel: Channel) {
        
        do {
            let _ = try FirebaseReference(.Messages).document(channel.id).collection(channel.id).document(message.id).setData(from: message)
            
        } catch {
            print("error saving messages", error.localizedDescription)
        }
    }
    
    // MARK: - Update Message Status
    func updateMessageInFirebase(_ message: LocalMessage, memberIds: [String]) {
        let values = [kSTATUS: kREAD, kREADDATE: Date()] as [String: Any]
        
        for userId in memberIds {
            FirebaseReference(.Messages).document(userId).collection(message.chatRoomId).document(message.id).updateData(values)
        }
    }
    
    func removeListeners() {
        newChatListener.remove()
        
        if updatedChatListener != nil {
            updatedChatListener.remove()
        }
    }
    
}
