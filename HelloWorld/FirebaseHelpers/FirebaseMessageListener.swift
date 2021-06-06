    //
    //  FirebaseMessageListener.swift
    //  HelloWorld
    //
    //  Created by egamiyuji on 2021/01/18.
    //

    import Foundation
    import Firebase
    import FirebaseFirestoreSwift
    import RealmSwift
    import FirebaseFunctions

    class FirebaseMessageListener {
        
        static let shared = FirebaseMessageListener()
        var newChatListener: ListenerRegistration!
        var updatedChatListener: ListenerRegistration!
        
        lazy var functions = Functions.functions(region: "asia-northeast1")
        
        private init() {}
        
        func listenForNewChats(channelId: String, lastMessageDate: Date, isChannel: Bool = false) {
            
            guard let currentUser = User.currentUser else { return }
            
            let currentUserMsgRef = FirebaseReference(isChannel ? .Channel : .Chat).document(channelId).collection(kMESSAGE)
            
            newChatListener = currentUserMsgRef
                .whereField(kDATE, isGreaterThan: lastMessageDate)
                .addSnapshotListener { [weak self] (snapshot, error) in
                    
                    guard let snapshot = snapshot else { return }
                    
                    for change in snapshot.documentChanges {
                        if change.type != .added { continue }
                        print("New document is added")
                        
                        let result = Result {
                            try? change.document.data(as: LocalMessage.self)
                        }
                        
                        switch result {
                        case .success(let message):
                            guard let message = message else { break }
                            
                            // Outgoingメッセージはスルーする（チャンネルの場合）
                            // 本来であれば、WhereFieldクエリで制限したかったが
                            // Firestoreにクエリ制限があるため不可
                            if message.senderId == User.currentId { break }
                            
                            // Incomingメッセージのみを保存する
                            // Outgoingメッセージは、送信時にRealmに保存
                            if message.senderLang == currentUser.lang {
                                RealmManager.shared.save(message)
                                
                            } else {
                                self?.translateText(message: message, userLang: currentUser.lang)
                            }
                            
                            self?.changeReadStatus(channelId: channelId, message: message, isChannel: isChannel)
                            
                        case .failure(let error):
                            print("error decoding local messages", error.localizedDescription)
                        }
                    }
                }
        }
        
        func listenForReadStatusChange(channelId: String, isChannel: Bool = false) {
            
            let messageRef = FirebaseReference(isChannel ? .Channel : .Chat).document(channelId).collection(kMESSAGE)
            
            updatedChatListener = messageRef
                .whereField(kSENDERID, isEqualTo: User.currentId)
                //            .whereField(kREADCOUNTER, isGreaterThan: 0)
                //            .whereField(kREADCOUNTER, isNotEqualTo: 0)
                .addSnapshotListener { (snapshot, error) in
                    
                    guard let snapshot = snapshot else { return }
                    
                    for change in snapshot.documentChanges {
                        if change.type != .modified { continue }
                        
                        print("detect read status change")
                        
                        let result = Result {
                            try? change.document.data(as: LocalMessage.self)
                        }
                        
                        switch result {
                        case .success(let message):
                            guard let message = message else { break }
                            if message.readCounter <= 0 { break }
                            
                            RealmManager.shared.save(message)
                            
                        case .failure(let error):
                            print("Error decoding local message", error.localizedDescription)
                        }
                    }
                }
        }
        
        func moldMessages(snapshot: QuerySnapshot?) -> [String: Any]? {
            
            guard let documents = snapshot?.documents, documents.first != nil else {
                print("No documents found...")
                return nil
            }
            
            guard let lastSnapshot = documents.last else { return nil }
            
            var messages = documents.compactMap {
                try? $0.data(as: LocalMessage.self)
            }
            
            // 順番を逆順にソート（古いもの順に並び替え）
            messages.sort { $0.date < $1.date }
            
            return [
                "messages": messages,
                "cursor": lastSnapshot
            ]
        }
        
        // Initial Messagesも含め、翻訳完了後に全てRealmに保存する場合
        func translate(messages: [LocalMessage], userLang: String, completion: @escaping(_ transResults: [LocalMessage]) -> Void) {
            
            print("translate with HTTP functions")
            
            // TODO: transMessagesが空の場合の処理を追加する
            // 翻訳が必要なメッセージだけの配列を作成
            let transMessages = messages.filter { $0.senderLang != userLang }
            
            if transMessages.count <= 0 {
                completion(messages)
                return
            }
            
            // 翻訳するテキストの配列を作成
            let transTexts = transMessages.map { $0.message }
            
            functions
                .httpsCallable("onTranslateTexts").call([
                    "transTexts": transTexts,
                    "transLang": userLang
                ]) { (results, error) in
                    
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            let code = FunctionsErrorCode(rawValue: error.code)
                            let message = error.localizedDescription
                            let details = error.userInfo[FunctionsErrorDetailsKey]
                            print("Error code", code ?? "NULL")
                            print("Error message", message)
                            print("Error details", details ?? "NULL")
                            print("FunctionsError...", error.localizedDescription)
                            return
                        }
                        
                        print("NSError...", error.localizedDescription)
                        return
                    }
                    
                    guard var results = results?.data as? [String] else {
                        print("Error getting or converting translated results...")
                        return
                    }
                    
                    var messages = messages
                    
                    // まだRealmに未登録なので、全メッセージを返す必要あり
                    for (index, message) in messages.enumerated() {
                        // ユーザー言語のメッセージは、そのまま返してRealmに追加
                        if message.senderLang == userLang { continue }
                        
                        message.message = results.first!
                        messages[index] = message
                        
                        results.removeFirst()
                    }
                    
                    completion(messages)
                }
        }
        
