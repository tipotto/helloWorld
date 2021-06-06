//
//  SearchResult.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/04/21.
//

import Foundation

struct SearchResult: Codable {
    var results: [ChannelRes]
    var isTransNeeded: Bool
}
