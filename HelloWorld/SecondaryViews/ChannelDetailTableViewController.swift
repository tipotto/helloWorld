//
//  ChannelTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/03.
//

import UIKit

protocol ChannelDetailTableViewControllerDelegate {
    func didClickFollow()
}

class ChannelDetailTableViewController: UITableViewController {

    // MARK: - Vars
    var channel: Channel!
    var delegate: ChannelDetailTableViewControllerDelegate?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        showChannelData()
        configureRightBarButton()
    }

    // MARK: - IBActions
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var membersLabel: UILabel!
    @IBOutlet weak var aboutTextView: UITextView!
    
    // MARK: - Configure
    private func showChannelData() {
        title = channel.name
        nameLabel.text = channel.name
        membersLabel.text = "\(channel.memberIds.count) members"
        aboutTextView.text = channel.aboutChannel
        setAvater(avatarLink: channel.avatarLink)
    }
    
    private func configureRightBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Follow", style: .plain, target: self, action: #selector(followChannel))
    }
    
    private func setAvater(avatarLink: String) {
        if avatarLink.isEmpty {
            avatarImageView.image = UIImage(named: "avatar")
            return
        }
        
        FileStorage.downloadImage(imageUrl: avatarLink) { [weak self] avatarImage in
            self?.avatarImageView.image = avatarImage != nil ? avatarImage!.circleMasked : UIImage(named: "avatar")
        }
    }
    
    // MARK: - Actions
    @objc func followChannel() {
        channel.memberIds.append(User.currentId)
        FirebaseChannelListener.shared.saveChannel(channel)
        delegate?.didClickFollow()
        
        // 1つ前のコントローラーに戻る
        navigationController?.popViewController(animated: true)
    }
}
