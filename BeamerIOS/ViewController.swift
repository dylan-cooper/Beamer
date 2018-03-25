//
//  ViewController.swift
//  BeamerIOS
//
//  Created by Dylan Cooper on 2018-03-12.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CocoaAsyncSocket

class ViewController: UIViewController, BeamerClientDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        BeamerClient.shared.delegate = self
        print("viewDidLoad")
    }
    
    // MARK: BeamerClientDelegate
    
    func connectedTo(_ socket: GCDAsyncSocket!) {
        print("ConnectedTo")
        print(socket)
    }
    
    func disconnected() {
        print("disconnected")
    }
    
    func handleBody(_ body: Data) {
        let decoder = JSONDecoder()
        let message = try! decoder.decode(Message.self, from: body)
        print(message)
    }
    
    // MARK: Actions
    
    @IBAction func sendClicked(_ sender: Any) {
        let data = "Hello".data(using: .utf8)
        
        print(data)
        BeamerClient.shared.send(data!)
    }
}




