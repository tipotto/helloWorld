//
//  FirebaseChannelListener.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/02.
//

import Foundation
import Firebase

class FirebaseChannelListener {
    static let shared = FirebaseChannelListener()
    var channelListener: ListenerRegistration!
    
    private init() {}
    
    // MARK: - Fetching
    func downloadUserChannels(completion: @escaping (_ channels: [Channel]) -> Void) {
        channelListener = FirebaseReference(.Channel).whereField(kADMINID, isEqualTo: User.currentId).addSnapshotListener { (snapshot, error) in
            
            guard let documents = snapshot?.documents else {
                print("No documents for user channels exist...")
                return
            }
            
            var channels = documents.compactMap {
                try? $0.data(as: Channel.self)
            }
            
            // チャンネルメンバーが多い順にソート
            channels.sort { $0.memberIds.count > $1.memberIds.count }
            completion(channels)
        }
    }
    
    func downloadSubscribedChannels(completion: @escaping (_ channels: [Channel]) -> Void) {
        channelListener = FirebaseReference(.Channel).whereField(kMEMBERIDS, arrayContains: User.currentId).addSnapshotListener { snapshot, error in
            
            guard let documents = snapshot?.documents else {
                print("No documents for user channels exist...")
                return
            }
            
            var channels = documents.compactMap {
                try? $0.data(as: Channel.self)
            }
            
            // チャンネルメンバーが多い順にソート
            channels.sort { $0.memberIds.count > $1.memberIds.count }
            completion(channels)
        }
    }
    
    func downloadAllChannels(completion: @escaping (_ channels: [Channel]) -> Void) {
        
        FirebaseReference(.Channel).getDocuments { [weak self] snapshot, error in
            
            guard let documents = snapshot?.documents else {
                print("No documents for all channels exist...")
                return
            }
            
            var channels = documents.compactMap {
                try? $0.data(as: Channel.self)
            }
            
            channels = self?.removeSubscribedChannels(channels) ?? []
            
            // チャンネルメンバーが多い順にソート
            channels.sort { $0.memberIds.count > $1.memberIds.count }
            completion(channels)
        }
    }
    
    // MARK: - Add, Update, Delete
    func saveChannel(_ channel: Channel) {
        do {
            try FirebaseReference(.Channel).document(channel.id).setData(from: channel)
        
        } catch {
            print("Error saving channel", error.localizedDescription)
        }
    }
    
    func deleteChannel(_ channel: Channel) {
        FirebaseReference(.Channel).document(channel.id).delete()
    }
    
    func removeSubscribedChannels(_ allChannels: [Channel]) -> [Channel]? {
        return allChannels.filter { !$0.memberIds.contains(User.currentId) }
    }
    
    func removeChannelListener() {
        channelListener.remove()
    }
    
}
