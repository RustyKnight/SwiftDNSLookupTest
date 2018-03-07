//
//  ViewController.swift
//  TestDNS
//
//  Created by Shane Whitehead on 7/3/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var hostNameField: UITextField!
  @IBOutlet weak var hostPortField: UITextField!
  @IBOutlet weak var lookupCountLabel: UILabel!
  @IBOutlet weak var errorCountLabel: UILabel!
  
  @IBOutlet weak var lookupRateLabel: UILabel!
  @IBOutlet weak var lookupRateSlider: UISlider!
  
  @IBOutlet weak var maxTimeLabel: UILabel!
  @IBOutlet weak var minTimeLabel: UILabel!
  @IBOutlet weak var avgTimeLabel: UILabel!
  
  @IBOutlet weak var updateTimeLabel: UILabel!
  
  @IBOutlet weak var lastFailureLabel: UILabel!
  @IBOutlet weak var lastSuccessLabel: UILabel!
  
  @IBOutlet weak var pingStatusLabel: UILabel!
  @IBOutlet weak var pingMinTime: UILabel!
  @IBOutlet weak var pingMaxTime: UILabel!
  @IBOutlet weak var pingAvgTime: UILabel!
  @IBOutlet weak var pingCountLabel: UILabel!
  
  var formatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day, .hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter
  }()
  
  var pingFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day, .hour, .minute, .second, .nanosecond]
    formatter.unitsStyle = .abbreviated
    return formatter
  }()

  let minRateTime: TimeInterval = 60
  let maxRateTime: TimeInterval = (60 * 60) - (60)
  
  var lookupRate: TimeInterval = 60
  
  var maxTime: TimeInterval = 0
  var minTime: TimeInterval = 0
  var totalTime: TimeInterval = 0
  var totalLookups: Int = 0
  var errorCount: Int = 0
  
  let dnsLookup: DNSLookupTimer = DNSLookupTimer()
  
  let startTime: Date = Date()
  
  var upTimer: Timer?
  
  var swiftPing: SwiftPing?
  
  var pings: [UInt16: Date] = [:]
  
  var totalPingCount: Int = 0
  var failedPingCount: Int = 0
  var totalPingTime: TimeInterval = 0
  var minPingTime: TimeInterval?
  var maxPingTime: TimeInterval = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //    hostNameField.text = "confluence.worldreach.local"
    //    hostPortField.text = "8090"
    hostNameField.text = "we.local"
    hostPortField.text = "51234"
    
    lastFailureLabel.isHidden = true
    lastSuccessLabel.isHidden = true
    
    lastFailureLabel.text = nil
    lastSuccessLabel.text = nil
    
    lookupRateSlider.value = 0
    
    //    errorTextView.text = ""
    
    pingStatusLabel.text = "Ping..."
    pingMinTime.text = "0"
    pingMaxTime.text = "0"
    pingAvgTime.text = "0"
    
    updateStatus()
    
    dnsLookup.delegate = self
    dnsLookup.hostName = hostNameField.text
    dnsLookup.hostPort = hostPortField.text
    dnsLookup.timeRate = lookupRate
    
    swiftPing = SwiftPing(hostName: hostNameField.text!)
    swiftPing?.delegate = self
    swiftPing?.start()
    
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
    //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
    //tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
    
    dnsLookup.start()
    
    upTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
      let upTime = Date().timeIntervalSince(self.startTime)
      self.updateTimeLabel.text = self.formatter.string(from: upTime)
    })
    
  }
  
  @objc func dismissKeyboard() {
    //Causes the view (or one of its embedded text fields) to resign the first responder status.
    view.endEditing(true)
  }
  
  func updateStatus() {
    lookupCountLabel.text = String(totalLookups)
    errorCountLabel.text = String(errorCount)
    
    maxTimeLabel.text = formatter.string(from: maxTime) ?? "0"
    minTimeLabel.text = formatter.string(from: minTime) ?? "0"
    
    var avgTime = 0.0
    if totalLookups > 0 {
      avgTime = totalTime / Double(totalLookups)
    }
    
    avgTimeLabel.text = formatter.string(from: avgTime) ?? "0"
  }
  
  @IBAction func pingNowTapped(_ sender: Any) {
    dnsLookup.performReverseLookup()
  }
  
  @IBAction func lookupTimeRateDidChange(_ sender: Any) {
    lookupRate = minRateTime + (maxRateTime * Double(lookupRateSlider.value))
    lookupRateLabel.text = formatter.string(from: lookupRate) ?? "??"
  }
  
  @IBAction func lookupTimeRateWasUntouched(_ sender: Any) {
    dnsLookup.timeRate = lookupRate
  }
  
  @IBAction func hostNameDidEnd(_ sender: Any) {
    print("hostNameDidEnd")
    dnsLookup.hostName = hostNameField.text
  }
  
  @IBAction func hostPortDidEnd(_ sender: Any) {
    print("hostPortDidEnd")
    dnsLookup.hostPort = hostPortField.text
  }
}

