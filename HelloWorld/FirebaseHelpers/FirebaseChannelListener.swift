//
//  FirebaseChannelListener.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/02.
//

import Foundation
import Firebase
import FirebaseFunctions

class FirebaseChannelListener {
    static let shared = FirebaseChannelListener()
    var channelListener: ListenerRegistration!
    lazy var functions = Functions.functions(region: "asia-northeast1")
    
    private init() {}
    
    // MARK: - Fetching
    func downloadAdminChannels(userId: String, completion: @escaping (_ adminChannels: [JoiningChannel]) -> Void) {
        channelListener = FirebaseReference(.User).document(userId).collection(kCHANNEL)
            .whereField(kISADMIN, isEqualTo: true)
            .addSnapshotListener { snapshot, error in
            
            guard let documents = snapshot?.documents else {
                print("No documents of joining channels...")
                return
            }
            
            let adminChannels = documents.compactMap {
                try? $0.data(as: JoiningChannel.self)
            }
            
            completion(adminChannels)
        }
    }
    
//    func downloadUserChannels(completion: @escaping (_ channels: [ChannelRes]) -> Void) {
//        channelListener = FirebaseGroupQuery(.ChannelRes)
//            .whereField(kID, isEqualTo: User.currentUser!.lang)
//            .whereField(kADMINID, isEqualTo: User.currentId)
//            .addSnapshotListener { snapshot, error in
//
//            guard let documents = snapshot?.documents else {
//                print("No documents for user channels exist...")
//                return
//            }
//
//            let channels = documents.compactMap {
//                try? $0.data(as: ChannelRes.self)
//            }
//
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
            .limit(to: kNUMBEROFCHANNELS).getDocuments { snapshot, error in
            
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

    // MARK: - Add, Update, Delete
    func saveChannel(joiningCh: JoiningChannel) {
        
        guard let currentUser = User.currentUser else { return }
        
        let joiningChDocRef = FirebaseReference(.User).document(currentUser.id).collection(kCHANNEL).document(joiningCh.id)
        
        do {
            try joiningChDocRef.setData(from: joiningCh)
            
        } catch {
            print("Error saving joining channel", error.localizedDescription)
        }
    }
    
    func followChannel(joiningChannel: JoiningChannel) {
        
        let joiningChannelDocRef = FirebaseReference(.User).document(User.currentId).collection(kCHANNEL).document(joiningChannel.id)
        
        do {
            try joiningChannelDocRef.setData(from: joiningChannel)

        } catch {
            print("Error saving joining channel", error.localizedDescription)
        }
    }
    
    func unfollowChannel(channelId: String) {
        FirebaseReference(.User).document(User.currentId).collection(kCHANNEL).document(channelId).delete()
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
    
    func translate(transTexts: [String], transLang: String, completion: @escaping(_ transResults: [String]) -> Void) {
        
        functions
            .httpsCallable("onTranslateTexts").call([
                "transTexts": transTexts,
                "transLang": transLang
            ]) { (results, error) in
                
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        print("Error code", code ?? "NULL")
                        print("Error message", message)
                        print("Error details", details ?? "NULL")
                        print("FunctionsError...", error.localizedDescription)
                        return
                    }
                    
                    print("NSError...", error.localizedDescription)
                    return
                }
                
                guard let transResults = results?.data as? [String] else {
                    print("Error getting or converting translated results...")
                    return
                }
                
                completion(transResults)
                
            }
    }
    
    func translateSearchKeyword(keyword: String, transLang: String, completion: @escaping(_ transResults: [String]) -> Void) {
        
        translate(transTexts: [keyword], transLang: transLang) {
            results in
            
            completion(results)
            
        }
    }
    
    func translateChannels(channels: [ChannelRes], userLang: String, completion: @escaping(_ transResults: [ChannelRes]) -> Void) {
        
        print("translate with HTTP functions...")
        
        var transTexts = [String]()
        channels.forEach {
            transTexts.append($0.name)
            transTexts.append($0.aboutChannel)
        }
        
        translate(transTexts: transTexts, transLang: userLang) {
            results in
                
                var transResults = [ChannelRes]()
                for (index, channel) in channels.enumerated() {
                    let i = index * 2
                    let transName = results[i]
                    let transAboutChannel = results[i + 1]
                    
                    var chRes = channel
                    chRes.name = transName
                    chRes.aboutChannel = transAboutChannel
                    transResults.append(chRes)
                }
                
                completion(transResults)
            }
    }
    
//    func translateChannels(channels: [ChannelRes], userLang: String, completion: @escaping(_ transResults: [ChannelRes]) -> Void) {
//
//        print("translate with HTTP functions...")
//
//        var transTexts = [String]()
//        channels.forEach {
//            transTexts.append($0.name)
//            transTexts.append($0.aboutChannel)
//        }
//
//        functions
//            .httpsCallable("onTranslateTexts").call([
//                "transTexts": transTexts,
//                "transLang": userLang
//            ]) { (results, error) in
//
//                if let error = error as NSError? {
//                    if error.domain == FunctionsErrorDomain {
//                        let code = FunctionsErrorCode(rawValue: error.code)
//                        let message = error.localizedDescription
//                        let details = error.userInfo[FunctionsErrorDetailsKey]
//                        print("Error code", code ?? "NULL")
//                        print("Error message", message)
//                        print("Error details", details ?? "NULL")
//                        print("FunctionsError...", error.localizedDescription)
//                        return
//                    }
//
//                    print("NSError...", error.localizedDescription)
//                    return
//                }
//
//                guard let results = results?.data as? [String] else {
//                    print("Error getting or converting translated results...")
//                    return
//                }
//
//                var transResults = [ChannelRes]()
//                for (index, channel) in channels.enumerated() {
//                    let i = index * 2
//                    let transName = results[i]
//                    let transAboutChannel = results[i + 1]
//
//                    var chRes = channel
//                    chRes.name = transName
//                    chRes.aboutChannel = transAboutChannel
//                    transResults.append(chRes)
//                }
//
//                completion(transResults)
//            }
//    }
    
}
