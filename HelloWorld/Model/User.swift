//
//  User.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/10.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct User: Codable, Equatable {
    var id = ""
    var name: String
    var lang = ""
    var avatarLink = ""
    
    static var currentId: String {
        return auth.currentUser!.uid
    }
    
    static var currentUser: User? {
        
        if auth.currentUser == nil { return nil }
        
        guard let dictionary = UserDefaults.standard.data(forKey: kCURRENTUSER) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        var user: User?
        do {
            user = try decoder.decode(User.self, from: dictionary)            
            
        } catch {
            print("Error decoding user from user defaults ", error.localizedDescription)
        }
        
        return user
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

func saveUserLocally(_ user: User) {
    let encoder = JSONEncoder()
    do {
        let data = try encoder.encode(user)
        UserDefaults.standard.set(data, forKey: kCURRENTUSER)
    } catch {
        print("error saving user locally ", error.localizedDescription)
    }
}

func createDummyUsers() {
    
    print("Creating dummy users...")
    
    let names = ["Alison Stamp", "Inayah Duggan", "Alfie Thornton", "Rachelle Neale", "Anya Gates", "Juanita Bate"]
    
//    var imageIndex = 1
//    var userIndex = 1
    
    for i in 0..<6 {
        
        print("user", i + 1)
        
        let id = UUID().uuidString
        
        let fileDirectory = "Avatars/" + "_\(id)" + ".jpg"
        
        // Firebase Storageにプロフィール画像を登録
        FileStorage.uploadImage(UIImage(named: "user\(i + 1)")!, directory: fileDirectory) { avatarLink in
            
            let user = User(id: id, name: names[i], avatarLink: avatarLink ?? "")
            
            // Firestoreにユーザーデータを登録
            FirebaseUserListener.shared.saveUserToFireStore(user)
        }
        
//        imageIndex += 1
//        userIndex += 1
        
//        if imageIndex == 6 { imageIndex = 1 }
    }
}


