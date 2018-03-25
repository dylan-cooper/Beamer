//
//  Message.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-24.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Foundation

enum MessageType: String, Codable {
    case pairRequest
}
struct Message: Codable {
    var type: MessageType
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
}