//        func translate(messages: [LocalMessage], userLang: String, isRealmNotified: Bool = false, completion: @escaping(_ transResults: [TranslateResult]) -> Void) {
//
//            print("translate with HTTP functions")
//
//            // TODO: transMessagesが空の場合の処理を追加する
//            // 翻訳が必要なメッセージだけの配列を作成
//            let transMessages = messages.filter { $0.senderLang != userLang }
//
//            // 翻訳するテキストの配列を作成
//            let transTexts = transMessages.map { $0.message }
//
//            functions
//                .httpsCallable("onTranslateTexts").call([
//                    "transTexts": transTexts,
//                    "transLang": userLang
//                ]) { (results, error) in
//
//                    if let error = error as NSError? {
//                        if error.domain == FunctionsErrorDomain {
//                            let code = FunctionsErrorCode(rawValue: error.code)
//                            let message = error.localizedDescription
//                            let details = error.userInfo[FunctionsErrorDetailsKey]
//                            print("Error code", code ?? "NULL")
//                            print("Error message", message)
//                            print("Error details", details ?? "NULL")
//                            print("FunctionsError...", error.localizedDescription)
//                            return
//                        }
//
//                        print("NSError...", error.localizedDescription)
//                        return
//                    }
//
//                    guard var results = results?.data as? [String] else {
//                        print("Error getting or converting translated results...")
//                        return
//                    }
//
//                    var transResults = [TranslateResult]()
//                    // 翻訳前にRealmに登録済みなので、翻訳済みのメッセージだけを返す
//                    if(isRealmNotified) {
//                        for (index, message) in transMessages.enumerated() {
//                            transResults.append(TranslateResult(message: message, transText: results[index]))
//                        }
//
//                        completion(transResults)
//                        return
//                    }
//
//                    // まだRealmに未登録なので、全メッセージを返す必要あり
//                    for (_, message) in messages.enumerated() {
//                        // ユーザー言語のメッセージは、そのまま返してRealmに追加
//                        if message.senderLang == userLang {
//                            transResults.append(TranslateResult(message: message, transText: ""))
//
//                            continue
//                        }
//
//                        // Realm未登録であれば、ここで値を更新可能かも？
//                        message.message = results.first!
//
//                        transResults.append(TranslateResult(message: message, transText: ""))
//
//                        results.removeFirst()
//                    }
//
//                    completion(transResults)
//                }
//        }
        
        // HTTP呼び出し可能関数を利用したパターン
        // クライアント側ではなく、バックエンド側で翻訳を実行
        func translateText(message: LocalMessage, userLang: String) {
            
            print("translateText")
            
            translate(messages: [message], userLang: userLang) { messages in
                RealmManager.shared.saveList(messages)
            }
        }
        
