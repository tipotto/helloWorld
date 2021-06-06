//
//  Channel.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/01.
//

import Foundation
import FirebaseFirestoreSwift

struct Channel: Codable {

    var id = ""
    var adminId = ""
    var memberCounter = 0
    @ServerTimestamp var lastMessageDate = Date()
}
