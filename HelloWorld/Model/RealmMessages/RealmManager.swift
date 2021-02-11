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
    
    let realm = try? Realm()
    
    private init() {}
    
    func saveToRealm<T: Object>(_ object: T) {
        
        do {
            try realm?.write {
                realm?.add(object, update: .all)
            }

        } catch {
            print("error saving realm object", error.localizedDescription)
        }
    }
    
}
