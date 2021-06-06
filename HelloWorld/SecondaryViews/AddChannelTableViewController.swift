//
//  AddChannelTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/02.
//

import UIKit
import Gallery
import ProgressHUD

class AddChannelTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var aboutTextField: UITextView!
        
    // MARK: - Vars
    var channelId = UUID().uuidString
    var avatarLink = ""
    var gallery: GalleryController!
    var tapGesture = UITapGestureRecognizer()
    
    var editChannel: JoiningChannel?
    var channelLangs: [String] = []
    var channelType: String = ""
    var channelTheme: String = ""
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // segueを使ってMyChannelsTableViewController から遷移している
        // AddChannelTableViewControllerのインスタンスが生成されているわけではない
        // ため、初回以外は呼ばれない？
        print("AddChannelTableViewController viewDidLoad")
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        configureChannelLangs()
        configureGestures()
        configureLeftBarButton()
        configureEditingView()
    }
    
    // MARK: - IBActions
    @IBAction func selectChannelLangs(_ sender: Any) {
        let channelLangTVC = ChannelLangTableViewController()
        channelLangTVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(channelLangTVC, animated: true)
    }
    
    @IBAction func selectChannelType(_ sender: Any) {
        let channelTypeTVC = ChannelTypeTableViewController()
        channelTypeTVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(channelTypeTVC, animated: true)
    }
    
    @IBAction func selectChannelTheme(_ sender: Any) {
        let channelThemeTVC = ChannelThemeTableViewController()
        channelThemeTVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(channelThemeTVC, animated: true)
    }
    
    private func configureChannelLangs() {
        let currentUser = User.currentUser!
        if currentUser.lang == "en" {
            channelLangs = ["en"]
            
        } else {
            channelLangs = [currentUser.lang, "en"]
        }
    }
    
    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - IBActions
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        if nameTextField.text == "" {
            ProgressHUD.showError("Channel name is required.")
            return
        }
        
        editChannel != nil ? edit() : add()
    }
    
    @objc func avatarImageTapped() {
        print("tap on avatar image...")
        showGallery()
    }
    
    @objc func backButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Configurations
    private func configureGestures() {
        tapGesture.addTarget(self, action: #selector(avatarImageTapped))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    }
    
    private func configureLeftBarButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonPressed))
    }
    
    private func configureEditingView() {
        
        guard let channel = editChannel else {
            title = "Add Channel"; return
        }
        
        title = "Edit Channel"
        channelId = channel.id
        nameTextField.text = channel.name
        aboutTextField.text = channel.aboutChannel
        avatarLink = channel.avatarLink
        setAvater()
    }

    // MARK: - Save Channel
    private func add() {
        
        print("Save new channel")
        
        let joiningCh = JoiningChannel(id: channelId,
                                            name: nameTextField.text!,
                                            avatarLink: avatarLink,
                                            aboutChannel: aboutTextField.text,
                                            isAdmin: true)
        
        
        FirebaseChannelListener.shared.saveChannel(joiningCh: joiningCh)
        
        navigationController?.popViewController(animated: true)
    }
    
    private func edit() {
        guard var channel = editChannel else { return }
        
        channel.name = nameTextField.text!
        channel.aboutChannel = aboutTextField.text
        channel.avatarLink = avatarLink
        
        // save channel to Firebase
        FirebaseChannelListener.shared.saveChannel(joiningCh: channel)
        
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Gallery
    private func showGallery() {
        gallery = GalleryController()
        gallery.delegate = self
        Config.tabsToShow = [.imageTab, .cameraTab]
        Config.Camera.imageLimit = 1
        Config.initialTab = .imageTab
        
        present(gallery, animated: true)
    }
    
    // MARK: - Avatar
    private func uploadAvatarImage(_ image: UIImage) {
        
        // UIImageをJPEGに変換し、さらにNSDataに変換
        let jpegData = image.jpegData(compressionQuality: 0.7)! as NSData
        FileStorage.saveFileLocally(fileData: jpegData, fileName: channelId)
        
        let fileDirectory = "Avatars/_\(channelId).jpg"
        FileStorage.uploadImage(image, directory: fileDirectory) { [weak self] avatarLink in
            self?.avatarLink = avatarLink ?? ""
        }
    }
    
    private func setAvater() {
        if avatarLink.isEmpty {
            avatarImageView.image = UIImage(named: "avatar")
            return
        }
        
        FileStorage.downloadImage(imageUrl: avatarLink) { [weak self] avatarImage in
            self?.avatarImageView.image = avatarImage != nil ? avatarImage!.circleMasked : UIImage(named: "avatar")
        }
    }

}

extension AddChannelTableViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        
        if images.count <= 0 { return }
        
        // 選択された画像をUIImageに変換
        images.first?.resolve { [weak self] avatarImage in
            
            guard let image = avatarImage else {
                ProgressHUD.showFailed("Failed to select image.")
                return
            }
            
            self?.avatarImageView.image = image.circleMasked
            self?.uploadAvatarImage(image)
            print("get icon successfully.")
        }
        
        controller.dismiss(animated: true)
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true)
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        controller.dismiss(animated: true)
    }
    
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true)
    }
    
    
}
