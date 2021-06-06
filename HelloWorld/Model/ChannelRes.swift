//
//  ChannelRes.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/04/11.
//

import Foundation

struct ChannelRes: Codable {
    
    var id = ""
    var name = ""
    var avatarLink = ""
    var aboutChannel = ""
    var channelId: String
    
    //    enum CodingKeys: String, CodingKey {
    //        case id
    //        case name
    //        case adminId
    //        case avatarLink
    //        case aboutChannel
    //        case createdDate
    //        case lastMessageDate = "date"
    //    }

        
}
