//
//  RealmManager.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/18.
//

import Foundation
import RealmSwift

class RealmManager {

    static let shared = RealmManager()
    
    var realm = try? Realm()
    
    private init() {}

    func save<T: Object>(_ object: T) {

        do {
            try realm?.write {
                realm?.add(object, update: .modified)
            }

        } catch {
            print("error saving realm object", error.localizedDescription)
        }
    }
    
    func saveList<T: Object>(_ objects: [T]) {

        do {
            try realm?.write {
                realm?.add(objects, update: .modified)
            }

        } catch {
            print("error saving realm object", error.localizedDescription)
        }
    }
    
//    func saveWithoutNotifying<T: Object>(_ object: T, token: NotificationToken) {
//
//        do {
//            try realm?.write(withoutNotifying: [token]) {
//                realm?.add(object, update: .modified)
//            }
//
//        } catch {
//            print("error saving realm object", error.localizedDescription)
//        }
//    }
    
    func saveListWithoutNotifying<T: Object>(_ objects: [T], token: NotificationToken) {
        
        do {
            try realm?.write(withoutNotifying: [token]) {
                realm?.add(objects, update: .modified)
            }
            
        } catch {
            print("error saving realm object", error.localizedDescription)
        }
    }
    
    func getMessages(chatRoomId: String) -> Results<LocalMessage>? {
        let predicate = NSPredicate(format: "chatRoomId == %@", chatRoomId)
        return realm?.objects(LocalMessage.self)
                    .filter(predicate)
                    .sorted(byKeyPath: kDATE, ascending: true)
    }
    
    func updateMessage(_ message: LocalMessage, text: String) {
        do {
            try realm?.write {
                message.message = text
            }

        } catch {
            print("error saving realm object", error.localizedDescription)
        }
    }
    
    func refresh() {
        realm?.refresh()
    }
}