//        func translateText(message: LocalMessage, userLang: String) {
//
//            print("translateText")
//
//            translate(messages: [message], userLang: userLang) { transResults in
//
//                let result = transResults[0]
//                RealmManager.shared.saveToRealm(result.message)
//            }
//        }
        
        // HTTP呼び出し可能関数を利用したパターン
        // クライアント側ではなく、バックエンド側で翻訳を実行
        func translateInitialMessages(messages: [LocalMessage], userLang: String) {
            
            print("translateInitMessages")
            
            translate(messages: messages, userLang: userLang) { messages in
                print("Saving translated messages to realm...")
                RealmManager.shared.saveList(messages)
            }
        }
        
//        func translateInitialMessages(messages: [LocalMessage], userLang: String) {
//
//            print("translateInitMessages")
//
//            translate(messages: messages, userLang: userLang) { transResults in
//
//                for result in transResults {
//                    print("Updating translated text to realm...")
//
//                    RealmManager.shared.saveToRealm(result.message)
//                }
//            }
//        }
        
//        func translateInitialMessages(messages: [LocalMessage], userLang: String) {
//
//            print("translateInitMessages")
//
//            translate(messages: messages, userLang: userLang, isRealmNotified: true) { transResults in
//
//                for result in transResults {
//                    print("Updating translated text to realm...")
//
//                    RealmManager.shared.updateMessage(result.message, text: result.transText)
//                }
//            }
//        }
        
        func translateMessages(messages: [LocalMessage], userLang: String, completion: @escaping(_ isCompleted: Bool) -> Void) {
            
            print("translateMessages")
            
            translate(messages: messages, userLang: userLang) { messages in
                
                guard let token = ChannelChatViewController.notificationToken else {
                    print("Failed to get notification token...")
                    return
                }
                
                print("Saving messages without notifying to realm...")

                RealmManager.shared.saveListWithoutNotifying(messages, token: token)
                
                completion(true)
            }
        }
        
