//
//  JoiningRoom.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/12.
//

import Foundation
import FirebaseFirestoreSwift

struct JoiningChat: Codable {
    
    var id = ""
    var name = ""
    var lang = ""
    var partnerId = ""
    var avatarLink = ""
    var lastMessage = "New message is shown here."
    var unreadCounter = 0
    @ServerTimestamp var date = Date()
    
}
