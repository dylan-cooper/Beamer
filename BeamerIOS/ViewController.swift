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
    
    @IBOutlet weak var mainStackView: UIStackView!
    var jobs: [Job] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BeamerClient.shared.delegate = self
        refreshStackView()
    }
    
    @objc func startBroadcasting(sender: Any) {
        BeamerClient.shared.startBroadcasting()
    }
    
    @objc func stopBroadcasting(sender: Any) {
        BeamerClient.shared.stopBroadcasting(state: .idle)
    }
    
    func makeTitleLabel() -> UILabel {
        let myLabel = UILabel()
        myLabel.numberOfLines = 1
        myLabel.text = "Beamer"
        myLabel.font = UIFont(name: "Masque", size: 72)
        myLabel.textColor = #colorLiteral(red: 0.2823529412, green: 0.6431372549, blue: 0.4274509804, alpha: 1)
        myLabel.textAlignment = .center
        return myLabel
    }
    
    func makeStatusLabel(_ stateText: String) -> UILabel {
        let statusLabel = UILabel()
        statusLabel.numberOfLines = 0
        statusLabel.text = "Status: \(stateText)"
        
        statusLabel.font = statusLabel.font.withSize(24)
        statusLabel.textAlignment = .center
        return statusLabel
    }
    
    func makeJobLabel(_ job: Job) -> UILabel {
        let statusLabel = UILabel()
        statusLabel.numberOfLines = 0
        statusLabel.text = job.name
        
        statusLabel.font = statusLabel.font.withSize(20)
        statusLabel.textAlignment = .center
        return statusLabel
    }
    
    func makeMiscLabel(_ text: String) -> UILabel {
        let statusLabel = UILabel()
        statusLabel.numberOfLines = 0
        statusLabel.text = text
        
        statusLabel.font = statusLabel.font.withSize(24)
        statusLabel.textAlignment = .center
        return statusLabel
    }
    
    func makeButtonForAction(text: String, action: Selector) -> UIButton {
        let myButton = UIButton(type: .system)
        myButton.setTitle(text, for: .normal)
        myButton.titleLabel?.numberOfLines = 0
        myButton.titleLabel?.font = myButton.titleLabel?.font.withSize(30)
        myButton.titleLabel?.textAlignment = .center
        myButton.addTarget(self, action: action, for: .touchUpInside)
        return myButton
    }

    func clearStackView() {
        for v in mainStackView.arrangedSubviews {
            mainStackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
    }
    
    func populateStackView() {
        mainStackView.addArrangedSubview(makeTitleLabel())
        
        switch BeamerClient.shared.state {
        case .idle:
            mainStackView.addArrangedSubview(makeStatusLabel("Idle"))
            mainStackView.addArrangedSubview(makeButtonForAction(text: "Start Broadcasting", action: #selector(startBroadcasting)))
        case .broadcasting:
            mainStackView.addArrangedSubview(makeStatusLabel("Broadcasting"))
            mainStackView.addArrangedSubview(makeButtonForAction(text: "Stop Broadcasting", action: #selector(stopBroadcasting)))
        case .connected:
            mainStackView.addArrangedSubview(makeStatusLabel("Connected"))
            if self.jobs.count > 0 {
                mainStackView.addArrangedSubview(makeMiscLabel("Current Jobs"))
            } else {
                mainStackView.addArrangedSubview(makeMiscLabel("No current jobs"))
            }
            
            for job in self.jobs {
                mainStackView.addArrangedSubview(makeJobLabel(job))
            }
        }
    }

    func refreshStackView() {
        clearStackView()
        populateStackView()
    }
    
    func sendCode(_ code: String) {
        let message = Message(type: .sendingCode, payload: code)
        BeamerClient.shared.send(message)
    }
    
    func showCodeAlert() {
        let alertController = UIAlertController(
            title: "Pair with new device?",
            message: "A nearby device wants to pair with you.  Enter the code seen on the device to accept",
            preferredStyle: .alert)
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Code"
            textField.textAlignment = .center
        }
        
        let pairAction = UIAlertAction(title: "Pair", style: .default, handler: { (alert) in
            let textField = alertController.textFields![0] as UITextField
            let code = textField.text!
            
            self.sendCode(code)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (alert) in
            //TODO: handle cancel?
        }
        
        alertController.addAction(pairAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showCodeAcceptedAlert() {
        let alertController = UIAlertController(
            title: "Code Accepted",
            message: "Your code was accepted.  Your devices are now paired.",
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showCodeRejectedAlert() {
        let alertController = UIAlertController(
            title: "Code Rejected",
            message: "The code you supplied did not match the code on the Mac.  Your devices were not paired.",
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showJobCompletedAlert(_ job: Job) {
        let alertController = UIAlertController(
            title: "Job Completed",
            message: "\(job.name) has finished running.",
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showDebugAlert() {
        let alertController = UIAlertController(
            title: "Debug",
            message: "A debug message was sent!",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: BeamerClientDelegate
    
    func stateChanged() {
        refreshStackView()
    }
    
    func addJob(_ job: Job) {
        self.jobs.append(job)
        refreshStackView()
    }
    
    func removeJob(_ job: Job) {
        self.jobs = self.jobs.filter {$0.pid != job.pid}
        refreshStackView()
    }

    func handleMessage(_ message: Message) {
        print(message)
        
        switch message.type {
        case .pairRequest:
            showCodeAlert()
        case .codeAccepted:
            showCodeAcceptedAlert()
        case .codeRejected:
            showCodeRejectedAlert()
        case .jobAdded:
            if let job = message.job {
                addJob(job)
            }
        case .jobCompleted:
            showJobCompletedAlert(message.job!)
            removeJob(message.job!)
        case .debug:
            showDebugAlert()
        default:
            print("No action for this message type: \(message.type)")
        }
    }
}




