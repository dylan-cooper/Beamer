//
//  BonjourServer.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 14/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//
import Cocoa
import CocoaAsyncSocket

enum PacketTag: Int {
    case header = 1
    case body = 2
}

protocol BeamerServerDelegate {
    func connected()
    func failedToConnect()
    func disconnected()
    func handleMessage(_ message: Message)
    func didChangeServices()
}

class BeamerServer: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, GCDAsyncSocketDelegate {
    
    static let shared = BeamerServer()
    
    var delegates: [String: BeamerServerDelegate] = [:]
    var coServiceBrowser: NetServiceBrowser!
    var services: [NetService] = []
    var connectedServices: [NetService] = []
    var socketsWithNames: [(String, GCDAsyncSocket)] = []
    
    let serviceType: String = "_beamer._tcp."
    let serviceDomain: String = "local."
    
    override init() {
        super.init()
        self.startBrowsing()
    }
    
    func addDelegate(name: String, delegate: BeamerServerDelegate) {
        self.delegates[name] = delegate
    }
    
    func removeDelegate(name: String) {
        self.delegates.removeValue(forKey: name)
    }
    
    private func parseHeader(_ data: Data) -> UInt {
        var out: UInt = 0
        (data as NSData).getBytes(&out, length: MemoryLayout<UInt>.size)
        return out
    }
    
    func handleResponseBody(_ data: Data) {
        let decoder = JSONDecoder()
        let message = try! decoder.decode(Message.self, from: data)
        for (_, delegate) in self.delegates {
            delegate.handleMessage(message)
        }
        //self.delegate?.handleMessage(message)
    }
    
    func getServiceWithName(_ name: String) -> NetService? {
        let filtered = services.filter() { $0.name == name }
        if filtered.count > 0 {
            return filtered[0]
        }
        return nil
    }
    
    func hasConnectedServiceWithName(_ name: String) -> Bool {
        let filtered = connectedServices.filter() {$0.name == name}
        return filtered.count > 0
    }
    
    func connectTo(_ service: NetService) {
        service.delegate = self
        print(service)
        service.resolve(withTimeout: 3)
    }
    
    // MARK: NSNetServiceBrowser helpers
    
    func stopBrowsing() {
        if self.coServiceBrowser != nil {
            self.coServiceBrowser.stop()
            self.coServiceBrowser.delegate = nil
            self.coServiceBrowser = nil
        }
    }
    
    func startBrowsing() {
        self.services.removeAll(keepingCapacity: true)
        self.coServiceBrowser = NetServiceBrowser()
        self.coServiceBrowser.delegate = self
        self.coServiceBrowser.searchForServices(ofType: serviceType,
                                                inDomain: serviceDomain)
    }
    
    func sendToSpecificService(_ service: NetService, _ message: Message) {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(message)
        print("send message")
        let selected = self.socketsWithNames.first { (val: (String, GCDAsyncSocket)) -> Bool in
            return val.0 == service.name
        }
        
        if let socket = selected?.1 {
            var header = data.count
            let headerData = Data(bytes: &header, count: MemoryLayout<UInt>.size)
            socket.write(headerData, withTimeout: -1.0, tag: PacketTag.header.rawValue)
            socket.write(data, withTimeout: -1.0, tag: PacketTag.body.rawValue)
        } else {
            print("Something has gone wrong - socket doesn't exist for service")
        }
    }
    
    func sendToAll(_ message: Message) {
        for service in self.connectedServices {
            sendToSpecificService(service, message)
        }
    }
    
    // Does the work of actually connecting to the service.
    // Some logical errors here?
    func doConnectToService(_ service: NetService) -> Bool {

        let addresses: Array = service.addresses!
        print("Addresses: \(addresses[0])")
        
        let selected = self.socketsWithNames.first { (val: (String, GCDAsyncSocket)) -> Bool in
            return val.0 == service.name
        }
        
        let socket = selected?.1 ?? GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)

        if !socket.isConnected {
            while !addresses.isEmpty {
                let address: Data = addresses[0]
                do {
                    try socket.connect(toAddress: address)
                    
                    // remove anything with this name (just to be safe)
                    self.socketsWithNames = self.socketsWithNames.filter { (val: (String, GCDAsyncSocket)) -> Bool in
                        return val.0 != service.name
                    }
                    
                    
                    // add to the list of sockets
                    self.socketsWithNames.append((service.name, socket))
                    
                    // add to the list of connected services
                    self.connectedServices.append(service)
                    return true
                } catch {
                    print(error);
                }
            }
        }
        
        return true
    }
    
    // MARK: NSNetService Delegates
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("did resolve address \(sender.name)")
        if self.doConnectToService(sender) {
            print("connected to \(sender.name)")
            for (_, delegate) in self.delegates {
                delegate.connected()
            }
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("net service did not resolve. errorDict: \(errorDict)")
        for (_, delegate) in self.delegates {
            delegate.failedToConnect()
        }
    }
    
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print("didAcceptConnectionWith")
    }
    
    // MARK: GCDAsyncSocket Delegates
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("connected to host \(host), on port \(port)")
        sock.readData(toLength: UInt(MemoryLayout<UInt64>.size), withTimeout: -1.0, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket did disconnect \(sock), error: \(String(describing: err?._userInfo))")
        // get the name
        let socketWithName = self.socketsWithNames.first { (val: (String, GCDAsyncSocket)) -> Bool in
            return val.1 == sock
        }
        if let name = socketWithName?.0 {
            // remove from list
            self.connectedServices = self.connectedServices.filter({ (service) -> Bool in
                service.name != name
            })
        
            // inform delegates
            for (_, delegate) in self.delegates {
                delegate.disconnected()
            }
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("socket did read data. tag: \(tag)")
        
        if data.count == MemoryLayout<UInt>.size {
            let bodyLength: UInt = self.parseHeader(data)
            sock.readData(toLength: bodyLength, withTimeout: -1, tag: PacketTag.body.rawValue)
        } else {
            self.handleResponseBody(data)
            sock.readData(toLength: UInt(MemoryLayout<UInt>.size), withTimeout: -1, tag: PacketTag.header.rawValue)
        }
    }
    
    func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        print("socket did close read stream")
    }
    
    // MARK: NSNetServiceBrowser Delegates
    
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didFind aNetService: NetService, moreComing: Bool) {
        self.services.append(aNetService)
        if !moreComing {
            for (_, delegate) in self.delegates {
                delegate.didChangeServices()
            }
        }
    }
    
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didRemove aNetService: NetService, moreComing: Bool) {
        if let index = self.services.index(where: {$0 == aNetService}) {
            self.services.remove(at: index)
        }
        
        if !moreComing {
            for (_, delegate) in self.delegates {
                delegate.didChangeServices()
            }
        }
    }
}
