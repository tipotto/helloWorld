//
//  FirebaseTypingListener.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/19.
//

import Foundation
import Firebase

class FirebaseTypingListener {
    
    static let shared = FirebaseTypingListener()
    
    var typingListener: ListenerRegistration!
    
    private init() {}
    
    func createTypingObserver(chatRoomId: String, completion: @escaping (_ isTyping: Bool) -> Void) {
        
        // 自分とチャット相手のtypingデータが同じドキュメントにあることで、
        // 自分のテキスト入力時にも、自分側でセットしたリスナーが変更を検知してしまう
        // 自分と相手のデータを別ドキュメントにすることで、
        // 相手の入力時にのみ、自分のリスナーで変更を検知するようにしたい
        let docRef = FirebaseReference(.Typing).document(chatRoomId)
        typingListener = docRef.addSnapshotListener { (snapshot, error) in
            
            guard let fields = snapshot?.data() else {
                completion(false)
                docRef.setData([User.currentId: false])
                return
            }
            
            for field in fields {
                if field.key == User.currentId { continue }
                completion(field.value as! Bool)
            }
        }
    }
    
    class func saveTypingCounter(isTyping: Bool, chatRoomId: String) {
        FirebaseReference(.Typing).document(chatRoomId).updateData([User.currentId: isTyping])
    }
    
    func removeTypingListener() {
        typingListener.remove()
    }
    
}
