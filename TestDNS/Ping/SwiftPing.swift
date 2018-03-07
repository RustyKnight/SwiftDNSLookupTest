//
//  SwiftPing.swift
//  TestDNS
//
//  Created by Shane Whitehead on 8/3/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

protocol SwiftPingDelegate {
  func pingStarted(pinging: String)
  func pingDidStop()
  func ping(didFailWithDescription description: String, error: Error)
  func ping(didSendPacket packaet: Data, sequenceNumber: UInt16)
  func ping(didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error)
  func ping(didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16)
  func ping(didReceiveUnexpectedPacket packet: Data)
}

class SwiftPing: NSObject, SimplePingDelegate {
  
  let hostName: String!
  
  var delegate: SwiftPingDelegate?
  
  fileprivate var pinger: SimplePing?
  var sendTimer: RepeatingTimer?
  
  init(hostName: String) {
    self.hostName = hostName
  }
  
  /// Called by the table view selection delegate callback to start the ping.
  func start(forceIPv4: Bool = false, forceIPv6: Bool = false) {
    let pinger = SimplePing(hostName: self.hostName)
    self.pinger = pinger
    
    // By default we use the first IP address we get back from host resolution (.Any)
    // but these flags let the user override that.
    
    if (forceIPv4 && !forceIPv6) {
      pinger.addressStyle = .icmPv4
    } else if (forceIPv6 && !forceIPv4) {
      pinger.addressStyle = .icmPv6
    }
    
    pinger.delegate = self
    pinger.start()
  }
  
  /// Called by the table view selection delegate callback to stop the ping.
  
  func stop() {
    NSLog("stop")
    self.pinger?.stop()
    self.pinger = nil

    stopTimer()
    
    delegate?.pingDidStop()
  }
  
  fileprivate func stopTimer() {
    self.sendTimer?.stop()
    self.sendTimer = nil
  }
  
  /// Sends a ping.
  ///
  /// Called to send a ping, both directly (as soon as the SimplePing object starts up) and
  /// via a timer (to continue sending pings periodically).
  
  @objc func sendPing() {
    self.pinger!.send(with: nil)
  }
  
  // MARK: pinger delegate callback
  
  func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
    let simpleAddress = SwiftPing.displayAddressForAddress(address: address as NSData)
    
    delegate?.pingStarted(pinging: simpleAddress)
    
    stopTimer()
    onBackgroundThreadDo {
      self.sendTimer = RepeatingTimer(initialDelay: 1.0, delay: 1.0)
      self.sendTimer?.eventHandler = {
//        print("Send PING")
        self.sendPing()
      }
      self.sendTimer?.resume()
    }
  }
  
  func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
    let shorError = SwiftPing.shortErrorFromError(error: error as NSError)
    delegate?.ping(didFailWithDescription: shorError, error: error)
    self.stop()
  }
  
  func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
    delegate?.ping(didSendPacket: packet, sequenceNumber: sequenceNumber)
  }
  
  func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
    delegate?.ping(didFailToSendPacket: packet, sequenceNumber: sequenceNumber, error: error)
  }
  
  func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
    delegate?.ping(didReceivePingResponsePacket: packet, sequenceNumber: sequenceNumber)
  }
  
  func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
    delegate?.ping(didReceiveUnexpectedPacket: packet)
  }
  
  // MARK: utilities
  
  /// Returns the string representation of the supplied address.
  ///
  /// - parameter address: Contains a `(struct sockaddr)` with the address to render.
  ///
  /// - returns: A string representation of that address.
  
  static func displayAddressForAddress(address: NSData) -> String {
    var hostStr = [Int8](repeating: 0, count: Int(NI_MAXHOST))
    
    let success = getnameinfo(
      address.bytes.assumingMemoryBound(to: sockaddr.self),
      socklen_t(address.length),
      &hostStr,
      socklen_t(hostStr.count),
      nil,
      0,
      NI_NUMERICHOST
      ) == 0
    let result: String
    if success {
      result = String(cString: hostStr)
    } else {
      result = "?"
    }
    return result
  }
  
  /// Returns a short error string for the supplied error.
  ///
  /// - parameter error: The error to render.
  ///
  /// - returns: A short string representing that error.
  
  static func shortErrorFromError(error: NSError) -> String {
    if error.domain == kCFErrorDomainCFNetwork as String && error.code == Int(CFNetworkErrors.cfHostErrorUnknown.rawValue) {
      if let failureObj = error.userInfo[kCFGetAddrInfoFailureKey as String] {
        if let failureNum = failureObj as? NSNumber {
          if failureNum.intValue != 0 {
            let f = gai_strerror(Int32(failureNum.intValue))
            if f != nil {
              return String(cString: f!)
            }
          }
        }
      }
    }
    if let result = error.localizedFailureReason {
      return result
    }
    return error.localizedDescription
  }
//
//  // MARK: table view delegate callback
//
//  @IBOutlet var forceIPv4Cell: UITableViewCell!
//  @IBOutlet var forceIPv6Cell: UITableViewCell!
//  @IBOutlet var startStopCell: UITableViewCell!
//
//  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    let cell = self.tableView.cellForRow(at: indexPath as IndexPath)!
//    switch cell {
//    case forceIPv4Cell, forceIPv6Cell:
//      cell.accessoryType = cell.accessoryType == .none ? .checkmark : .none
//    case startStopCell:
//      if self.pinger == nil {
//        let forceIPv4 = self.forceIPv4Cell.accessoryType != .none
//        let forceIPv6 = self.forceIPv6Cell.accessoryType != .none
//        self.start(forceIPv4: forceIPv4, forceIPv6: forceIPv6)
//      } else {
//        self.stop()
//      }
//    default:
//      fatalError()
//    }
//    self.tableView.deselectRow(at: indexPath, animated: true)
//  }
//
//  func pingerWillStart() {
//    self.startStopCell.textLabel!.text = "Stop…"
//  }
//
//  func pingerDidStop() {
//    self.startStopCell.textLabel!.text = "Start…"
//  }
}
