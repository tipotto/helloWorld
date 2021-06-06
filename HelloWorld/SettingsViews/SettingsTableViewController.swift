//
//  SettingsTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/11.
//

import UIKit
import ProgressHUD

class SettingsTableViewController: UITableViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userLangLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showUserInfo()
    }
    
    // MARK: - IBActions
    @IBAction func tellAFriendButtonPressed(_ sender: Any) {
        print("tell a friend")
    }
    
    @IBAction func termsAndConditionsButtonPressed(_ sender: Any) {
        print("terms and conditions")
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        
        FirebaseUserListener.shared.logOutCurrentUser { [weak self] error in
            
            if error != nil {
                ProgressHUD.showFailed("Log out is failed.")
                return
            }
            
            let loginView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "LoginView")
            
            // 上記の処理はバックグラウンドで実行される。
            // そのため、以降の処理をメインスレッドで実行することで、その処理結果をUIに反映させる。
            DispatchQueue.main.async {
                loginView.modalPresentationStyle = .fullScreen
                self?.present(loginView, animated: true)
            }
        }
    }
    
    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0 : 15.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Settingsページの最初のセクションをクリックした時に
        // 指定したコントローラーに遷移する。
        if indexPath.section == 0 && indexPath.row == 0 {
            performSegue(withIdentifier: "SettingsToEditProfileSeg", sender: self)
        }
    }
    
    // MARK: - Update UI
    private func showUserInfo() {
        
        guard let user = User.currentUser else { return }
        print("user in UserDefaults", user)
        
        usernameLabel.text = user.name
        userLangLabel.text = "Language: \(user.lang)"
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        appVersionLabel.text = "App version \(appVersion ?? "")"
        
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
}
