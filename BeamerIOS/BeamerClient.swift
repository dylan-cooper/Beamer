
//
//  BonjourController.swift
//  bonjour-demo-ios
//
//  Created by James Zaghini on 12/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

enum PacketTag: Int {
    case header = 1
    case body = 2
}

enum BeamerClientState {
    case idle
    case broadcasting
    case connected
}

protocol BeamerClientDelegate {
    func stateChanged()
    func handleMessage(_ message: Message)
}

class BeamerClient: NSObject, NetServiceDelegate, GCDAsyncSocketDelegate {
    
    static let shared = BeamerClient()
    
    var delegate: BeamerClientDelegate?
    var service: NetService!
    var socket: GCDAsyncSocket!
    var state: BeamerClientState = .idle
    let serviceDomain: String = "local."
    let serviceType: String = "_beamer._tcp."
    
    override init() {
        super.init()
    }
    
    private func setState(state: BeamerClientState) {
        self.state = state
        self.delegate?.stateChanged()
    }
    
    func startBroadcasting() {
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        do {
            try self.socket.accept(onPort: 0)
            self.service = NetService(domain: serviceDomain,
                                      type: serviceType,
                                      name: UIDevice.current.name,
                                      port: Int32(self.socket.localPort))
            self.service.delegate = self
            self.service.publish()
            self.setState(state: .broadcasting)
        } catch let error as NSError {
            print("Unable to create socket. Error \(error)")
        }
    }
    
    func stopBroadcasting(state: BeamerClientState) {
        self.service.stop()
        self.setState(state: state)
    }
    
    private func parseHeader(_ data: Data) -> UInt {
        var out: UInt = 0
        (data as NSData).getBytes(&out, length: MemoryLayout<UInt>.size)
        return out
    }
    
    func send(_ message: Message) {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(message)
        print("send message")
        
        var header = data.count
        let headerData = Data(bytes: &header, count: MemoryLayout<UInt>.size)
        self.socket.write(headerData, withTimeout: -1.0, tag: PacketTag.header.rawValue)
        self.socket.write(data, withTimeout: -1.0, tag: PacketTag.body.rawValue)
    }
    
    /// MARK: NSNetService Delegates
    
    func netServiceDidPublish(_ sender: NetService) {
        print("Bonjour service published. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port)")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Unable to create socket. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port), Error \(errorDict)")
        self.setState(state: .idle)
    }
    
    /// MARK: GCDAsyncSocket Delegates
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("Did accept new socket")
        self.socket = newSocket
        self.socket.readData(toLength: UInt(MemoryLayout<UInt64>.size), withTimeout: -1.0, tag: 0)
        self.stopBroadcasting(state: .connected)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket did disconnect")
        if sock == self.socket {
            self.setState(state: .idle)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("did read data")

        if data.count == MemoryLayout<UInt>.size {
            let bodyLength: UInt = self.parseHeader(data)
            sock.readData(toLength: bodyLength, withTimeout: -1, tag: PacketTag.body.rawValue)
        } else {
            let decoder = JSONDecoder()
            let message = try! decoder.decode(Message.self, from: data)
            self.delegate?.handleMessage(message)
            sock.readData(toLength: UInt(MemoryLayout<UInt>.size), withTimeout: -1, tag: PacketTag.header.rawValue)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("did write data with tag: \(tag)")
    }
}
