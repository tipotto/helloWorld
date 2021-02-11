//
//  FirebaseUserListener.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/10.
//

import Foundation
import Firebase


class FirebaseUserListener {
    
    static let shared = FirebaseUserListener()
    
    private init() {}
    
    // MARK: - Login
    func loginUserWithEmail(email: String, password: String, completion: @escaping (_ error: Error?, _ isEmailVerified: Bool) -> Void) {
        
        auth.signIn(withEmail: email, password: password) { (result, error) in
            
            if error != nil {
                print("login error occurred.")
                completion(error, false)
                return
            }
            
            guard let authUser = result?.user, authUser.isEmailVerified else {
                print("Email is not verified.")
                completion(nil, false)
                return
            }
            
            FirebaseUserListener.shared.downloadUserFromFirebase(userId: authUser.uid, email: email)
            completion(nil, true)
        }
    }
    
    // MARK: - Register
    func registerUserWith(email: String, password: String, completion: @escaping (_ error: Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] (result, error) in
            
            if error != nil {
                completion(error)
                return
            }

            guard let authUser = result?.user else {
                completion(FirebaseError.failedToFetchAuthUser)
                return
            }

            // send verification email
            authUser.sendEmailVerification { error in
                completion(error)
                return
            }

            // create user and save it
            let user = User(id: authUser.uid,
                            username: email,
                            email: email,
                            pushId: "",
                            avatarLink: "",
                            status: "Hey there I'm using Messenger")
            
            saveUserLocally(user)
            self?.saveUsersToFireStore(user)
            
            completion(nil)
                
        }
    }
    
    // MARK: - Firebase errors
    public enum FirebaseError: Error {
        case failedToFetchAuthUser
    }
    
    // MARK: - Resend link methods
    func resendVerificationEmail(email: String, completion: @escaping (_ error: Error?) -> Void) {
        
        guard let authUser = auth.currentUser else {
            completion(FirebaseError.failedToFetchAuthUser)
            return
        }
        
        authUser.reload { error in
            authUser.sendEmailVerification { error in
                completion(error)
            }
        }
    }
    
    
    func resetPasswordFor(email: String, completion: @escaping (_ error: Error?) -> Void) {
        auth.sendPasswordReset(withEmail: email) { error in
            completion(error)
        }
    }
    
    func logOutCurrentUser(completion: @escaping (_ error: Error?) -> Void) {
        do {
            try auth.signOut()
            userDefaults.removeObject(forKey: kCURRENTUSER)
            userDefaults.synchronize()
            completion(nil)
            
        } catch let error as NSError {
            completion(error)
        }
    }
    
    // MARK: - Save users
    func saveUsersToFireStore(_ user: User) {
        do {
            try FirebaseReference(.User).document(user.id).setData(from: user)
        } catch {
            print(error.localizedDescription, "adding user")
        }
    }
    
//    func saveFriendsToFireStore(_ user: User) {
//        do {
//            try FirebaseReference(.User).document(User.currentId).collection(user.id).document(user.id).setData(from: user)
//        } catch {
//            print(error.localizedDescription, "adding user")
//        }
//    }
    
    // MARK: - Download user from firebase
    func downloadUserFromFirebase(userId: String, email: String? = nil) {
        FirebaseReference(.User).document(userId).getDocument { (snapshot, error) in
            
            guard let document = snapshot else {
                print("No document for user")
                return
            }
            
            let result = Result {
                try? document.data(as: User.self)
            }
            
            switch result {
            case .success(let user):
                guard let user = user else {
                    print("Document doesn't exist.")
                    return
                }
                saveUserLocally(user)
                
            case .failure(let error):
                print("Error decoding user ", error)
            }
        }
    }
    
    func downloadAllUsersFromFirebase(completion: @escaping (_ allUsers: [User]) -> Void) {
        
        var users: [User] = []
        
        // 以下の処理は非同期処理であり、実行結果を取得した時点でクロージャーを実行
        // クロージャー外でcompletionを実行した場合、非同期処理の完了を待たずに結果を呼び出し元に返してしまう
        FirebaseReference(.User).limit(to: 500).getDocuments { (querySnapshot, error) in
            
            guard let document = querySnapshot?.documents else {
                print("No documents in all users")
                return
            }
            
            let allUsers = document.compactMap { documentSnapshot -> User? in
                return try? documentSnapshot.data(as: User.self)
            }
            
            for user in allUsers {
                if User.currentId == user.id { continue }
                users.append(user)
            }
            
            completion(users)
        }
    }
    
    func downloadUsersFromFirebase(withIds: [String], completion: @escaping (_ allUsers: [User]) -> Void) {

        var count = 0
        var users: [User] = []
        
        for userId in withIds {
            
            FirebaseReference(.User).document(userId).getDocument { (snapshot, error) in
                
                guard let document = snapshot else {
                    print("No document for user")
                    return
                }
                
                guard let user = try? document.data(as: User.self) else {
                    print("Failed to cast user data")
                    return
                }
                
                users.append(user)
                count += 1
                
                if count == withIds.count {
                    completion(users)
                }
            }
        }
    }
}
