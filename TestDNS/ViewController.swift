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

	@IBOutlet weak var errorTextView: UITextView!
	
	@IBOutlet weak var updateTimeLabel: UILabel!
	
	var formatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.day, .hour, .minute, .second]
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
	
	let ping: Ping = Ping()
	
	let startTime: Date = Date()
	
	var upTimer: Timer?

	override func viewDidLoad() {
		super.viewDidLoad()
//    hostNameField.text = "confluence.worldreach.local"
//    hostPortField.text = "8090"
    hostNameField.text = "we.local"
    hostPortField.text = "51234"

		lookupRateSlider.value = 0
		
		errorTextView.text = ""
		
		updateStatus()
		
		ping.delegate = self
		ping.hostName = hostNameField.text
		ping.hostPort = hostPortField.text
		ping.timeRate = lookupRate

		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
		//Uncomment the line below if you want the tap not not interfere and cancel other interactions.
		//tap.cancelsTouchesInView = false
		view.addGestureRecognizer(tap)
		
		ping.start()
		
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
		ping.performReverseLookup()
	}
	
	@IBAction func lookupTimeRateDidChange(_ sender: Any) {
		lookupRate = minRateTime + (maxRateTime * Double(lookupRateSlider.value))
		lookupRateLabel.text = formatter.string(from: lookupRate) ?? "??"
	}
	
	@IBAction func lookupTimeRateWasUntouched(_ sender: Any) {
		ping.timeRate = lookupRate
	}
	
	@IBAction func hostNameDidEnd(_ sender: Any) {
		print("hostNameDidEnd")
		ping.hostName = hostNameField.text
	}
	
	@IBAction func hostPortDidEnd(_ sender: Any) {
		print("hostPortDidEnd")
		ping.hostPort = hostPortField.text
	}
}



extension ViewController: PingDelegate {
	
	func lookup(found: String) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.lookup(found: found)
      }
      return
    }
    var text = self.errorTextView.text ?? ""
    text += "[\(preferredFormatter.string(from: Date()))] Found \(found)\n"
    self.errorTextView.text = text
	}
	
	func lookupFailed(with: Error) {
    guard Thread.isMainThread else {
      onMainThreadDo {
        self.lookupFailed(with: with)
      }
      return
    }
    self.errorCount += 1
    self.updateStatus()
    var text = self.errorTextView.text ?? ""
    text += "\(with)\n"
    self.errorTextView.text = text
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
