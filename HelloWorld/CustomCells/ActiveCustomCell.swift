//
//  ActiveCustomCell.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/21.
//

import UIKit

class ActiveCustomCell: UITableViewCell {
    
    static let identifier = "ActiveCustomCell"
    
    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var unreadCounterLabel: UILabel!
    @IBOutlet weak var unreadCounterBackgroundView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        unreadCounterBackgroundView.layer.cornerRadius = unreadCounterBackgroundView.frame.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func configLabels() {
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.minimumScaleFactor = 0.9
        
        lastMessageLabel.adjustsFontSizeToFitWidth = true
        lastMessageLabel.minimumScaleFactor = 0.9
        lastMessageLabel.numberOfLines = 2
        
        dateLabel.adjustsFontSizeToFitWidth = true
    }
    
    private func configUnreadCounter(unreadCount: Int) {
        if unreadCount == 0 {
            unreadCounterBackgroundView.isHidden = true
            return
        }
        
        unreadCounterLabel.text = "\(unreadCount)"
        unreadCounterBackgroundView.isHidden = false
    }
    
    func configure(room: JoiningChat) {
        usernameLabel.text = room.name
        lastMessageLabel.text = room.lastMessage
        setAvatar(avatarLink: room.avatarLink)
        dateLabel.text = timeElapsed(room.date ?? Date())
        
        configLabels()
        configUnreadCounter(unreadCount: room.unreadCounter)
    }
    
    func configure(channel: JoiningChannel) {
        usernameLabel.text = channel.name
        lastMessageLabel.text = channel.lastMessage
        setAvatar(avatarLink: channel.avatarLink)
        dateLabel.text = timeElapsed(channel.date ?? Date())
        
        configLabels()
        configUnreadCounter(unreadCount: channel.unreadCounter)
    }
    
    private func setAvatar(avatarLink: String) {
        FileStorage.downloadImage(imageUrl: avatarLink) { [weak self] avatarImage in
            guard let strongSelf = self else { return }

            guard let image = avatarImage else {
                strongSelf.avatarImageView.image = UIImage(named: "avatar")!
                return
            }

            strongSelf.avatarImageView.image = image.circleMasked
        }
        
    }
    
}
