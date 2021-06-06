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
    
    func fetchJoiningRooms(userIds: [String], completion: @escaping (_ rooms: [JoiningChat]) -> Void) {
        
        let firstUserId = userIds.first
        let secondUserId = userIds.last
        let partnerIdsByUser = [firstUserId: secondUserId, secondUserId: firstUserId]

        var count = 0
        var rooms: [JoiningChat] = []

        for userId in userIds {
            
            guard let partnerId = partnerIdsByUser[userId] as? String else { return }
            
            print("Fetching room for user", userId)

            FirebaseReference(.User).document(userId).collection(kCHAT).document(partnerId).getDocument { (document, error) in

                guard let document = document else {
                    print("No room documents for user", userId)
                    // TODO: もし存在しない場合は次のループを実行するようにしたい
                    // returnの場合、次のループが実行されるか確認
                    return
                }
                
                print("Got room document for user", userId)

                if let room = try? document.data(as: JoiningChat.self) {
                    print("Succeeded to cast data for user", userId)
                    rooms.append(room)
                    
                } else {
                    print("Failed to cast data for user", userId)
                }
                
                count += 1
                if count == userIds.count { completion(rooms) }
            }
        }
    }
    
    func fetchJoiningRoomsByUser(completion: @escaping (_ allRooms: [JoiningChat]) -> Void) {
        
        FirebaseReference(.User).document(User.currentId).collection(kCHAT).addSnapshotListener { (snapshot, error) in
            
            guard let documents = snapshot?.documents else {
                print("No documents for joining rooms")
                return
            }
            
            var allRooms = documents.compactMap {
                try? $0.data(as: JoiningChat.self)
            }
            
            allRooms.sort { $0.date! > $1.date! }
            completion(allRooms)
        }
    }
    
    // チャットルームから退出する時点で実行することを想定
    func clearUnreadCounter(chatRoomId: String, isChannel: Bool = false) {
        
        let roomRef = FirebaseReference(.User).document(User.currentId).collection(isChannel ? kCHANNEL : kCHAT).document(chatRoomId)

        roomRef.updateData(["unreadCounter": 0])
    }
    
    func saveJoiningRoom(room: JoiningChat, userId: String) {
        do {
            try FirebaseReference(.User).document(userId).collection(kCHAT).document(room.id).setData(from: room)
            
        } catch {
            print("Error saving recent", error.localizedDescription)
        }
    }
    
    func deleteJoiningRoom(_ room: JoiningChat) {
        FirebaseReference(.User).document(User.currentId).collection(kCHAT).document(room.id).delete()
    }
}