//        func translateMessages(messages: [LocalMessage], userLang: String, completion: @escaping(_ isCompleted: Bool) -> Void) {
//
//            print("translateMessages")
//
//            translate(messages: messages, userLang: userLang) { transResults in
//
//                for result in transResults {
//
//                    print("Updating message without notifying to realm...")
//                    guard let token = ChannelChatViewController.notificationToken else {
//                        print("Failed to get notification token...")
//                        continue
//                    }
//
//                    RealmManager.shared.saveWithoutNotifying(result.message, token: token)
//                }
//
//                completion(true)
//            }
//        }
        
        func fetch(channelId: String, cursor: QueryDocumentSnapshot, completion: @escaping(_ result: [String: Any]?) -> Void) {
            
            let query = FirebaseReference(.Channel).document(channelId)
                .collection(kMESSAGE)
                .order(by: "date", descending: true)
                .limit(to: kLOADMESSAGESNUMBER)
            
            query
                .start(afterDocument: cursor)
                .getDocuments { [weak self] (snapshot, error) in
                    
                    guard let result = self?.moldMessages(snapshot: snapshot)  else {
                        completion(nil)
                        return
                    }
                    
                    completion(result)
                }
        }
        
        func fetchMessagesByCursor(channelId: String, userLang: String, cursor: QueryDocumentSnapshot, group: DispatchGroup) {
            
            group.enter()
            
            fetch(channelId: channelId, cursor: cursor) { [weak self] result in
                    
                if result != nil {
                    
                    let result = result!
                    let messages = result["messages"] as! [LocalMessage]
                    let newCursor = result["cursor"] as! QueryDocumentSnapshot
                    
                    self?.fetchMessagesByCursor(channelId: channelId, userLang: userLang, cursor: newCursor, group: group)
                    
                    self?.translateMessages(messages: messages, userLang: userLang) { _ in
                        
                        print("Finished translating...")
                        group.leave()
                    }
                    
                } else {
                    group.leave()
                }
            }
        }
        
        func fetchSubsequentMessages(channelId: String, cursor: QueryDocumentSnapshot, completion: @escaping(_ isCompleted: Bool) -> Void) {
            
            guard let currentUser = User.currentUser else { return }
            let group = DispatchGroup()
            
            fetchMessagesByCursor(channelId: channelId, userLang: currentUser.lang, cursor: cursor, group: group)
            
            group.notify(queue: .main) {
                print("Finished all translating!!!")
                completion(true)
            }
        }
        
        func fetchMessages(channelId: String, completion: @escaping (_ isCompleted: Bool) -> Void) {
            print("Translating in new lang...")
            
            guard let currentUser = User.currentUser else { return }
            
            let query = FirebaseReference(.Channel).document(channelId)
                .collection(kMESSAGE)
                .order(by: "date", descending: true)
                .limit(to: kDISPLAYMESSAGESNUMBER)
            
            // 新しい順に上から12件を取得
            query.getDocuments { [weak self] (snapshot, error) in
                guard let result = self?.moldMessages(snapshot: snapshot),
                      let messages = result["messages"] as? [LocalMessage],
                      let cursor = result["cursor"] as? QueryDocumentSnapshot else {
                    print("Failed to get documents in translateInNewLang...")
                    completion(false)
                    return
                }
                
                // 新規メッセージをRealmに追加
                print("Insert new messages to Realm and first translate...")
//                for message in messages {
//                    RealmManager.shared.saveToRealm(message)
//                }
                
                self?.translateInitialMessages(messages: messages, userLang: currentUser.lang)
                
                self?.fetchSubsequentMessages(channelId: channelId, cursor: cursor) {
                    _ in
                    completion(true)
                }
            }
        }
        
        func changeReadStatus(channelId: String, message: LocalMessage, isChannel: Bool) {
            
            if message.senderId == User.currentId { return }
            
            print("Changing read status...")
            
            let messageDocRef = FirebaseReference(isChannel ? .Channel : .Chat).document(channelId).collection(kMESSAGE).document(message.id)
            
            let readStatusDocRef = messageDocRef.collection(kREADSTATUS).document(User.currentId)
            
            readStatusDocRef.getDocument { [weak self] (snapshot, error) in
                
                guard let data = snapshot?.data() as? [String: Bool] else {
                    print("No documents for read status")
                    return
                }
                
                if let isRead = data["isRead"], !isRead {
                    self?.updateReadStatus(chatRoomId: channelId, message: message, isChannel: isChannel)
                }
            }
        }
        
        // MARK: - Add, Update, Delete
        func send(message: LocalMessage, members: [ChannelMember], isChannel: Bool) {
            
            print("sending...")
            addMessage(message: message, members: members, isChannel: isChannel)
        }
        
        func createMessage(_ message: LocalMessage, recipientInfo: [String: String]) {
            
            print("Creating message...")
            
            guard let recipientId = recipientInfo["id"],
                  let recipientLang = recipientInfo["lang"] else { return }
            
            let sender = ChannelMember(id: message.senderId, lang: message.senderLang)
            let recipient = ChannelMember(id: recipientId, lang: recipientLang)
            
            send(message: message, members: [sender, recipient], isChannel: false)
        }
        
        func createChannelMessage(_ message: LocalMessage) {
            
            print("Creating channel message...")
            
            FirebaseReference(.Channel).document(message.chatRoomId).collection(kUSER).getDocuments { [weak self] (snapshot, error) in
                
                guard let documents = snapshot?.documents else {
                    print("No documents for channel members")
                    return
                }
                
                let members = documents.compactMap {
                    try? $0.data(as: ChannelMember.self)
                }
                
                self?.send(message: message, members: members, isChannel: true)
            }
        }
        
        // TODO: LocalMessage新規作成の際に、sourceLang, transLang, sourceMessage, transMessage
        // などのプロパティを新規追加する
