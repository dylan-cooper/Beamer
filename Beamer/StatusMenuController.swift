//
//  StatusMenuController.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-06.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Cocoa
import Darwin
import CocoaAsyncSocket

class StatusMenuController: NSObject, SelectProcessDelegate, BeamerServerDelegate, JobManagerDelegate, PairedDevicesManagerDelegate {

    var jobManager: JobManager!
    var nearbyDevicesWindow: NearbyDevicesWindow!
    var selectProcessWindow: SelectProcessWindow!
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    @IBOutlet weak var devicesHeaderMenuItem: NSMenuItem!
    @IBOutlet weak var devicesEndingSeparatorMenuItem: NSMenuItem!
    
    @IBOutlet weak var jobsHeaderMenuItem: NSMenuItem!
    @IBOutlet weak var jobsEndingSeparatorMenuItem: NSMenuItem!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        selectProcessWindow = SelectProcessWindow()
        selectProcessWindow.delegate = self
        
        nearbyDevicesWindow = NearbyDevicesWindow()
        
        jobManager = JobManager()
        jobManager.delegate = self
        
        BeamerServer.shared.addDelegate(name: "StatusMenuController", delegate: self)
        
        PairedDevicesManager.shared.delegate = self
        
        redrawDeviceMenuItems()
    }
    
    func redrawDeviceMenuItems() {
        let startingIndex = statusMenu.index(of: devicesHeaderMenuItem) + 1
        let oldEndIndex = statusMenu.index(of: devicesEndingSeparatorMenuItem)
        
        let pairedDevices = PairedDevicesManager.shared.getPairedDevices()
        let count = pairedDevices.count
        
        print("RedrawDevice \(pairedDevices)")
        
        for _ in startingIndex..<oldEndIndex {
            statusMenu.removeItem(at: startingIndex)
        }

        for i in 0..<count {
            let menuItem = NSMenuItem()
            menuItem.title = pairedDevices[i].0
            let imageName = pairedDevices[i].1 ? "NSStatusAvailable" : "NSStatusUnavailable"
            menuItem.image = NSImage(named: NSImage.Name(rawValue: imageName))
            statusMenu.insertItem(menuItem, at: i + startingIndex)
        }
    }
    
    func redrawJobMenuItems() {
        let startingIndex = statusMenu.index(of: jobsHeaderMenuItem) + 1
        let sortedJobs = jobManager.sortedJobs
        let count = sortedJobs.count
        let oldEndIndex = statusMenu.index(of: jobsEndingSeparatorMenuItem)
        
        for _ in startingIndex..<oldEndIndex {
            statusMenu.removeItem(at: startingIndex)
        }
        
        for i in 0..<count {
            let menuItem = NSMenuItem()
            menuItem.title = sortedJobs[i].name
            menuItem.image = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))
            statusMenu.insertItem(menuItem, at: i + startingIndex)
        }
    }
    
    // MARK: JobManagerDelegate
    
    func jobAdded(_ job: Job) {
        print("jobAdded")
        print(jobManager.jobs)
        redrawJobMenuItems()
        
        let message = Message(type: .jobAdded, job: job)
        BeamerServer.shared.sendToAll(message)
    }
    
    func jobCompleted(_ job: Job) {
        print("jobCompleted")
        print(jobManager.jobs)
        
        redrawJobMenuItems()
        
        let notification = NSUserNotification()
        notification.title = "Job Completed"
        notification.informativeText = "\(job.name) has finished running."
        NSUserNotificationCenter.default.deliver(notification)
        
        let message = Message(type: .jobCompleted, job: job)
        BeamerServer.shared.sendToAll(message)
    }
    
    func jobRemovedDueToError(_ job: Job) {
        print("jobRemoved")
        print(jobManager.jobs)
        redrawJobMenuItems()
        
        let notification = NSUserNotification()
        notification.title = "Watching Job Failed"
        notification.informativeText = "Failed to monitor job properly (\(job.name))."
        NSUserNotificationCenter.default.deliver(notification)
        
        let message = Message(type: .jobRemovedDueToError, job: job)
        BeamerServer.shared.sendToAll(message)
    }
    
    // MARK: SelectProcessDelegate
    
    func applicationWasSelected(app: NSRunningApplication) {
        jobManager.watchApplication(app)
    }
    
    // MARK: PairedDevicesManagerDelegate
    
    func devicePaired() {
        redrawDeviceMenuItems()
    }

    // MARK: BeamerServerDelegate
    
    func connected() {
        redrawDeviceMenuItems()
    }
    
    func failedToConnect() {
        redrawDeviceMenuItems()
    }
    
    func disconnected() {
        redrawDeviceMenuItems()
    }
    
    func handleMessage(_ message: Message) {
        print("handleMessage from StatusMenuController \(message)")
        
        // if there are messages that the SMC cares about, add here
        switch message.type {
            
        default:
            // do nothing
            print("ignoring message in StatusMenuController")
        }
    }
    
    func didChangeServices() {
        // a new nearby device has been seen, don't care here.
    }
    
    // MARK: Actions
    
    @IBAction func watchNewProcessClicked(_ sender: Any) {
        selectProcessWindow.showWindow(nil)
    }
    
    @IBAction func pairWithNearbyDevicesClicked(_ sender: Any) {
        nearbyDevicesWindow.showWindow(nil)
    }
    
    @IBAction func sendDebugMessageClicked(_ sender: Any) {
        let message = Message(type: .debug)
        BeamerServer.shared.sendToAll(message)
    }
    
    @IBAction func temp(_ sender: Any) {
        print(sender)
    }
    
    @IBAction func connectWithPairedDevicesClicked(_ sender: Any) {
        PairedDevicesManager.shared.connectWithSavedDevices()
    }
    
    @IBAction func clearPairedDevicesClicked(_ sender: Any) {
        PairedDevicesManager.shared.clearSavedDevices()
        redrawDeviceMenuItems()
    }
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}
