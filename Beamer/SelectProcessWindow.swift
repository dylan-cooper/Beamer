//
//  SelectProcessWindowController.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-18.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Cocoa

protocol SelectProcessDelegate {
    func applicationWasSelected(app: NSRunningApplication)
}

class SelectProcessWindow: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    
    var applications: [NSRunningApplication] = []
    var delegate: SelectProcessDelegate?
    
    @IBOutlet weak var tableView: NSTableView!
    
    override var windowNibName : NSNib.Name! {
        return NSNib.Name("SelectProcessWindow")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        loadRunningApplications()
    }
    
    func loadRunningApplications() {
        self.applications = NSWorkspace.shared.runningApplications
        self.tableView.reloadData()
        let indexSet = NSIndexSet(index: 0)
        self.tableView.selectRowIndexes(indexSet as IndexSet, byExtendingSelection: false)
        self.tableView.scrollRowToVisible(0)
    }
    
    @IBAction func refreshClicked(_ sender: Any) {
        loadRunningApplications()
    }
    
    @IBAction func watchClicked(_ sender: Any) {
        let app = self.applications[self.tableView.selectedRow]
        print(app)
        self.delegate?.applicationWasSelected(app: app)
        self.close()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.applications.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var icon: NSImage?
        var cellIdentifier: String = ""
        
        if tableColumn == tableView.tableColumns[0] {
            text = self.applications[row].localizedName ?? "Unknown"
            icon = self.applications[row].icon
            cellIdentifier = "ApplicationCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            text = "\(self.applications[row].processIdentifier)"
            cellIdentifier = "PIDCellID"
        }

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = icon
            return cell
        }
        return nil
    }
}
