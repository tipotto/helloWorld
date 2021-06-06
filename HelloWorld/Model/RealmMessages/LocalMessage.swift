//
//  LocalMessage.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/17.
//

import Foundation
import RealmSwift

class LocalMessage: Object, Codable {
    
    @objc dynamic var id = ""
    @objc dynamic var chatRoomId = ""
    @objc dynamic var date = Date()
    @objc dynamic var senderName = ""
    @objc dynamic var senderId = ""
    @objc dynamic var senderLang = ""
    @objc dynamic var senderInitials = ""
    @objc dynamic var readDate = Date()
    @objc dynamic var type = ""
    @objc dynamic var status = ""
    @objc dynamic var readCounter = 0
    @objc dynamic var message = ""
    @objc dynamic var audioUrl = ""
    @objc dynamic var videoUrl = ""
    @objc dynamic var pictureUrl = ""
    @objc dynamic var latitude = 0.0
    @objc dynamic var longitude = 0.0
    @objc dynamic var audioDuration = 0.0

    // TODO: 今後追加する予定
//    @objc dynamic var sourceLang = ""
//    @objc dynamic var translateLang = ""
//    @objc dynamic var sourceText = ""
//    @objc dynamic var translatedText = ""
    

    override class func primaryKey() -> String? {
        // プライマリーキーとしてidのvalueを設定
        return "id"
    }
    
}
