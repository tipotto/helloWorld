//
//  InactiveCustomCell.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/23.
//

import UIKit

class InactiveCustomCell: UITableViewCell {

    static let identifier = "InactiveCustomCell"
    
    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var aboutChannelLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configLabels() {
        channelNameLabel.adjustsFontSizeToFitWidth = true
        channelNameLabel.minimumScaleFactor = 0.9
        aboutChannelLabel.adjustsFontSizeToFitWidth = true
        aboutChannelLabel.minimumScaleFactor = 0.9
        aboutChannelLabel.numberOfLines = 2
    }
    
    // InactiveCellを利用するのは2パターン
    // 1. JoiningChannelから取得したadminChannelリスト（JoiningChannel）
    // 2. Algoliaから取得したレコメンドチャンネルリスト（ChannelRes）
    func configure(joiningCh: JoiningChannel) {
        channelNameLabel.text = joiningCh.name
        aboutChannelLabel.text = joiningCh.aboutChannel
        setAvatar(avatarLink: joiningCh.avatarLink)
        configLabels()
    }
    
    func configure(channelRes: ChannelRes) {
        channelNameLabel.text = channelRes.name
        aboutChannelLabel.text = channelRes.aboutChannel
        setAvatar(avatarLink: channelRes.avatarLink)
        configLabels()
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
