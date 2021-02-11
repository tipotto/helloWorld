//
//  RecentChat.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/14.
//

import Foundation
import FirebaseFirestoreSwift

struct RecentChat: Codable {
    
    var id = ""
    var chatRoomId = ""
    var senderId = ""
    var senderName = ""
    var receiverId = ""
    var receiverName = ""
    @ServerTimestamp var date = Date()
    var memberIds = [""]
    var lastMessage = ""
    var unreadCounter = 0
    var avatarLink = ""
    
}
