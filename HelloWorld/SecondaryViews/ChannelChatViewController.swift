//
//  ChannelChatViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/03.
//

import Foundation
import MessageKit
import InputBarAccessoryView
import Gallery
import RealmSwift
import IQAudioRecorderController
import ProgressHUD
import CoreLocation

class ChannelChatViewController: MessagesViewController {

    // MARK: - Views
//    let leftBarButtonView: UIView = {
//        return UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
//    }()
//
//    let titleLabel: UILabel = {
//        let title = UILabel(frame: CGRect(x: 5, y: 0, width: 180, height: 25))
//        title.textAlignment = .left
//        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        title.adjustsFontSizeToFitWidth = true
//        return title
//    }()
    
//    let subTitleLabel: UILabel = {
//        let subTitle = UILabel(frame: CGRect(x: 5, y: 22, width: 180, height: 20))
//        subTitle.textAlignment = .left
//        subTitle.font = UIFont.systemFont(ofSize: 13, weight: .medium)
//        subTitle.adjustsFontSizeToFitWidth = true
//        return subTitle
//    }()
    
    // MARK: - Vars
    private var chatId = ""
    private var recipientId = ""
    private var recipientName = ""
    
    var channel: Channel!
    
    // lazy: 毎回BasicAudioControllerのインスタンスを取得（初期化）するのではなく、
    // マイクボタンがクリックされた時のみ初期化
    open lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
    
    let currentUser = MKSender(senderId: User.currentId, displayName: User.currentUser!.username)
    let refreshController = UIRefreshControl()
    let micButton = InputBarButtonItem()
    
    var mkMessages: [MKMessage] = []
    var allLocalMessages: Results<LocalMessage>!
    
    let realm = try? Realm()
    
    var displayingMessagesCount = 0
    var maxMessageNumber = 0
    var minMessageNumber = 0
//    var typingCounter = 0
    
    var gallery: GalleryController!
    
    // Listeners
    var notificationToken: NotificationToken?
    
    var longPressGesture: UILongPressGestureRecognizer!
    var audioFileName = ""
    var audioDuration: Date!
    
    
    // MARK: - Inits
    init(channel: Channel) {
        super.init(nibName: nil, bundle: nil)
        self.chatId = channel.id
        self.recipientId = channel.id
        self.recipientName = channel.name
        self.channel = channel
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ChatView's viewDidLoad is executed...")
        
        navigationItem.largeTitleDisplayMode = .never
        
//        createTypingObserver()
        
        configureMessageCollectionView()
        configureGestureRecognizer()
        configureMessageInputBar()
        configureLeftBarButton()
        configureCustomTitle()
        loadChats()
        listenForNewChats()
        
//        updateTextForTypingIndicator(false)
//        listenForReadStatusChange()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseRecentListener.shared.resetRecentCounter(chatRoomId: chatId)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FirebaseRecentListener.shared.resetRecentCounter(chatRoomId: chatId)
        audioController.stopAnyOngoingPlaying()
    }
    
    // MARK: - Configurations
    private func configureMessageCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self

        // InputTextBarを編集した時に、画面を最下部までスクロールすることで
        // 常に最新メッセージを表示するようにする
        scrollsToBottomOnKeyboardBeginsEditing = true

        maintainPositionOnKeyboardFrameChanged = true

