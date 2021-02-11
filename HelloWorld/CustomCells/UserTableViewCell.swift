//
//  UserTableViewCell.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(user: User) {
        usernameLabel.text = user.username
        statusLabel.text = user.status
        setAvatar(avatarLink: user.avatarLink)
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
