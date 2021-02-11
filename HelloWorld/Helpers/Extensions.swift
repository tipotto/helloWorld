//
//  Extensions.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import UIKit

extension UIImage {
    
    var isPortrait: Bool {
        return size.height > size.width
    }

    var isLandscape: Bool {
        return size.width > size.height
    }
    
    var breadth: CGFloat {
        return min(size.width, size.height)
    }
    
    var breadthSize: CGSize {
        return CGSize(width: breadth, height: breadth)
    }
    
    var breadthRect: CGRect {
        return CGRect(origin: .zero, size: breadthSize)
    }
    
    var circleMasked: UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        
        defer { UIGraphicsEndImageContext() }
        
        let cgFloatX = isLandscape ? floor((size.width - size.height) / 2) : 0
        let cgFloatY = isPortrait ? floor((size.height - size.width) / 2) : 0
        let cgPoint = CGPoint(x: cgFloatX, y: cgFloatY)
        
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: cgPoint, size: breadthSize)) else { return nil }
        
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage).draw(in: breadthRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
        
    }
}

extension Date {
    func longDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        return dateFormatter.string(from: self)
    }
    
    func stringDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMMyyyyHHmmss"
        return dateFormatter.string(from: self)
    }
    
    func time() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self)
    }
    
    func interval(ofComponent comp: Calendar.Component, from date: Date) -> Float {
        let currentCalender = Calendar.current
        guard let start = currentCalender.ordinality(of: comp, in: .era, for: date) else {
            return 0
        }
        
        guard let end = currentCalender.ordinality(of: comp, in: .era, for: self) else {
            return 0
        }
        
        return Float(start - end)
    }
}