        messagesCollectionView.refreshControl = refreshController
    }
    
    private func configureGestureRecognizer() {
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(recordAudio))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
    }

    private func configureMessageInputBar() {
        
        // adminユーザー以外はメッセージを送信できない
        messageInputBar.isHidden = channel.adminId != User.currentId

        messageInputBar.delegate = self
        let attachButton = InputBarButtonItem()
        attachButton.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        attachButton.setSize(CGSize(width: 30, height: 30), animated: false)
        attachButton.onTouchUpInside { [weak self] item in
            self?.attachActionMessage()
        }

        micButton.image = UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        micButton.setSize(CGSize(width: 30, height: 30), animated: false)
        micButton.addGestureRecognizer(longPressGesture)

        messageInputBar.setStackViewItems([attachButton], forStack: .left, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        
        updateMicButtonStatus(show: true)

        // InputTextBarに画像をペーストできないようにする
        messageInputBar.inputTextView.isImagePasteEnabled = false

        // デバイスの設定に合わせて背景色を変更（Normal or Dark）
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.inputTextView.backgroundColor = .systemBackground
    }
    
    func updateMicButtonStatus(show: Bool) {
        if show {
            messageInputBar.setStackViewItems([micButton], forStack: .right, animated: false)
            messageInputBar.setRightStackViewWidthConstant(to: 30, animated: false)
            return
        }
        
        messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 55, animated: false)
    }
    
    private func configureLeftBarButton() {
        navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonPressed))]
    }
    
    private func configureCustomTitle() {
        title = channel.name
    }
    
    // MARK: - Load Chats
    private func loadChats() {
        
        // Realm（ローカルストレージ）からチャットデータを取得
        let predicate = NSPredicate(format: "chatRoomId = %@", chatId)
        allLocalMessages = realm?.objects(LocalMessage.self)
            .filter(predicate)
            .sorted(byKeyPath: kDATE, ascending: true)
        
        // Realm（ローカルストレージ）にデータが存在しない場合
        // Firestoreからメッセージを取得し、Realmに保存
        if allLocalMessages.isEmpty {
            checkForOldChats()
        }
        
        // リスナーを停止する際は、invalidateメソッドを呼ぶ
        notificationToken = allLocalMessages.observe { [weak self] (changes: RealmCollectionChange) in
            
            guard let strongSelf = self else { return }
            
            switch changes {
            case .initial:
                print("initial")
                strongSelf.insertMessages()
                strongSelf.messagesCollectionView.reloadData()
                strongSelf.messagesCollectionView.scrollToBottom(animated: true)
                
            case .update(_, _, let insertions, _):
                // checkForOldChatsメソッド内でFirestoreからメッセージを取得し、
                // Realmに保存するとこのブロックに入ってくる
                // トリガーは、Realmへのデータ追加・変更？（changesがRealmCollectionChange型のため）
                // Realmへのデータ追加、変更は、allLocalMessagesに自動で反映されると思われる
                // 以下の処理で、allLocalMessages[index]で追加したデータにアクセスできる
                print("Start updating...")
                // Realmに5件メッセージを保存した場合、insertionsには[1], [2], [3], [4], [5]
                // というようにindexの配列がその都度入ってくる
                // indexの値は、既存のallLocalMessagesの個数に、その都度新たな要素を追加した数になる
                for index in insertions {
                    print("insertions", insertions)
                    print("index", index)
                    strongSelf.insertMessage(strongSelf.allLocalMessages[index])
                    strongSelf.messagesCollectionView.reloadData()
                    strongSelf.messagesCollectionView.scrollToBottom(animated: false)
                }
                
            case .error(let error):
                print("Error on new insertions", error.localizedDescription)
            }
        }
    }
    
    private func listenForNewChats() {
        FirebaseMessageListener.shared.listenForNewChats(User.currentId, collectionId: chatId, lastMessageDate: lastMessageDate())
    }

    private func checkForOldChats() {
        FirebaseMessageListener.shared.checkForOldChats(User.currentId, collectionId: chatId)
    }
    
//    private func listenForReadStatusChange() {
//        FirebaseMessageListener.shared.listenForReadStatusChange(User.currentId, collectionId: chatId) { [weak self] updatedMessage in
//            // markMessageAsReadメソッド内では、チャット相手が送信したメッセージかつ未読のもの以外は、既読処理をスルーする仕様
//            // そのため、FirebaseMessageListenerのlistenForReadStatusChangeメソッドで変更を検知するのは、
//            // チャット相手が送信したメッセージ、かつ未読のものに限られる
//            // そのため、このクロージャーで受け取るメッセージのステータスは、Read以外入ってこないはず
//            if updatedMessage.status != kREAD { return }
//            print("updated message", updatedMessage.message)
//            print("updated status", updatedMessage.status)
//            self?.updateMessage(updatedMessage)
//        }
//    }

    // MARK: - Insert Messages
    // 初回ロード時のみ実行（initial）
    private func insertMessages() {
        
        print("all local messages(insertMessages)", allLocalMessages.count)
        
        maxMessageNumber = allLocalMessages.count - displayingMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        // Realmにデータが存在しない場合、allLocalMessagesが0になる
        // そのため、以下の処理は実行されない
        for index in minMessageNumber ..< maxMessageNumber {
            let localMessage = allLocalMessages[index]
            insertMessage(localMessage)
        }
    }
    
    private func insertMessage(_ localMessage: LocalMessage) {
        print("insert message")

        // 各メッセージを既読にする
        // Incoming, かつ未読であれば既読に変更
//        markMessageAsRead(localMessage)

        let incoming = IncomingMessage(self)

        // LocalMessage を MKMessage に変換
        guard let mkMessage = incoming.createMessage(localMessage: localMessage) else { return }
        print("mkMessage image", mkMessage.photoItem?.image == nil ? "Image is nil" : "Get image successfully")
        mkMessages.append(mkMessage)

        displayingMessagesCount += 1
    }
    
    private func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        maxMessageNumber = minNumber - 1
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for index in (minMessageNumber ... maxMessageNumber).reversed() {
            insertOlderMessage(allLocalMessages[index])
        }
    }
    
    private func insertOlderMessage(_ localMessage: LocalMessage) {
        let incoming = IncomingMessage(self)

        // LocalMessage を MKMessage に変換
        guard let mkMessage = incoming.createMessage(localMessage: localMessage) else { return }
        mkMessages.insert(mkMessage, at: 0)
        displayingMessagesCount += 1
    }
    
