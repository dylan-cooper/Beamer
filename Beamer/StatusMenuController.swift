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

class StatusMenuController: NSObject {

    
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        icon?.isTemplate = true
        statusItem.image = icon
        //statusItem.title = "Beamer"
        statusItem.menu = statusMenu
    }
    
    @IBAction func watchClicked(_ sender: Any) {
        let pid: pid_t = pid_t(97812)
        let result = watch_pid(pid)
        print(result)
    }
    @IBAction func temp(_ sender: Any) {
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
        

    }
}
