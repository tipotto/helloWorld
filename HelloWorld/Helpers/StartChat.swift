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
    
    print("firstUserId", firstUser.id)
    print("secondUserId", secondUser.id)
    print("chatRoomId", chatRoomId)

    addJoiningRooms(chatRoomId: chatRoomId, users: [firstUser, secondUser])

    return chatRoomId
}

func restartChat(room: JoiningChat) {
    FirebaseUserListener.shared.downloadUsersFromFirebase(userIds: [User.currentId, room.partnerId]) {
        users in
        
        // TODO: 1人でも存在しなければ、その場で処理を終了
        if users.count <= 1 { return }
        addJoiningRooms(chatRoomId: room.id, users: users)
    }
}

func addJoiningRooms(chatRoomId: String, users: [User]) {
    
    print("Start adding rooms...")
    
    guard let firstUser = users.first,
          let secondUser = users.last else { return }
    
    let memberIdsToAddRoom = [firstUser.id, secondUser.id]
    
    FirebaseRecentListener.shared.fetchJoiningRooms(userIds: memberIdsToAddRoom) { joiningRooms in
    
        guard let removedMemberIds = removeMemberWhoHasRoom(rooms: joiningRooms, memberIds: memberIdsToAddRoom) else { return }
        
        print("removed member ids", removedMemberIds)
        
        // TODO: 現状では各ユーザーのChat作成にはバッチを使っていない
        // しかしChannelになるとユーザー数が増えるため、バッチで対応する
        guard let authUser = User.currentUser else { return }
        
        let batch = Firestore.firestore().batch()
        for userId in removedMemberIds {
            let receiver = (userId == User.currentId) ? getReceiverFrom(users: users, authUser: authUser) : authUser
            
            let room = JoiningChat(id: chatRoomId,
                                   name: receiver.name,
                                   lang: receiver.lang,
                                   partnerId: receiver.id,
                                   avatarLink: receiver.avatarLink,
                                   lastMessage: "No messages",
                                   unreadCounter: 0,
                                   date: Date())

            let joiningChatDocRef = FirebaseReference(.User).document(userId).collection(kCHAT).document(chatRoomId)
            
            do {
                try batch.setData(from: room, forDocument: joiningChatDocRef)
                
            } catch {
                print("error saving messages", error.localizedDescription)
            }
        }
        
        // Firestoreに反映
        batch.commit()

    }
}

func removeMemberWhoHasRoom(rooms: [JoiningChat], memberIds: [String]) -> [String]? {
    var memberIdsToAddRoom = memberIds

    // 初回実行時は、Resentが存在しないため実行されない
    for room in rooms {
        
        print("Remove member for room", room.id)

        var indexToRemove: Int
        if room.id == User.currentId {
            // 相手のRoomということ
            // 相手のRoomを新規作成する必要はないため、相手の
            indexToRemove = memberIdsToAddRoom.firstIndex(where: { $0 != User.currentId })!
            print("index 1", indexToRemove)

        } else {
            indexToRemove = memberIdsToAddRoom.firstIndex(of: User.currentId)!
            print("index 2", indexToRemove)
        }

        memberIdsToAddRoom.remove(at: indexToRemove)
    }

    return memberIdsToAddRoom
}

func chatRoomIdFrom(firstUserId: String, secondUserId: String) -> String? {

    if firstUserId.isEmpty || secondUserId.isEmpty { return nil }

    let value = firstUserId.compare(secondUserId).rawValue
    return value < 0 ? (firstUserId + secondUserId) : (secondUserId + firstUserId)
}

func getReceiverFrom(users: [User], authUser: User) -> User {
    var allUsers = users
    let indexToRemove = allUsers.firstIndex(of: authUser)!
    allUsers.remove(at: indexToRemove)
    return allUsers.first!
}