//    private func insertOlderMessage(_ localMessage: LocalMessage) {
//        let mkMessage = MKMessage(message: localMessage)
//
//        if localMessage.type == kTEXT {
//            mkMessages.insert(mkMessage, at: 0)
//            displayingMessagesCount += 1
//        }
//
//        if localMessage.type == kPHOTO {
//            FileStorage.downloadImage(imageUrl: localMessage.pictureUrl) { [weak self] image in
//
//                guard let strongSelf = self else { return }
//
//                // UIの更新はMainスレッドで行う必要あり
//                mkMessage.photoItem?.image = image
//                strongSelf.messagesCollectionView.reloadData()
//
//                strongSelf.mkMessages.insert(mkMessage, at: 0)
//                strongSelf.displayingMessagesCount += 1
//            }
//        }
//    }
    
    // insertMessage内で呼び出し
//    private func markMessageAsRead(_ localMessage: LocalMessage) {
//        // チャット相手が送信したメッセージ、かつ未読のものだけを既読にする
//        if (localMessage.senderId == User.currentId) || localMessage.status == kREAD { return }
//        FirebaseMessageListener.shared.updateMessageInFirebase(localMessage, memberIds: [User.currentId, recipientId])
//    }
    
    // MARK: - Actions
    func sendMessage(text: String?, photo: UIImage?, video: Video?, location: String?, coordinate: CLLocationCoordinate2D? = nil, audio: String?, audioDuration: Float = 0.0) {
        
        OutgoingMessage.sendChannel(channel: channel,
                                    text: text,
                                    photo: photo,
                                    video: video,
                                    location: location,
                                    coordinate: coordinate,
                                    audio: audio,
                                    audioDuration: audioDuration)
                                    
    }
    
    @objc func backButtonPressed() {
        FirebaseRecentListener.shared.resetRecentCounter(chatRoomId: chatId)
        removeListener()
        LocationManager.shared.stopUpdating()
        navigationController?.popViewController(animated: true)
    }
    
    private func attachActionMessage() {
        
        // キーボードを非表示にする
        messageInputBar.inputTextView.resignFirstResponder()
        
        let options = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let camera = UIAlertAction(title: "Camera", style: .default) { [weak self] alert in
            self?.showImageGallery(camera: true)
        }
        
        let library = UIAlertAction(title: "Library", style: .default) { [weak self] alert in
            self?.showImageGallery(camera: false)
        }

        let userLocation = UIAlertAction(title: "Share your location", style: .default) { [weak self] alert in
            self?.shareUserLocation()
        }
        
        let otherLocation = UIAlertAction(title: "Share other location", style: .default) { [weak self] alert in
            self?.showLocationPicker()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        camera.setValue(UIImage(systemName: "camera"), forKey: "image")
        library.setValue(UIImage(systemName: "photo.fill"), forKey: "image")
        userLocation.setValue(UIImage(systemName: "mappin.circle"), forKey: "image")
        otherLocation.setValue(UIImage(systemName: "mappin.and.ellipse"), forKey: "image")
        
        options.addAction(camera)
        options.addAction(library)
        options.addAction(userLocation)
        options.addAction(otherLocation)
        options.addAction(cancel)
        present(options, animated: true)
    }
    
    private func shareUserLocation() {
        
        print("Share Location")
        
        if LocationManager.shared.authStatus == kNOTDETERMINED {
            print("status >>> not determined")
            LocationManager.shared.configureLocationManager()
            return
        }

        if LocationManager.shared.authStatus == kDENIED {
            print("status >>> denied")
            ProgressHUD.showFailed("Please allow access to location in Settings.")
            return
        }
        
        if !LocationManager.shared.isUpdatelocation {
            LocationManager.shared.startUpdating()
            // 0.000001秒スリープする
            usleep(1)
            print("sleeping for 0.000001 sec")
        }

        sendMessage(text: nil, photo: nil, video: nil, location: kLOCATION, audio: nil)
    }
    
    private func showLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] coordinate in
            
            self?.sendMessage(text: nil, photo: nil, video: nil, location: kLOCATION, coordinate: coordinate, audio: nil)
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
//    func createTypingObserver() {
//        FirebaseTypingListener.shared.createTypingObserver(chatRoomId: chatId) { [weak self] isTyping in
//
//            DispatchQueue.main.async {
//                self?.updateTextForTypingIndicator(isTyping)
//            }
//        }
//    }
    
