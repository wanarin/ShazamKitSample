//
//  MetaData.swift
//  ShazamKitSample
//
//  Created by kazuya.tachibana on 2021/06/09.
//

import Foundation

struct MetaData: Comparable, Equatable {
    let title: String
    let offset: TimeInterval
    
    init(title: String, offset: TimeInterval) {
        self.title = title
        self.offset = offset
    }
    
    static func < (lhs: MetaData, rhs: MetaData) -> Bool {
        return lhs.offset < rhs.offset
    }
    
    static func == (lhs: MetaData, rhs: MetaData) -> Bool {
        return lhs.title == rhs.title && lhs.offset == rhs.offset
    }
}

extension MetaData {
    
    static let allMetaDatas = [
        MetaData(title: "て", offset: 1),
        MetaData(title: "れ", offset: 2),
        MetaData(title: "ふぉ", offset: 4),
        MetaData(title: "ん", offset: 5),
        MetaData(title: "しょ", offset: 7),
        MetaData(title: "っきんぐ", offset: 10)
    ]
}
