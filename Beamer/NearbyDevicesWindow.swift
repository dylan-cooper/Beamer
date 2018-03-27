//
//  NearbyDevicesWindow.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-24.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Cocoa


class NearbyDevicesWindow: NSWindowController, BeamerServerDelegate, NSTableViewDelegate, NSTableViewDataSource {

    var generatedCode: String?
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var numbersTextField: NSTextField!

    var selectedService: NetService?
    
    override var windowNibName: NSNib.Name! {
        return NSNib.Name("NearbyDevicesWindow")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        BeamerServer.shared.addDelegate(name: "NearbyDevicesWindow", delegate: self)
    }
    
    @IBAction func pairButtonClicked(_ sender: Any) {
        if tableView.selectedRow > -1 {
            selectedService = BeamerServer.shared.services[tableView.selectedRow]
            BeamerServer.shared.connectTo(selectedService!)
        }
    }
    
    func updateCode() {
        let number = arc4random_uniform(1000000)
        generatedCode = String(format: "%06d", number)
    }
    
    func showModal() {
        updateCode()
        numbersTextField.stringValue = self.generatedCode ?? "ERROR"
        let alert = NSAlert()
        alert.messageText = "Use this code to connect with the device:"
        alert.accessoryView = numbersTextField
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func sendPairRequest() {
        let message = Message(type: .pairRequest)
        BeamerServer.shared.sendToSpecificService(self.selectedService!, message)
    }
    
    func sendCodeAccepted() {
        let message = Message(type: .codeAccepted)
        BeamerServer.shared.sendToSpecificService(self.selectedService!, message)
        PairedDevicesManager.shared.saveDevice(name: self.selectedService!.name)
        self.close()
    }
    
    func sendCodeRejected() {
        let message = Message(type: .codeRejected)
        BeamerServer.shared.sendToSpecificService(self.selectedService!, message)
    }
    
    func checkCode(sentCode: String?) {
        guard let sent = sentCode, let generated = generatedCode else {
            print("One of the codes doesn't exist")
            return
        }
        
        if (sent == generated) {
            print("code accepted")
            sendCodeAccepted()
        } else {
            print("code rejected")
            sendCodeRejected()
        }
    }
    
    // MARK: BeamerServerDelegate

    func connected() {
        sendPairRequest()
        showModal()
    }
    
    func failedToConnect() {
        // TODO: Show "Failed to connect" modal
    }
    
    func disconnected() {
        // TODO: ??
    }

    func handleMessage(_ message: Message) {
        switch message.type {
        case .sendingCode:
            print(String(describing: message.payload))
            checkCode(sentCode: message.payload)
        default:
            print("No action for this message type: \(message.type)")
        }
    }
    
    func didChangeServices() {
        self.tableView.reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return BeamerServer.shared.services.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: String = ""
        
        if tableColumn == tableView.tableColumns[0] {
            text = BeamerServer.shared.services[row].name
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
