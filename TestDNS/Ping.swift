//
//  Ping.swift
//  TestDNS
//
//  Created by Shane Whitehead on 7/3/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

protocol PingDelegate {
	func lookupPerformedSuccessful(in: TimeInterval)
	func lookupFailed(with: Error)
	func lookup(found: String)
}

@objc class Ping: NSObject {

	fileprivate var ping: Timer? = nil
	
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
		return ping != nil
	}
	
	var delegate: PingDelegate?
	
	override init() {
		super.init()
	}
	
	func stop() {
		onMainThreadDo {
			if let ping = self.ping {
				ping.invalidate()
			}
			self.ping = nil
		}
	}
	
	func start() {
		onMainThreadDo {
			self.stop()
			guard self.hostName != nil && self.hostPort != nil else {
				print("!! Ping: Invalid host name, can not start")
				return
			}
			guard let timeRate = self.timeRate else {
				print("!! Ping: Invalid time rate, can not start")
				return
			}
			self.ping = Timer.scheduledTimer(withTimeInterval: timeRate, repeats: true) { (timer) in
				self.performReverseLookup()
			}
		}
	}
	
	func performReverseLookup() {
		onBackgroundThreadDo {
			guard let hostName = self.hostName, let hostPort = self.hostPort else {
				print("!! Ping: Invalid host name or port, can not perform reverse loopkup")
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
          stopWatch.stop()
          self.delegate?.lookupPerformedSuccessful(in: stopWatch.duration)
          for address in result {
            print("Ping: Found \(address)")
            self.delegate?.lookup(found: address)
          }
        } catch let badThings {
          stopWatch.stop()
          ok = false
          print("!! Ping: (\(tries)) Lookup failed with \(String(describing: badThings))")
          
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
