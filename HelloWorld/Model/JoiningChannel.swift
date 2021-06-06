//
//  JoiningChannel.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/18.
//

import Foundation
import FirebaseFirestoreSwift

struct JoiningChannel: Codable {
    
    // TODO: 今後ドキュメントリファレンスを追加する
    // ユーザーが所属するチャンネルの、ユーザー言語のデータに直接アクセスできる
    var id = ""
    var name = ""
    var avatarLink = ""
    var lastMessage = "New message is shown here."
    var unreadCounter = 0
    var aboutChannel = ""
    var isAdmin = false
    @ServerTimestamp var date = Date()
//    var unreadMessageId = ""
    
}
