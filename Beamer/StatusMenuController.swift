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

class StatusMenuController: NSObject, SelectProcessDelegate, NearbyDevicesDelegate {

    var nearbyDevicesWindow: NearbyDevicesWindow!
    var selectProcessWindow: SelectProcessWindow!
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        selectProcessWindow = SelectProcessWindow()
        selectProcessWindow.delegate = self
        
        nearbyDevicesWindow = NearbyDevicesWindow()
        nearbyDevicesWindow.delegate = self
    }
    
    // MARK: SelectProcessDelegate
    
    func applicationWasSelected(app: NSRunningApplication) {
        let pid = app.processIdentifier
        WatchPidWrapper.watch_process(pid: pid)
        
        let name = app.localizedName ?? "Process \(app.processIdentifier)"
        let menuItem = NSMenuItem()
        menuItem.title = name
        menuItem.image = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))
        statusMenu.insertItem(menuItem, at: 10)
    }
    
    // MARK: NearbyDevicesDelegate
    
    func deviceWasSelected(device: String) {
        print(device)
    }
    

    // MARK: Actions
    
    @IBAction func watchNewProcessClicked(_ sender: Any) {
        selectProcessWindow.showWindow(nil)
    }
    
    @IBAction func pairWithNearbyDevicesClicked(_ sender: Any) {
        nearbyDevicesWindow.showWindow(nil)
    }
    
    @IBAction func temp(_ sender: Any) {
        print(sender)
        let notification = NSUserNotification()
        notification.title = "Title"
        notification.informativeText = "body"
        NSUserNotificationCenter.default.deliver(notification)

        //let data = "World".data(using: .utf8)
        //beamerServer.send(data!)
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)

    }
}
