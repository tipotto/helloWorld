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
    var channelRes: ChannelRes!
    var channel: Channel?
    var delegate: ChannelDetailTableViewControllerDelegate?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        fetchChannel()
        configureRightBarButton()
    }

    // MARK: - IBActions
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var membersLabel: UILabel!
    @IBOutlet weak var lastMessageDateLabel: UILabel!
    @IBOutlet weak var aboutTextView: UITextView!
    
    // MARK: - Configure
    private func configLabels() {
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.9
        membersLabel.adjustsFontSizeToFitWidth = true
        membersLabel.minimumScaleFactor = 0.9
        lastMessageDateLabel.adjustsFontSizeToFitWidth = true
        lastMessageDateLabel.minimumScaleFactor = 0.9
    }
    
    private func showChannelData() {
        
        title = channelRes.name
        nameLabel.text = channelRes.name
        membersLabel.text = "\(channel!.memberCounter) members"
        lastMessageDateLabel.text = timeElapsed(channel!.lastMessageDate ?? Date())
        aboutTextView.text = channelRes.aboutChannel
        setAvater(avatarLink: channelRes.avatarLink)
        
        configLabels()
    }
    
    private func configureRightBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Follow", style: .plain, target: self, action: #selector(followChannel))
    }
    
    private func fetchChannel() {
        FirebaseChannelListener.shared.downloadChannel(channelId: channelRes.channelId) { [weak self] channel in
            self?.channel = channel
            self?.showChannelData()
        }
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
        
        let joiningChannel = JoiningChannel(id: channelRes.channelId, name: channelRes.name, avatarLink: channelRes.avatarLink, aboutChannel: channelRes.aboutChannel)
        
        FirebaseChannelListener.shared.followChannel(joiningChannel: joiningChannel)

        delegate?.didClickFollow()
        
        // 1つ前のコントローラーに戻る
        navigationController?.popViewController(animated: true)
    }
}
