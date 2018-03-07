//
//  RepeatingTimer.swift
//  TestDNS
//
//  Created by Shane Whitehead on 8/3/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

class RepeatingTimer {
  
  private lazy var timer: DispatchSourceTimer = {
    let t = DispatchSource.makeTimerSource()
    t.schedule(deadline: .now() + initialDelay, repeating: .milliseconds(Int(delay * 1000.0)))
    t.setEventHandler(handler: { [weak self] in
      self?.eventHandler?()
    })
    return t
  }()
  
  var eventHandler: (() -> Void)?
  
  private enum State {
    case suspended
    case resumed
  }
  
  private var state: State = .suspended
  
  private let initialDelay: TimeInterval!
  private let delay: TimeInterval!
  
  init(initialDelay: TimeInterval = 0, delay: TimeInterval) {
    self.initialDelay = initialDelay
    self.delay = delay
  }
  
  deinit {
    stop()
    eventHandler = nil
  }
  
  func stop() {
    timer.setEventHandler {}
    timer.cancel()
    /*
     If the timer is suspended, calling cancel without resuming
     triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
     */
    resume()
  }
  
  func resume() {
    if state == .resumed {
      return
    }
    state = .resumed
    timer.resume()
  }
  
  func suspend() {
    if state == .suspended {
      return
    }
    state = .suspended
    timer.suspend()
  }
}
