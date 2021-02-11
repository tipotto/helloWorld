//
//  StartChat.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/14.
//

import Foundation
import Firebase

// MARK: - Start Chat

func startChat(firstUser: User, secondUser: User) -> String? {
    
    guard let chatRoomId = chatRoomIdFrom(firstUserId: firstUser.id, secondUserId: secondUser.id) else {
        return nil
    }
    
    createRecentItems(chatRoomId: chatRoomId, users: [firstUser, secondUser])
    
    return chatRoomId
}

func restartChat(chatRoomId: String, memberIds: [String]) {
    FirebaseUserListener.shared.downloadUsersFromFirebase(withIds: memberIds) { users in
        if users.count <= 0 { return }
        createRecentItems(chatRoomId: chatRoomId, users: users)
    }
}

func createRecentItems(chatRoomId: String, users: [User]) {
    
    let memberIdsToCreateRecent = [users.first!.id, users.last!.id]
    print("initial member ids", memberIdsToCreateRecent)
    
    FirebaseReference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        // Recentが存在しない場合でも、snapshot自体は返ってくる。
        guard let snapshot = snapshot else { return }
        
        guard let removedMemberIds = removeMemberWhoHasRecent(snapshot: snapshot, memberIds: memberIdsToCreateRecent) else { return }
        
        print("removed member ids", removedMemberIds)
        
        for userId in removedMemberIds {
            print("creating recent with user id", userId)
            
            guard let authUser = User.currentUser else { return }
            guard let receiverUser = getReceiverFrom(users: users) else { return }
            
            let authUserId = User.currentId
            let sender = userId == authUserId ? authUser : receiverUser
            let receiver = userId == authUserId ? receiverUser : authUser
            
            let recent = RecentChat(id: UUID().uuidString,
                                    chatRoomId: chatRoomId,
                                    senderId: sender.id,
                                    senderName: sender.username,
                                    receiverId: receiver.id,
                                    receiverName: receiver.username,
                                    date: Date(),
                                    memberIds: [sender.id, receiver.id],
                                    lastMessage: "",
                                    unreadCounter: 0,
                                    avatarLink: receiver.avatarLink)
            
            FirebaseRecentListener.shared.saveRecent(recent)

        }
        
    }
}

func removeMemberWhoHasRecent(snapshot: QuerySnapshot, memberIds: [String]) -> [String]? {
    var memberIdsToCreateRecent = memberIds
    
    // 初回実行時は、Resentが存在しないため実行されない
    for recentData in snapshot.documents {
        let currentRecent = recentData.data() as Dictionary
        
        guard let currentUserId = currentRecent[kSENDERID] as? String else { return nil }
        if !memberIdsToCreateRecent.contains(currentUserId) { continue }
        
        let indexToRemove = memberIdsToCreateRecent.firstIndex(of: currentUserId)!
        memberIdsToCreateRecent.remove(at: indexToRemove)
    }
    
    return memberIdsToCreateRecent
}

func chatRoomIdFrom(firstUserId: String, secondUserId: String) -> String? {
    
    if firstUserId.isEmpty || secondUserId.isEmpty { return nil }
    
    let value = firstUserId.compare(secondUserId).rawValue
    return value < 0 ? (firstUserId + secondUserId) : (secondUserId + firstUserId)
}

func getReceiverFrom(users: [User]) -> User? {
    var allUsers = users
    guard let authUser = User.currentUser else { return nil }
    guard let indexToRemove = allUsers.firstIndex(of: authUser) else { return nil }
    allUsers.remove(at: indexToRemove)
    
    return allUsers.first!
}