extension ViewController: DNSLookupTimerDelegate {
  
  func lookup(found: String) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.lookup(found: found)
      }
      return
    }
    //    var text = self.errorTextView.text ?? ""
    //    text += "[\(preferredFormatter.string(from: Date()))] Found \(found)\n"
    //    self.errorTextView.text = text
    
    lastSuccessLabel.text = "[\(preferredFormatter.string(from: Date()))] \(found)"
    lastSuccessLabel.isHidden = false
  }
  
  func lookupFailed(with: Error) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.lookupFailed(with: with)
      }
      return
    }
    self.errorCount += 1
    lastFailureLabel.text = "\(with)"
    lastFailureLabel.isHidden = false
  }
  
  func lookupPerformedSuccessful(in duration: TimeInterval) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.lookupPerformedSuccessful(in: duration)
      }
      return
    }
    self.totalTime += duration
    self.totalLookups += 1
    self.minTime = min(self.minTime, duration)
    self.maxTime = max(self.maxTime, duration)
    self.updateStatus()
  }
}

extension ViewController: SwiftPingDelegate {
  func ping(didSendPacket packet: Data, sequenceNumber: UInt16) {
    pings[sequenceNumber] = Date()
  }
  
  func ping(didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
    guard let date = pings[sequenceNumber] else {
      return
    }
    totalPingCount += 1
    pings.removeValue(forKey: sequenceNumber)
    
    let duration = Date().timeIntervalSince(date)
    
    updatePingStatus(duration)
  }
  
  func updatePingStatus(_ duration: TimeInterval) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.updatePingStatus(duration)
      }
      return
    }
    
    totalPingTime += duration
    maxPingTime = max(maxPingTime, duration)
    minPingTime = min(minPingTime ?? Double.greatestFiniteMagnitude, duration)
    
    let avgTime = totalPingTime / Double(totalPingCount)
    
    pingMaxTime.text = formatter.string(from: maxPingTime)
    pingMinTime.text = formatter.string(from: maxPingTime)
    pingAvgTime.text = formatter.string(from: avgTime)

    self.pingCountLabel.text = "\(self.totalPingCount)\\\(self.failedPingCount)"
  }
  
  func pingStarted(pinging: String) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.pingStarted(pinging: pinging)
      }
      return
    }
    pingStatusLabel.textColor = UIColor.black
    pingStatusLabel.backgroundColor = UIColor.clear
    pingStatusLabel.text = "Pinging \(pinging)"
  }
  
  func pingDidStop() {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.pingDidStop()
      }
      return
    }
    //    pingStatusLabel.text = "Ping Stopped"
  }
  
  func ping(didFailWithDescription description: String, error: Error) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.ping(didFailWithDescription:description, error: error)
      }
      return
    }
    pingStatusLabel.textColor = lastFailureLabel.textColor
    pingStatusLabel.backgroundColor = lastFailureLabel.backgroundColor
    pingStatusLabel.text = "Ping failed with \(description)"
  }
  //
  //  func ping(didSendPacket: Data, sequenceNumber: UInt16) {
  //    guard Thread.isMainThread else {
  //      self.ping(didSendPacket:didSendPacket, sequenceNumber: sequenceNumber)
  //    }
  //    print("Ping send \(sequenceNumber)")
  //  }
  
  func ping(didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
    pings.removeValue(forKey: sequenceNumber)
    failedPingCount += 0
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.pingCountLabel.text = "\(self.totalPingCount)\\\(self.failedPingCount)"
      }
      return
    }
  }
  
  //  func ping(didReceivePingResponsePacketpacket: Data, sequenceNumber: UInt16) {
  //    guard Thread.isMainThread else {
  //      self.ping(didReceivePingResponsePacket: didReceivePingResponsePacketpacket, sequenceNumber: sequenceNumber)
  //    }
  //    print("Ping receieved \(sequenceNumber)")
  //  }
  
  func ping(didReceiveUnexpectedPacket packet: Data) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.ping(didReceiveUnexpectedPacket:packet)
      }
      return
    }
  }
  
  
}
