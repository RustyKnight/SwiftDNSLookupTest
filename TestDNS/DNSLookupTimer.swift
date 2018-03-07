//
//  Ping.swift
//  TestDNS
//
//  Created by Shane Whitehead on 7/3/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

protocol DNSLookupTimerDelegate {
  func lookupPerformedSuccessful(in: TimeInterval)
  func lookupFailed(with: Error)
  func lookup(found: String)
}

@objc class DNSLookupTimer: NSObject {
  
  fileprivate var timer: RepeatingTimer? = nil
  
  var hostName: String?
  var hostPort: String?
  var timeRate: TimeInterval? {
    didSet {
      guard isRunning else {
        return
      }
      stop()
      start()
    }
  }
  
  var isRunning: Bool {
    return timer != nil
  }
  
  var delegate: DNSLookupTimerDelegate?
  
  override init() {
    super.init()
  }
  
  func stop() {
    guard let timer = timer else {
      return
    }
    timer.stop()
    self.timer = nil
  }
  
  func start() {
    stop()
    guard hostName != nil && hostPort != nil else {
      print("!! Lookup: Invalid host name, can not start")
      return
    }
    guard let timeRate = timeRate else {
      print("!! Lookup: Invalid time rate, can not start")
      return
    }
    onBackgroundThreadDo {
      self.timer = RepeatingTimer(delay: timeRate)
      self.timer?.eventHandler = {
        self.performReverseLookup()
      }
      self.timer?.resume()
    }
  }
  
  func performReverseLookup() {
    guard let hostName = self.hostName, let hostPort = self.hostPort else {
      print("!! Lookup: Invalid host name or port, can not perform reverse loopkup")
      self.stop()
      return
    }
    let hints = addrinfo(ai_flags: 0,
                         ai_family: AF_UNSPEC,
                         ai_socktype: SOCK_STREAM,
                         ai_protocol: IPPROTO_TCP,
                         ai_addrlen: 0,
                         ai_canonname: nil,
                         ai_addr: nil,
                         ai_next: nil)
    
    var error: Error? = nil
    var tries: Int = 0
    var ok = true
    
    let stopWatch = StopWatch().start()
    repeat {
      do {
        let result = try NetworkUtils.getaddrinfo(node: hostName,
                                                  service: hostPort,
                                                  hints: hints)
        ok = true
        stopWatch.stop()
        self.delegate?.lookupPerformedSuccessful(in: stopWatch.duration)
        for address in result {
          print("Lookup: Found \(address)")
          self.delegate?.lookup(found: address)
        }
      } catch let badThings {
        stopWatch.stop()
        ok = false
        print("!! Lookup: (\(tries)) Lookup failed with \(String(describing: badThings))")
        
        tries += 1
        if tries > 3 {
          error = badThings
          ok = true
        }
      }
    } while !ok
    if let result = error {
      self.delegate?.lookupFailed(with: result)
      self.delegate?.lookupPerformedSuccessful(in: stopWatch.duration)
    }
  }
}

/// Performs the specificed action on the main thread
/// If the call is made within the main thread, then it
/// is executed immeditaly, otherwise it is scheduled to
/// run on the main thread at some point in the future
///
/// - Parameter call: Action to be executed
func onMainThreadDo(_ call: @escaping () -> Void) {
  guard !Thread.isMainThread else {
    call()
    return
  }
  DispatchQueue.main.async {
    call()
  }
}


/// Performs the specified action on the global dispatch queue
///
/// - Parameter call: Action to be executed
func onBackgroundThreadDo(_ call: @escaping () -> Void) {
  DispatchQueue.global().async {
    call()
  }
}
