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
    var gallery: GalleryController!
    var tapGesture = UITapGestureRecognizer()
    var avatarLink = ""
    var channelId = UUID().uuidString
    
    var channelToEdit: Channel?
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        configureGestures()
        configureLeftBarButton()
        configureEditingView()
        
    }
    
    // MARK: - IBActions
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        if nameTextField.text == "" {
            ProgressHUD.showError("Channel name is required.")
            return
        }
        
        channelToEdit != nil ? editChannel() : saveChannel()
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
        
        guard let channel = channelToEdit else { return }
        
        title = "Edit Channel"
        channelId = channel.id
        nameTextField.text = channel.name
        aboutTextField.text = channel.aboutChannel
        avatarLink = channel.avatarLink
        
        setAvater()
        
    }
    
    // MARK: - Save Channel
    private func saveChannel() {
        let channel = Channel(id: channelId, name: nameTextField.text!, adminId: User.currentId, memberIds: [User.currentId], avatarLink: avatarLink, aboutChannel: aboutTextField.text)
        
        // save channel to Firebase
        FirebaseChannelListener.shared.saveChannel(channel)
        
        navigationController?.popViewController(animated: true)
    }
    
    private func editChannel() {
        guard var channel = channelToEdit else { return }
        
        channel.name = nameTextField.text!
        channel.aboutChannel = aboutTextField.text
        channel.avatarLink = avatarLink
        
        // save channel to Firebase
        FirebaseChannelListener.shared.saveChannel(channel)
        
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