//    func updateTypingIndicator() {
//        typingCounter += 1
//        FirebaseTypingListener.saveTypingCounter(isTyping: true, chatRoomId: chatId)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
//            self?.stopTypingCounter()
//        }
//    }

//    func stopTypingCounter() {
//        typingCounter -= 1
//
//        if typingCounter == 0 {
//            FirebaseTypingListener.saveTypingCounter(isTyping: false, chatRoomId: chatId)
//        }
//    }
    
    // MARK: - Update Typing Indicator
//    func updateTextForTypingIndicator(_ show: Bool) {
//        subTitleLabel.text = show ? "\(recipientName) is typing..." : ""
//    }
    
    // MARK: - UIScroll View Delegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !refreshController.isRefreshing { return }
        if displayingMessagesCount >= allLocalMessages.count {
            refreshController.endRefreshing()
            return
        }
        loadMoreMessages(maxNumber: maxMessageNumber, minNumber: minMessageNumber)
        messagesCollectionView.reloadDataAndKeepOffset()
    }
    
    // MARK: - Update Read Message Status
    // FirestoreへのReadステータスの変更を検知して、ローカルストレージのデータを変更
//    private func updateMessage(_ localMessage: LocalMessage) {
//        for index in 0 ..< mkMessages.count {
//            let message = mkMessages[index]
//            if message.messageId != localMessage.id { continue }
//
//            message.status = localMessage.status
//            message.readDate = localMessage.readDate
//            mkMessages[index] = message
//
//            RealmManager.shared.saveToRealm(localMessage)
//
//            if message.status == kREAD {
//                messagesCollectionView.reloadData()
//            }
//        }
//    }
    
    // MARK: - Helpers
    private func removeListener() {
//        FirebaseTypingListener.shared.removeTypingListener()
        FirebaseMessageListener.shared.removeListeners()
    }
    
    private func lastMessageDate() -> Date {
        let lastMessageDate = allLocalMessages.last?.date ?? Date()
        return Calendar.current.date(byAdding: .second, value: 1, to: lastMessageDate) ?? lastMessageDate
    }

    // MARK: - Gallery
    private func showImageGallery(camera: Bool) {
        gallery = GalleryController()
        gallery.delegate = self
        
        Config.tabsToShow = camera ? [.cameraTab] : [.imageTab, .videoTab]
        Config.Camera.imageLimit = 1
        Config.initialTab = .imageTab
        Config.VideoEditor.maximumDuration = 30
        
        present(gallery, animated: true)
    }
}

extension ChannelChatViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        if images.isEmpty {
            controller.dismiss(animated: true)
            return
        }
        
        images.first!.resolve { [weak self] image in
            self?.sendMessage(text: nil, photo: image, video: nil, location: nil, audio: nil)
        }
        
        controller.dismiss(animated: true)
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        sendMessage(text: nil, photo: nil, video: video, location: nil, audio: nil)
        controller.dismiss(animated: true)
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        controller.dismiss(animated: true)
    }
    
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Audio Messages
extension ChannelChatViewController: IQAudioRecorderViewControllerDelegate {
    
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        controller.dismiss(animated: true)
        
        var duration: Float = 0.0
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: URL(string: filePath)!)
            duration = Float(audioPlayer.duration)
            
        } catch {
            print("Failed creating audio player", error.localizedDescription)
            return
        }
        
        print("duration", "\(duration)")
                    
        sendMessage(text: nil, photo: nil, video: nil, location: nil, audio: filePath, audioDuration: duration)
    }
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true)
    }
    
    @objc func recordAudio() {
        let audioVC = AudioViewController(delegate: self)
        audioVC.presentAudioRecorder(target: self)
    }
}
