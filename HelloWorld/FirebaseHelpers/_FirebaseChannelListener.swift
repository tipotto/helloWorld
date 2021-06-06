//
//  FirebaseChannelListener.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/02.
//

import Foundation
import Firebase

class _FirebaseChannelListener {
    static let shared = _FirebaseChannelListener()
    var channelListener: ListenerRegistration!
    
    private init() {}
    
    // MARK: - Fetching
    func downloadUserChannels(completion: @escaping (_ channels: [ChannelRes]) -> Void) {
        channelListener = FirebaseGroupQuery(.ChannelRes)
            .whereField(kID, isEqualTo: User.currentUser!.lang)
            .whereField(kADMINID, isEqualTo: User.currentId)
            .addSnapshotListener { snapshot, error in
            
            guard let documents = snapshot?.documents else {
                print("No documents for user channels exist...")
                return
            }
            
            let channels = documents.compactMap {
                try? $0.data(as: ChannelRes.self)
            }
            
            // チャンネルメンバーが多い順にソート
//            channels.sort { $0.date! > $1.date! }
            completion(channels)
        }
    }
    
//    func downloadUserChannels(completion: @escaping (_ channels: [Channel]) -> Void) {
//        channelListener = FirebaseReference(.Channel)
//            .whereField(kADMINID, isEqualTo: User.currentId)
//            .addSnapshotListener { snapshot, error in
//
//            guard let documents = snapshot?.documents else {
//                print("No documents for user channels exist...")
//                return
//            }
//
//            let channels = documents.compactMap {
//                try? $0.data(as: Channel.self)
//            }
//
//            // チャンネルメンバーが多い順にソート
////            channels.sort { $0.date! > $1.date! }
//            completion(channels)
//        }
//    }
    
//    func downloadUserChannels(completion: @escaping (_ channels: [JoiningChannel]) -> Void) {
//        channelListener = FirebaseReference(.User).document(User.currentId).collection("Channel")
//            .whereField(kISADMIN, isEqualTo: true)
//            .addSnapshotListener { snapshot, error in
//
//            guard let documents = snapshot?.documents else {
//                print("No documents for user channels exist...")
//                return
//            }
//
//            var channels = documents.compactMap {
//                try? $0.data(as: JoiningChannel.self)
//            }
//
//            // チャンネルメンバーが多い順にソート
//            channels.sort { $0.date! > $1.date! }
//            completion(channels)
//        }
//    }
    
    func downloadSubscribedChannels(completion: @escaping (_ channels: [JoiningChannel]) -> Void) {
        
        channelListener = FirebaseReference(.User).document(User.currentId).collection(kCHANNEL).addSnapshotListener { snapshot, error in
                    
            guard let documents = snapshot?.documents else {
                print("No documents for user channels exist...")
                return
            }
            
            var channels = documents.compactMap {
                try? $0.data(as: JoiningChannel.self)
            }
            
            // チャンネルメンバーが多い順にソート
            channels.sort { $0.date! > $1.date! }
            completion(channels)
        }
    }
    
    func downloadChannel(channelId: String, completion: @escaping (_ channel: Channel) -> Void) {
        
        FirebaseReference(.Channel).document(channelId).getDocument { snapshot, error in
            
            guard let document = snapshot else {
                print("No documents for all channels exist...")
                return
            }
            
            let result = Result {
                try? document.data(as: Channel.self)
            }
            
            switch result {
            case .success(let channel):
                guard let channel = channel else {
                    print("Document doesn't exist.")
                    return
                }
                
                DispatchQueue.main.async {
                    completion(channel)
                }
                
            case .failure(let error):
                print("Error decoding user ", error)
            }
        }
    }
    
    func downloadAllChannels(completion: @escaping (_ channels: [ChannelRes]) -> Void) {
        
        FirebaseGroupQuery(.ChannelRes)
            .whereField(kID, isEqualTo: User.currentUser!.lang)
            .limit(to: kNUMBEROFCHANNELS).getDocuments { [weak self] snapshot, error in
            
            guard let documents = snapshot?.documents else {
                print("No documents for all channels exist...")
                return
            }
            
            let channels = documents.compactMap {
                try? $0.data(as: ChannelRes.self)
            }
                
            completion(channels)
        }
    }
    
//    func downloadAllChannels(completion: @escaping (_ channels: [Channel]) -> Void) {
//
//        FirebaseReference(.Channel).limit(to: kNUMBEROFCHANNELS).getDocuments { [weak self] snapshot, error in
//
//            guard let documents = snapshot?.documents else {
//                print("No documents for all channels exist...")
//                return
//            }
//
//            let channels = documents.compactMap {
//                try? $0.data(as: Channel.self)
//            }
//
////            channels = self?.removeSubscribedChannels(channels) ?? []
//
//            // チャンネルメンバーが多い順にソート
////            channels.sort { $0.memberIds.count > $1.memberIds.count }
//            completion(channels)
//        }
//    }
    
