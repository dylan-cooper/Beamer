//
//  NearbyDevicesWindow.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-24.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Cocoa

protocol NearbyDevicesDelegate {
    func deviceWasSelected(device: String)
}

class NearbyDevicesWindow: NSWindowController, BeamerServerDelegate, NSTableViewDelegate, NSTableViewDataSource {

    var delegate: NearbyDevicesDelegate?
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet var numbersTextField: NSTextField!
    
    override var windowNibName: NSNib.Name! {
        return NSNib.Name("NearbyDevicesWindow")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        BeamerServer.shared.delegate = self
    }
    
    @IBAction func pairButtonClicked(_ sender: Any) {
        if tableView.selectedRow > -1 {
            let device = BeamerServer.shared.devices[tableView.selectedRow]
            print(device)
            BeamerServer.shared.connectTo(device)
        }

    }
    
    func showModal() {
        let alert = NSAlert()
        alert.messageText = "Hello"
        alert.accessoryView = numbersTextField
        alert.addButton(withTitle: "OK")
        alert.runModal()

    }
    
    // MARK: BeamerServerDelegate

    func connected() {
        let message = Message(type: .pairRequest)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(message)
        print(String(data: data, encoding: .utf8) as Any)
        BeamerServer.shared.send(data)
    }
    
    func disconnected() {
        // TODO: ??
    }

    func handleBody(_ body: String?) {
        print("handleBody \(String(describing: body))")
        showModal()
    }
    
    func didChangeServices() {
        self.tableView.reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return BeamerServer.shared.devices.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: String = ""
        
        if tableColumn == tableView.tableColumns[0] {
            text = BeamerServer.shared.devices[row].name
            cellIdentifier = "DeviceCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            text = "" // TODO: figure out a status
            cellIdentifier = "StatusCellID"
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text

            return cell
        }
        return nil
    }
    
}
