//
//  TranslationAPI.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/17.
//

import Foundation

enum TranslationAPI {
    case detectLanguage
    case translate
    case supportedLanguages
    
    func getURL() -> String {
        var urlString = ""
        
        switch self {
        case .detectLanguage:
            urlString = "https://translation.googleapis.com/language/translate/v2/detect"
            
        case .translate:
            urlString = "https://translation.googleapis.com/language/translate/v2"
            
        case .supportedLanguages:
            urlString = "https://translation.googleapis.com/language/translate/v2/languages"
        }
        
        return urlString
    }
    
    func getHTTPMethod() -> String {
        if self == .supportedLanguages {
            return "GET"
            
        } else {
            return "POST"
        }
    }
}