    // MARK: - Add, Update, Delete
    func saveChannel(_ channel: Channel) {
        do {
            try FirebaseReference(.Channel).document(channel.id).setData(from: channel)

        } catch {
            print("Error saving channel", error.localizedDescription)
        }
    }
    
    func save(_ channel: ChannelRes) {
        
        FirebaseGroupQuery(.Channel).whereField(kID, isEqualTo: channel.id).getDocuments { (snapshot, error) in
        
            guard let documents = snapshot?.documents else {
                print("No document for specific channel exists...")
                return
            }
            
            let batch = Firestore.firestore().batch()
            for doc in documents {
                let documentRef = doc.reference
                print("documentRef", documentRef)
                
                do {
                    
                    if documentRef.path.contains(kUSER) {
                        batch.updateData([
                            "name": channel.name,
                            "avatarLink": channel.avatarLink
                        ], forDocument: documentRef)
                        continue
                    }
                    
                    try batch.setData(from: channel, forDocument: documentRef)
                    
                } catch {
                    print("error saving messages", error.localizedDescription)
                }
            }
            
            // Firestoreに反映
            batch.commit()
        }
    }
    
    func createChannel(channelId: String, channelRes: ChannelRes, userLang: String) {
        
        print("Create new channel")
        
        let channelDocRef = FirebaseReference(.Channel).document(channelId)
        
        // TODO: langコレクションではなく、channelResに変更する
        let channelResDocRef = channelDocRef.collection(kLANG).document(userLang)
        
        let batch = Firestore.firestore().batch()
        do {
            try batch.setData(from: Channel(id: channelId), forDocument: channelDocRef)
            try batch.setData(from: channelRes, forDocument: channelResDocRef)
            
        } catch {
            print("Error saving joining channel", error.localizedDescription)
        }
        
        // Firestoreに反映
        batch.commit()
        
    }
    
//    func createChannel(channelId: String, joiningChannel: JoiningChannel, channel: Channel, channelMember: ChannelMember) {
//
//        print("Create new channel")
//
//        let joiningChannelDocRef = FirebaseReference(.User).document(User.currentId).collection(kCHANNEL).document(channelId)
//
//        let channelDocRef = FirebaseReference(.Channel).document(channelId)
//
//        // TODO: langChannelDocRefをjoiningChannelのプロパティとして保持する
//        // ユーザーが所属するチャンネルの、ユーザー言語のデータに直接アクセスできる
//        let langChannelDocRef = channelDocRef.collection(kLANG).document(channelMember.lang)
//        let memberDocRef = channelDocRef.collection(kUSER).document(User.currentId)
//
//        let batch = Firestore.firestore().batch()
//        do {
//            try batch.setData(from: joiningChannel, forDocument: joiningChannelDocRef)
//            try batch.setData(from: channel, forDocument: langChannelDocRef)
//            try batch.setData(from: channelMember, forDocument: memberDocRef)
//
//        } catch {
//            print("Error saving joining channel", error.localizedDescription)
//        }
//
//        // Firestoreに反映
//        batch.commit()
//    }
    
    func followChannel(channelId: String, joiningChannel: JoiningChannel) {
        
        let joiningChannelDocRef = FirebaseReference(.User).document(User.currentId).collection(kCHANNEL).document(channelId)
        
        do {
            try joiningChannelDocRef.setData(from: joiningChannel)

        } catch {
            print("Error saving joining channel", error.localizedDescription)
        }
    }
        
//    func followChannel(channelId: String, joiningChannel: JoiningChannel, channelMember: ChannelMember) {
//
//        let joiningChannelDocRef = FirebaseReference(.User).document(User.currentId).collection("Channel").document(channelId)
//        let channelDocRef = FirebaseReference(.Channel).document(channelId)
//        let memberDocRef = channelDocRef.collection(kUSER).document(User.currentId)
//
//        let batch = Firestore.firestore().batch()
//        do {
//            try batch.setData(from: joiningChannel, forDocument: joiningChannelDocRef)
//            try batch.setData(from: channelMember, forDocument: memberDocRef)
//
//            batch.updateData(["memberCounter": FieldValue.increment(1.0)], forDocument: channelDocRef)
//
//        } catch {
//            print("Error saving joining channel", error.localizedDescription)
//        }
//
//        // Firestoreに反映
//        batch.commit()
//    }
    
    func unfollowChannel(channelId: String) {
        
        let batch = Firestore.firestore().batch()
        let channelDocRef = FirebaseReference(.Channel).document(channelId)
        let memberDocRef = channelDocRef.collection(kUSER).document(User.currentId)
            
        batch.deleteDocument(memberDocRef)
        batch.updateData(["memberCounter": FieldValue.increment(-1.0)], forDocument: channelDocRef)
        
        // Firestoreに反映
        batch.commit()
    }
    
    func deleteChannel(_ channel: Channel) {
        FirebaseReference(.Channel).document(channel.id).delete()
    }

//    func removeSubscribedChannels(_ allChannels: [Channel]) -> [Channel]? {
//        return allChannels.filter { !$0.memberIds.contains(User.currentId) }
//    }
    
    func removeChannelListener() {
        channelListener.remove()
    }
    
}
