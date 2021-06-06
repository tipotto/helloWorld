//
//  SearchBadge.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/04/30.
//

import Foundation

enum Plan: String, CaseIterable, Equatable, Codable {
    case business
    case travel
    case shopping

    init?(_ text: String) {
        if text.starts(with: "bu") {
            self = .business
        } else if text.starts(with: "tr") {
            self = .travel
        } else if text.starts(with: "sh") {
            self = .shopping
        } else {
            return nil
        }
    }

    var iconName: String {
        switch self {
        case .business:
            return "bag"
        case .travel:
            return "airplane"
        case .shopping:
            return "cart"
        }
    }

    var items: [String] {
        switch self {
        case .business:
            return ["会議", "商談", "プレゼン", "勉強会"]
        case .travel:
            return ["宿泊", "日帰り"]
        case .shopping:
            return ["スーパー", "デパート"]
        }
    }
}
