//
//  PhotoMessage.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/20.
//

import Foundation
import MessageKit

class PhotoMessage: NSObject, MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(path: String) {
        url = URL(fileURLWithPath: path)
        placeholderImage = UIImage(named: "photoPlaceholder")!
        size = CGSize(width: 240, height: 240)
    }
    
}
