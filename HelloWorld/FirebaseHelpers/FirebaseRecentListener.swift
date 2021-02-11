//
//  FirebaseRecentListener.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/14.
//

import Foundation
import Firebase

class FirebaseRecentListener {
    
    static let shared = FirebaseRecentListener()
    
    private init() {}
    
    func downloadRecentChatsFromFireStore(completion: @escaping (_ allRecents: [RecentChat]) -> Void) {
        
        FirebaseReference(.Recent).whereField(kSENDERID, isEqualTo: User.currentId).addSnapshotListener { (snapshot, error) in
            
            var recentChats: [RecentChat] = []
            
            guard let documents = snapshot?.documents else {
                print("No documents for recent chats")
                return
            }
            
            let allRecents = documents.compactMap {
                try? $0.data(as: RecentChat.self)
            }
            
            for recent in allRecents {
                if recent.lastMessage.isEmpty { continue }
                recentChats.append(recent)
            }
            
            recentChats.sort { $0.date! > $1.date! }
            completion(recentChats)
            
        }
    }
    
    func updateRecents(chatRoomId: String, lastMessage: String) {
        
        // 
        FirebaseReference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { [weak self] (snapshot, error) in
            
            guard let documents = snapshot?.documents else {
                print("No document for recent update")
                return
            }
            
            let allRecents = documents.compactMap {
                try? $0.data(as: RecentChat.self)
            }
            
            for recent in allRecents {
                self?.updateRecentWithNewMessage(recent: recent, lastMessage: lastMessage)
            }
            
        }
    }
    
    private func updateRecentWithNewMessage(recent: RecentChat, lastMessage: String) {

        var recent = recent
        if recent.senderId != User.currentId {
            recent.unreadCounter += 1
        }
        
        recent.lastMessage = lastMessage
        recent.date = Date()
        saveRecent(recent)
    }
    
    // 特定のチャットルームに入室する時点で実行することを想定
    // 特定のRecentを引数にとっているため
    func clearUnreadCounter(recent: RecentChat) {
        var newRecent = recent
        newRecent.unreadCounter = 0
        saveRecent(newRecent)
    }
    
    // チャットルームから退出する時点で実行することを想定
    func resetRecentCounter(chatRoomId: String) {
        FirebaseReference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).whereField(kSENDERID, isEqualTo: User.currentId).getDocuments { [weak self] (snapshot, error) in
            guard let document = snapshot?.documents else {
                print("No documents for recent")
                return
            }
            
            let allRecents = document.compactMap { snapshot -> RecentChat? in
                return try? snapshot.data(as: RecentChat.self)
            }
            
//            let allRecents = document.compactMap {
//                try? $0.data(as: RecentChat.self)
//            }
            
            if allRecents.count <= 0 { return }
            self?.clearUnreadCounter(recent: allRecents.first!)
        }
    }
    
    func saveRecent(_ recent: RecentChat) {
        do {
            try FirebaseReference(.Recent).document(recent.id).setData(from: recent)
            
        } catch {
            print("Error saving recent", error.localizedDescription)
        }
    }
    
    func deleteRecent(_ recent: RecentChat) {
        FirebaseReference(.Recent).document(recent.id).delete()
    }
}
