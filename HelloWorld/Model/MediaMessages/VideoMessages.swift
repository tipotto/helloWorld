//
//  VideoMessages.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/22.
//

import Foundation
import MessageKit

class VideoMessage: NSObject, MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(url: URL?) {
        self.url = url
        self.placeholderImage = UIImage(named: "photoPlaceholder")!
        self.size = CGSize(width: 240, height: 240)
    }
    
}
