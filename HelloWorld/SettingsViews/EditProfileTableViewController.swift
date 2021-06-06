//
//  EditProfileTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/12.
//

import UIKit
import Gallery
import ProgressHUD

class EditProfileTableViewController: UITableViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var userlangLabel: UILabel!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    // MARK: - Vars
    var gallery: GalleryController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        configureTextField()
        
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showUserInfo()
    }
    
    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")
        
        return headerView
    }
    
    // 各セクションのヘッダーの高さを指定
    // 最初のセクションのヘッダーのみ、高さを0に設定
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0 : 15.0
    }
    
    // セルがクリックされた場合の処理
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // 特定のsection（row）が選択された時に、
        // 選択状態を意味するハイライトを自動解除する。（deselectRowメソッド）
        // この処理をしないと、他のsectionをクリックするまでハイライトされたままになる。
        tableView.deselectRow(at: indexPath, animated: true)
        
        // TODO: Show status view
        if !(indexPath.section == 1 && indexPath.row == 0) { return }
        performSegue(withIdentifier: "EditProfileToLangSeg", sender: self)
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        showImageGallery()
    }

    // MARK: - Update UI
    private func showUserInfo() {
        
        guard let user = User.currentUser else { return }
        
        usernameTextField.text = user.name
        userlangLabel.text = "Language Settings"
        
        // download and set avatar image
        FileStorage.downloadImage(imageUrl: user.avatarLink) { [weak self] avatarImage in
            guard let strongSelf = self else { return }
            
            guard let image = avatarImage else {
                strongSelf.avatarImageView.image = UIImage(named: "avatar")!
                return
            }
            
            strongSelf.avatarImageView.image = image.circleMasked
        }
    }
    
    // MARK: - Configure
    private func configureTextField() {
        usernameTextField.delegate = self
        usernameTextField.clearButtonMode = .whileEditing
    }
    
    // MARK: - Gallery
    private func showImageGallery() {
        gallery = GalleryController()
        gallery.delegate = self
        
        Config.tabsToShow = [.imageTab, .cameraTab]
        Config.Camera.imageLimit = 1
        Config.initialTab = .imageTab
        
        present(gallery, animated: true)
    }
    
    // MARK: - Upload images
    private func uploadImage(_ image: UIImage) {
        
        let fileDirectory = "Avatars/" + "_\(User.currentId)" + ".jpg"
        
        FileStorage.uploadImage(image, directory: fileDirectory) { avatarLink in
            
            guard var user = User.currentUser else { return }
            user.avatarLink = avatarLink ?? ""
            saveUserLocally(user)
            FirebaseUserListener.shared.saveUserToFireStore(user)
            
            // Save image locally
            guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }
            
            FileStorage.saveFileLocally(fileData: imageData as NSData, fileName: User.currentId)
        }
    }
    
}

extension EditProfileTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField != usernameTextField { return true }
        if textField.text == "" { return false }
        guard var user = User.currentUser else { return false }
        
        user.name = textField.text!
        saveUserLocally(user)
        FirebaseUserListener.shared.saveUserToFireStore(user)
        
        textField.resignFirstResponder()
        return false
    }
}

extension EditProfileTableViewController: GalleryControllerDelegate
{
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        
        if images.count <= 0 { return }
        
        images.first!.resolve { [weak self] avatarImage in
            
            guard let strongSelf = self else { return }
            
            if avatarImage == nil {
                ProgressHUD.showFailed("Failed to select image.")
            }
            
            strongSelf.uploadImage(avatarImage!)
            strongSelf.avatarImageView.image = avatarImage
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
