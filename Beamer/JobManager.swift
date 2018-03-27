//
//  JobManager.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-25.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Foundation
import Darwin
import Cocoa

protocol JobManagerDelegate {
    func jobAdded(_ job: Job)
    func jobCompleted(_ job: Job)
    func jobRemovedDueToError(_ job: Job)
    
}

class JobManager {    
    var delegate: JobManagerDelegate?
    var jobs: [Job] = []
    var sortedJobs: [Job] {
        return jobs.sorted(by: { $0.name < $1.name })
    }
    
    func watchJob(_ job: Job) {
        jobs.append(job)
        
        DispatchQueue.global(qos: .background).async {
            let result = watch_pid(job.pid)
            if result == 0 {
                print("Error")
                self.jobs = self.jobs.filter { $0.pid != job.pid }
                self.delegate?.jobRemovedDueToError(job)

            } else {
                self.jobs = self.jobs.filter { $0.pid != job.pid }
                self.delegate?.jobCompleted(job)
            }
        }
        self.delegate?.jobAdded(job)
    }
    
    func watchApplication(_ app: NSRunningApplication) {
        let name = app.localizedName ?? "Process \(app.processIdentifier)"
        let job = Job(pid: app.processIdentifier, name: name)
        self.watchJob(job)
    }
}
