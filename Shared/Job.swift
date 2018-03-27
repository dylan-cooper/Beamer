//
//  Job.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-25.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Foundation

struct Job: Codable {
    var pid: pid_t
    var name: String
    
    private enum CodingKeys: String, CodingKey {
        case pid
        case name
    }
}
