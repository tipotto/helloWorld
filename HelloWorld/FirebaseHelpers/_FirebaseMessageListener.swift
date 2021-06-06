////
////  FirebaseMessageListener.swift
////  HelloWorld
////
////  Created by egamiyuji on 2021/01/18.
////
//
//import Foundation
//import Firebase
//import FirebaseFirestoreSwift
//import RealmSwift
//
//class _FirebaseMessageListener {
//
//    static let shared = _FirebaseMessageListener()
//    var newChatListener: ListenerRegistration!
//    var updatedChatListener: ListenerRegistration!
//
//    var translateCounter = 0
//    var fetchedMessageCounter = 0
//
//    private init() {}
//
//    func listenForNewChats(channelId: String, lastMessageDate: Date, isChannel: Bool = false) {
//
//        // TODO: jaの代わりにuserLangを設定する
//        guard let currentUser = User.currentUser else { return }
//
//        let currentUserMsgRef = FirebaseReference(isChannel ? .Channel : .Chat).document(channelId).collection("Lang").document(currentUser.lang).collection("Message")
//
//        newChatListener = currentUserMsgRef
//            .whereField(kDATE, isGreaterThan: lastMessageDate)
//            .addSnapshotListener { [weak self] (snapshot, error) in
//
//                guard let snapshot = snapshot else { return }
//
//                for change in snapshot.documentChanges {
//                    if change.type != .added { continue }
//                    print("New document is added")
//
//                    let result = Result {
//                        try? change.document.data(as: LocalMessage.self)
//                    }
//
//                    switch result {
//                    case .success(let message):
//                        guard let message = message else { break }
//
//                        // Outgoingメッセージはスルーする（チャンネルの場合）
//                        // WhereFieldクエリで制限したかったが、Firestoreにクエリ制限があるため不可
//                        if message.senderId == User.currentId { break }
//
//                        // ここではIncomingメッセージのみを保存する
//                        // Outgoingメッセージは、送信時にRealmに保存する
//                        // そのためFirestoreへの反映をこのリスナーで検知した時点ではなく、
//                        // 送信時にRealmに保存された時点で、mkMessageに変換・表示される仕様
//
//                        RealmManager.shared.saveToRealm(message)
//                        print("Finish saving message to realm")
//
//                        self?.changeReadStatus(channelId: channelId, message: message, isChannel: isChannel)
//
//                    case .failure(let error):
//                        print("error decoding local messages", error.localizedDescription)
//                    }
//                }
//            }
//    }
//
//    func listenForReadStatusChange(channelId: String, isChannel: Bool = false) {
//
//        guard let currentUser = User.currentUser else { return }
//
//        let messageRef = FirebaseReference(isChannel ? .Channel : .Chat).document(channelId).collection("Lang").document(currentUser.lang).collection("Message")
//
//        updatedChatListener = messageRef
//            .whereField(kSENDERID, isEqualTo: User.currentId)
////            .whereField(kREADCOUNTER, isGreaterThan: 0)
////            .whereField(kREADCOUNTER, isNotEqualTo: 0)
//            .addSnapshotListener { (snapshot, error) in
//
//                guard let snapshot = snapshot else { return }
//
//                for change in snapshot.documentChanges {
//                    if change.type != .modified { continue }
//
////                    if change.document.metadata.hasPendingWrites {
////                        print("Local")
////                        continue
////                    }
//
//                    print("detect read status change")
//
//                    let result = Result {
//                        try? change.document.data(as: LocalMessage.self)
//                    }
//
//                    switch result {
//                    case .success(let message):
//                        guard let message = message else { break }
//                        if message.readCounter <= 0 { break }
//
//                        RealmManager.shared.saveToRealm(message)
//
//                    case .failure(let error):
//                        print("Error decoding local message", error.localizedDescription)
//                    }
//                }
//            }
//    }
//
//    func checkForOldChats(channelId: String, isChannel: Bool, completion: @escaping (_ isChannelJoined: Bool) -> Void) {
//
//        print("Checking for old chats...")
//
//        guard let currentUser = User.currentUser else { return }
//
//        let query = FirebaseReference(isChannel ? .Channel : .Chat).document(channelId)
//            .collection("Lang").document(currentUser.lang)
//            .collection("Message")
//            .order(by: "date", descending: true)
//
//        query
//            .limit(to: kDISPLAYMESSAGESNUMBER)
//            .getDocuments { [weak self] (snapshot, error) in
//
//                guard let result = self?.moldMessages(snapshot: snapshot),
//                      let messages = result["messages"] as? [LocalMessage],
//                      let cursor = result["cursor"] as? QueryDocumentSnapshot else {
//                    print("Failed to get documents in checkForOldChats...")
//                    completion(true)
//                    return
//                }
//
//                // TODO: 最初にユーザーに表示するメッセージ（12件）をローカル翻訳・Realmに保存
//                print("Saving old messages to realm...")
//                for message in messages {
//                    RealmManager.shared.saveToRealm(message)
//                }
//
//                for message in messages {
//                    self?.changeReadStatus(channelId: channelId, message: message, isChannel: isChannel)
//                }
//
//                self?.fetchMessagesByCursor(channelId: channelId, query: query, cursor: cursor, currentUser: currentUser, isChannel: isChannel) { _ in
//                    completion(false)
//                }
//            }
//    }
//
//    func translate(_ message: LocalMessage, userLang: String, langColRef: CollectionReference, isFirstQuery: Bool = false, completion: ((_ isCompleted: Bool) -> Void)? = nil) {
//
//        TranslationManager.shared.translate(textToTranslate: message.message, langArr: [userLang], sourceLangCode: "en") { [weak self] translatedText, _ in
//
//            guard let strongSelf = self else { return }
//
//            // transLang は常にユーザー言語
//            guard let transText = translatedText else {
//                print("Error translating text...")
//                return
//            }
//
//            // Realmへ更新を反映（notificationに通知する）
//            // localMessageを新規作成
//            let newMessage = strongSelf.createNewLocalMessage(message, translatedText: transText)
//
//            if isFirstQuery {
//                print("Updating translated text to realm...")
//                RealmManager.shared.updateMessage(message, text: transText)
//
//            } else {
//                guard let token = ChannelChatViewController.notificationToken else {
//                    print("Failed to get notification token...")
//                    return
//                }
//                print("Updating message without notifying to realm...")
//                RealmManager.shared.saveWithoutNotifying(newMessage, token: token)
//            }
//
//            let messageRef = langColRef.document(userLang).collection("Message").document(message.id)
//            do {
//                try messageRef.setData(from: newMessage)
//
//            } catch {
//                print("error saving messages", error.localizedDescription)
//            }
//
//            strongSelf.translateCounter += 1
//
//            if !isFirstQuery
//                && strongSelf.translateCounter == strongSelf.fetchedMessageCounter {
//
//                print("Finish translating texts...")
//                print("translate counter", strongSelf.translateCounter)
//                print("fetched message counter", strongSelf.fetchedMessageCounter)
//
//                completion!(true)
//            }
//        }
//    }
//
//    func moldMessages(snapshot: QuerySnapshot?) -> [String: Any]? {
//
//        guard let documents = snapshot?.documents, documents.first != nil else {
//            print("No documents found...")
//            return nil
//        }
//
//        guard let lastSnapshot = documents.last else { return nil }
//
//        var messages = documents.compactMap {
//            try? $0.data(as: LocalMessage.self)
//        }
//
//        // 順番を逆順にソート（古いもの順に並び替え）
//        messages.sort { $0.date < $1.date }
//
//        fetchedMessageCounter += messages.count
//
//        return [
//            "messages": messages,
//            "cursor": lastSnapshot
//        ]
//    }
//
//    func translateInNewLang(channelId: String, completion: @escaping (_ isCompleted: Bool) -> Void) {
//        print("Translating in new lang...")
//
//        guard let currentUser = User.currentUser else { return }
//
//        let langColRef = FirebaseReference(.Channel).document(channelId)
//            .collection("Lang")
//
//        let query = langColRef.document("en")
//            .collection("Message")
//            .order(by: "date", descending: true)
//            .limit(to: kDISPLAYMESSAGESNUMBER)
//
//        // 新しい順に上から12件を取得
//        query.getDocuments { [weak self] (snapshot, error) in
//            guard let result = self?.moldMessages(snapshot: snapshot),
//                  let messages = result["messages"] as? [LocalMessage],
//                  let cursor = result["cursor"] as? QueryDocumentSnapshot else {
//                print("Failed to get documents in translateInNewLang...")
//                completion(false)
//                return
//            }
//
//            // 新規メッセージをRealmに追加
//            print("Insert new messages to Realm and first translate...")
//            for message in messages {
//                RealmManager.shared.saveToRealm(message)
//            }
//
//            for message in messages {
//                self?.translate(message, userLang: currentUser.lang, langColRef: langColRef, isFirstQuery: true)
//            }
//
//            self?.fetchMessagesByCursor(langColRef: langColRef, cursor: cursor, currentUser: currentUser) { _ in
//                completion(true)
//            }
//        }
//    }
//
//    func fetchMessagesByCursor(channelId: String, query: Query, cursor: QueryDocumentSnapshot, currentUser: User, isChannel: Bool, completion: @escaping (_ isCompleted: Bool) -> Void) {
//
//        query
//            .limit(to: kLOADMESSAGESNUMBER)
//            .start(afterDocument: cursor)
//            .getDocuments { [weak self] (snapshot, error) in
//
//                guard let result = self?.moldMessages(snapshot: snapshot),
//                      let messages = result["messages"] as? [LocalMessage],
//                      let cursor = result["cursor"] as? QueryDocumentSnapshot,
//                      let token = ChannelChatViewController.notificationToken else {
//                    print("No more messages are found in Firestore.")
//                    completion(true)
//                    return
//                }
//
//                print("Updating message without notifying to realm...")
//                for message in messages {
//                    RealmManager.shared.saveWithoutNotifying(message, token: token)
//
//                    self?.changeReadStatus(channelId: channelId, message: message, isChannel: isChannel)
//                }
//
//                print("Fetch more messages from Firestore.")
//                self?.fetchMessagesByCursor(channelId: channelId, query: query, cursor: cursor, currentUser: currentUser, isChannel: isChannel, completion: completion)
//            }
//    }
//
//    func fetchMessagesByCursor(langColRef: CollectionReference, cursor: QueryDocumentSnapshot, currentUser: User, completion: @escaping (_ isCompleted: Bool) -> Void) {
//
//        let query = langColRef.document("en")
//            .collection("Message")
//            .order(by: "date", descending: true)
//            .limit(to: kLOADMESSAGESNUMBER)
//
//        query
//            .start(afterDocument: cursor)
//            .getDocuments { [weak self] (snapshot, error) in
//
//                guard let result = self?.moldMessages(snapshot: snapshot),
//                      let messages = result["messages"] as? [LocalMessage],
//                      let cursor = result["cursor"] as? QueryDocumentSnapshot else {
//                    print("No more messages are found in Firestore.")
//                    completion(true)
//                    return
//                }
//
//                for message in messages {
//                    self?.translate(message, userLang: currentUser.lang, langColRef: langColRef) { [weak self] _ in
//
//                        print("Fetch more messages from Firestore.")
//                        self?.fetchMessagesByCursor(langColRef: langColRef, cursor: cursor, currentUser: currentUser, completion: completion)
//                    }
//                }
//            }
//    }
//
//    func changeReadStatus(channelId: String, message: LocalMessage, isChannel: Bool) {
//
//        if message.senderId == User.currentId { return }
//
//        print("Changing read status...")
//
//        let senderMsgRef = FirebaseReference(isChannel ? .Channel : .Chat).document(channelId).collection("Lang").document(message.senderLang).collection("Message")
//
//        let readStatusRef = senderMsgRef.document(message.id).collection("ReadStatus").document(User.currentId)
//
//        readStatusRef.getDocument { [weak self] (snapshot, error) in
//
//            guard let data = snapshot?.data() as? [String: Bool] else {
//                print("No documents for read status")
//                return
//            }
//
//            if let isRead = data["isRead"], !isRead {
//                self?.updateReadStatus(chatRoomId: channelId, message: message, isChannel: isChannel)
//            }
//        }
//    }
//
//    // MARK: - Add, Update, Delete
//    func sendMessage(message: LocalMessage, lang: String, membersDic: [String: Any], isChannel: Bool) {
//        addMessage(message: message, lang: lang, membersDic: membersDic, isChannel: isChannel)
//        updateJoiningChats(message: message, lang: lang, membersDic: membersDic, isChannel: isChannel)
//    }
//
//    func translateMessage(message: LocalMessage, membersDic: [String: Any], isChannel: Bool) {
//
//        guard let langArr = membersDic["langs"] as? [String] else { return }
//
//        TranslationManager.shared.translate(textToTranslate: message.message, langArr: langArr, sourceLangCode: message.senderLang) { [weak self] translatedText, translateLang in
//
//            guard let strongSelf = self else { return }
//
//            guard let transText = translatedText, let transLang = translateLang else {
//                print("Error translating text...")
//                return
//            }
//
//            print("Got translation results...")
//
//            // これまでと違い、transLang == senderLangの場合もlocalMessageを新規作成する
//            let newMessage = strongSelf.createNewLocalMessage(message, translatedText: transText)
//
//            strongSelf.sendMessage(message: newMessage, lang: transLang, membersDic: membersDic, isChannel: isChannel)
//        }
//    }
//
//    func createMemberInfoDic(message: LocalMessage, members: [ChannelMember]) -> [String: Any] {
//
//        print("createMemberInfoDic...")
//
//        // userIdsArrでは、senderのidは除外する
//        var userIdArr: [String] = []
//        var langArr: [String] = []
//        var userIdDic: [String: [String]] = [:]
//
//        for member in members {
//            langArr.append(member.lang)
//
//            if member.id != message.senderId {
//                userIdArr.append(member.id)
//            }
//
//            guard var userIdArrByLang = userIdDic[member.lang] else {
//                userIdDic[member.lang] = [member.id]
//                continue
//            }
//
//            userIdArrByLang.append(member.id)
//            userIdDic[member.lang] = userIdArrByLang
//        }
//
//        // 重複した言語を除去
//        let orderedSet = NSOrderedSet(array: langArr)
//        let uniqueLangArr = orderedSet.array as! [String]
//
//        print("Member info dictionary", [
//            "userIds": userIdArr,
//            "langs": uniqueLangArr,
//            "userIdsByLang": userIdDic
//        ])
//
//        return [
//            "userIds": userIdArr,
//            "langs": uniqueLangArr,
//            "userIdsByLang": userIdDic
//        ]
//    }
//
//    func send(message: LocalMessage, members: [ChannelMember], isChannel: Bool) {
//
//        print("sending...")
//
//        let membersDic = createMemberInfoDic(message: message, members: members)
//
//        if message.type == kTEXT {
//            translateMessage(message: message, membersDic: membersDic, isChannel: isChannel)
//
//        } else {
//            guard let langs = membersDic["langs"] as? [String] else { return }
//            for lang in langs {
//                sendMessage(message: message, lang: lang, membersDic: membersDic, isChannel: isChannel)
//            }
//        }
//    }
//
//    func createMessage(_ message: LocalMessage, recipientInfo: [String: String]) {
//
//        print("Creating message...")
//
//        guard let recipientId = recipientInfo["id"],
//              let recipientLang = recipientInfo["lang"] else { return }
//
//        let sender = ChannelMember(id: message.senderId, lang: message.senderLang)
//        let recipient = ChannelMember(id: recipientId, lang: recipientLang)
//
//        send(message: message, members: [sender, recipient], isChannel: false)
//    }
//
//    func createChannelMessage(_ message: LocalMessage) {
//
//        print("Creating channel message...")
//
//        FirebaseReference(.Channel).document(message.chatRoomId).collection(kUSER).getDocuments { [weak self] (snapshot, error) in
//
//            guard let documents = snapshot?.documents else {
//                print("No documents for channel members")
//                return
//            }
//
//            let members = documents.compactMap {
//                try? $0.data(as: ChannelMember.self)
//            }
//
//            self?.send(message: message, members: members, isChannel: true)
//        }
//    }
//
//    // TODO: LocalMessage新規作成の際に、sourceLang, transLang, sourceMessage, transMessage
//    // などのプロパティを新規追加する
//    func createNewLocalMessage(_ message: LocalMessage, translatedText: String) -> LocalMessage {
//
//        // 一度Realmにオブジェクトを保存すると、その後手元でプロパティを更新するとエラーになる
//        //　更新処理はRealmのトランザクション内で行う必要あり
//        //　おそらくプライマリーキー（id）でRealmに保存済みかどうかを判断している？
//        // そのため、RealmではなくFirestoreで管理したいオブジェクトは新規作成する必要あり
//        let newMessage = LocalMessage()
//        newMessage.message = translatedText
//        newMessage.id = message.id
//        newMessage.chatRoomId = message.chatRoomId
//        newMessage.senderId = message.senderId
//        newMessage.senderName = message.senderName
//        newMessage.senderLang = message.senderLang
//        newMessage.senderInitials = message.senderInitials
//        newMessage.date = message.date
//        newMessage.type = message.type
//
//        return newMessage
//    }
//
//    func addMessage(message: LocalMessage, lang: String, membersDic: [String: Any], isChannel: Bool) {
//
//        print("Adding message for lang", lang)
//
//        let messageRef = FirebaseReference(isChannel ? .Channel : .Chat) .document(message.chatRoomId).collection("Lang").document(lang).collection("Message").document(message.id)
//
//        let batch = Firestore.firestore().batch()
//        do {
//            try batch.setData(from: message, forDocument: messageRef)
//            if lang == message.senderLang {
//                guard let userIdArr = membersDic["userIds"] as? [String] else { return }
//                for userId in userIdArr {
//                    let readStatusRef = messageRef.collection("ReadStatus").document(userId)
//                    batch.setData(["isRead": false], forDocument: readStatusRef)
//                }
//            }
//
//        } catch {
//            print("error saving messages", error.localizedDescription)
//        }
//
//        // Firestoreに反映
//        batch.commit()
//    }
//
//    // TODO: LocalMessage新規作成の際に、sourceLang, transLang, sourceMessage, transMessage
//    // などをプロパティとして保持する（それにより、以下のメソッドの引数langは必要なくなる）
//    func updateJoiningChats(message: LocalMessage, lang: String, membersDic: [String: Any], isChannel: Bool) {
//
//        guard let userIdsByLang = membersDic["userIdsByLang"] as? [String: [String]],
//              let memberIds = userIdsByLang[lang] else { return }
//
//        FirebaseRecentListener.shared.updateJoiningRooms(message: message, memberIds: memberIds, isChannel: isChannel)
//
//    }
//
//    // MARK: - Update Message Status
//    func updateReadStatus(chatRoomId: String, message: LocalMessage, isChannel: Bool) {
//
//        print("Updating read counter and status...")
//
//        let batch = Firestore.firestore().batch()
//
//        let msgDocRef = FirebaseReference(isChannel ? .Channel : .Chat).document(chatRoomId).collection("Lang").document(message.senderLang).collection("Message").document(message.id)
//
//        let readStatusRef = msgDocRef.collection("ReadStatus").document(User.currentId)
//
//        batch.updateData(["isRead": true], forDocument: readStatusRef)
//        batch.updateData([
//            "readCounter": FieldValue.increment(1.0),
//            kREADDATE: Date()
//        ], forDocument: msgDocRef)
//
//        // Firestoreに反映
//        batch.commit()
//    }
//
//    func removeListeners() {
//        newChatListener.remove()
//
//        if updatedChatListener != nil {
//            updatedChatListener.remove()
//        }
//    }
//
//}