//        func createNewLocalMessage(_ message: LocalMessage, translatedText: String) -> LocalMessage {
//
//            // 一度Realmにオブジェクトを保存すると、その後手元でプロパティを更新するとエラーになる
//            //　更新処理はRealmのトランザクション内で行う必要あり
//            //　おそらくプライマリーキー（id）でRealmに保存済みかどうかを判断している？
//            // そのため、RealmではなくFirestoreで管理したいオブジェクトは新規作成する必要あり
//            let newMessage = LocalMessage()
//            newMessage.message = translatedText
//            newMessage.id = message.id
//            newMessage.chatRoomId = message.chatRoomId
//            newMessage.senderId = message.senderId
//            newMessage.senderName = message.senderName
//            newMessage.senderLang = message.senderLang
//            newMessage.senderInitials = message.senderInitials
//            newMessage.date = message.date
//            newMessage.type = message.type
//
//            return newMessage
//        }
        
        func addMessage(message: LocalMessage, members: [ChannelMember], isChannel: Bool) {
            
            let messageRef = FirebaseReference(isChannel ? .Channel : .Chat) .document(message.chatRoomId).collection(kMESSAGE).document(message.id)
            
            let batch = Firestore.firestore().batch()
            do {
                try batch.setData(from: message, forDocument: messageRef)
                
                for member in members {
                    if member.id == User.currentId { continue }
                    
                    let readStatusRef = messageRef.collection(kREADSTATUS).document(member.id)
                    batch.setData([kISREAD: false], forDocument: readStatusRef)
                }
                
            } catch {
                print("error saving messages", error.localizedDescription)
            }
            
            batch.commit()
        }

//        func updateJoiningChats(message: LocalMessage, lang: String, membersDic: [String: Any], isChannel: Bool) {
//
//            guard let userIdsByLang = membersDic["userIdsByLang"] as? [String: [String]],
//                  let memberIds = userIdsByLang[lang] else { return }
//
//            FirebaseRecentListener.shared.updateJoiningRooms(message: message, memberIds: memberIds, isChannel: isChannel)
//        }
        
        // MARK: - Update Message Status
        func updateReadStatus(chatRoomId: String, message: LocalMessage, isChannel: Bool) {
            
            print("Updating read counter and status...")
            
            let batch = Firestore.firestore().batch()
            
            let msgDocRef = FirebaseReference(isChannel ? .Channel : .Chat).document(chatRoomId).collection(kMESSAGE).document(message.id)
            
            let readStatusRef = msgDocRef.collection(kREADSTATUS).document(User.currentId)
            
            batch.updateData(["isRead": true], forDocument: readStatusRef)
            
            // messageのreadCounterのインクリメントをどこで行うか要検討
            // クライアント側 or バックエンド側
            //        batch.updateData([
            //            "readCounter": FieldValue.increment(1.0),
            //            kREADDATE: Date()
            //        ], forDocument: msgDocRef)
            
            // Firestoreに反映
            batch.commit()
        }
        
        func removeListeners() {
            newChatListener.remove()
            
            if updatedChatListener != nil {
                updatedChatListener.remove()
            }
        }
    }
