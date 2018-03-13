//
//  WatchPidWrapper.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-12.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Foundation

class WatchPidWrapper {
    static func watch_process(pid: pid_t) {
        DispatchQueue.global(qos: .background).async {
            let result = watch_pid(pid)
            if result == 0 {
                print("Error")
            } else {
                print("Success")
            }
        }
    }
}
