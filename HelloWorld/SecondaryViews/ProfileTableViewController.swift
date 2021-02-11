//
//  ProfileTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/14.
//

import UIKit

class ProfileTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: - Vars
    var user: User?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        
        setupUI()
    }
    
    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 「Start Chat」をクリックした場合のみ、以下を実行
        if indexPath.section != 1 { return }
        print("Start Chat")
        
        guard let authUser = User.currentUser else { return }
        guard let chatUser = user else { return }
        
        guard let chatRoomId = startChat(firstUser: authUser, secondUser: chatUser) else { return }
        
        let privateChatView = ChatViewController(chatId: chatRoomId,
                                                 recipientId: chatUser.id,
                                                 recipientName: chatUser.username)
        
        privateChatView.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(privateChatView, animated: true)
        
        
    }

    // MARK: - SetupUI
    private func setupUI() {
        
        guard let user = user else { return }
        title = user.username
        usernameLabel.text = user.username
        statusLabel.text = user.status
        
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
