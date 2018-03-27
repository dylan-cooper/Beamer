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
    case sendingCode
    case codeAccepted
    case codeRejected
    case jobAdded
    case jobRemovedDueToError
    case jobCompleted
    case debug
}

struct Message: Codable {
    var type: MessageType
    var payload: String?
    var job: Job?
    
    init(type: MessageType, payload: String?, job: Job?) {
        self.type = type
        self.payload = payload
        self.job = job
    }
    
    init(type: MessageType) {
        self.init(type: type, payload: nil, job: nil)
    }
    
    init(type: MessageType, payload: String) {
        self.init(type: type, payload: payload, job: nil)
    }
    
    init(type: MessageType, job: Job) {
        self.init(type: type, payload: nil, job: job)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case payload
        case job
    }
}
