//
//  PairedDevicesManager.swift
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-26.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

import Foundation

protocol PairedDevicesManagerDelegate {
    func devicePaired()
}

class PairedDevicesManager {
    static let shared = PairedDevicesManager()
    var delegate: PairedDevicesManagerDelegate?
    
    func connectWithSavedDevices() {
        let defaults = UserDefaults.standard
        let devices = defaults.object(forKey: "pairedDeviceNames") as? [String] ?? []
        print(devices)
        for name in devices {
            if let service = BeamerServer.shared.getServiceWithName(name) {
                print("found service with name: \(service)")
                BeamerServer.shared.connectTo(service)
            }
        }
    }
    
    func getPairedDevices() -> [(String, Bool)] {
        let defaults = UserDefaults.standard
        let names = defaults.object(forKey: "pairedDeviceNames") as? [String] ?? []
        return names.map({ (name: String) -> (String, Bool) in
            let isConnected = BeamerServer.shared.hasConnectedServiceWithName(name)
            return (name, isConnected)
        })
    }
    
    func saveDevice(name: String) {
        let defaults = UserDefaults.standard
        var devices = defaults.object(forKey: "pairedDeviceNames") as? [String] ?? []
        devices.append(name)
        devices = Array(Set(devices))
        defaults.set(devices, forKey: "pairedDeviceNames")
        
        delegate?.devicePaired()
    }
    
    func clearSavedDevices() {
        let defaults = UserDefaults.standard
        defaults.set([], forKey: "pairedDeviceNames")
    }
}
