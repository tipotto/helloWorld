//
//  ChannelTableViewCell.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/02.
//

import UIKit

class ChannelTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet weak var avatarImageView: UIImageView!

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var aboutLabel: UILabel!
    
    @IBOutlet weak var memberCountLabel: UILabel!
    
    @IBOutlet weak var lastMessageDateLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(channel: Channel) {
        setAvatar(avatarLink: channel.avatarLink)
        nameLabel.text = channel.name
        aboutLabel.text = channel.aboutChannel
        memberCountLabel.text = "\(channel.memberIds.count) members"
        lastMessageDateLabel.text = timeElapsed(channel.lastMessageDate ?? Date())
        lastMessageDateLabel.adjustsFontSizeToFitWidth = true
    }
    
    private func setAvatar(avatarLink: String) {
        if avatarLink.isEmpty {
            avatarImageView.image = UIImage(named: "avatar")
            return
        }
        
        FileStorage.downloadImage(imageUrl: avatarLink) { [weak self] avatarImage in
            self?.avatarImageView.image = avatarImage != nil ? avatarImage?.circleMasked : UIImage(named: "avatar")
        }
    }

}
