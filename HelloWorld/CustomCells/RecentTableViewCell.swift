//
//  RecentTableViewCell.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/14.
//

import UIKit

class RecentTableViewCell: UITableViewCell {
    
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

        // Configure the view for the selected state
    }
    
    func configure(recent: RecentChat) {
        usernameLabel.text = recent.receiverName
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.minimumScaleFactor = 0.9
        
        lastMessageLabel.text = recent.lastMessage
        lastMessageLabel.adjustsFontSizeToFitWidth = true
        lastMessageLabel.minimumScaleFactor = 0.9
        lastMessageLabel.numberOfLines = 2
        
        setAvatar(avatarLink: recent.avatarLink)
        dateLabel.text = timeElapsed(recent.date ?? Date())
        dateLabel.adjustsFontSizeToFitWidth = true
        
        if recent.unreadCounter == 0 {
            unreadCounterBackgroundView.isHidden = true
            return
        }
        
        unreadCounterLabel.text = "\(recent.unreadCounter)"
        unreadCounterBackgroundView.isHidden = false
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
