//
//  StopWatch.swift
//  TestDNS
//
//  Created by Shane Whitehead on 7/3/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation
public class StopWatch: CustomStringConvertible {
	
	var startTime: Date?
	var endTime: Date?
	
	public var description: String {
		return formattedDuration
	}
	
	public init() {
	}
	
	@discardableResult
	public func start() -> StopWatch {
		endTime = nil
		startTime = Date()
		return self
	}
	
	@discardableResult
	public func stop() -> StopWatch {
		guard startTime != nil else {
			return self
		}
		endTime = Date()
		return self
	}
	
	public var duration: TimeInterval {
		guard let startAt = startTime, let endedAt = endTime else {
			return -1
		}
		return endedAt.timeIntervalSince(startAt)
	}
	
	public var formattedDuration: String {
		guard let startAt = startTime, let endedAt = endTime else {
			return "Unknown"
		}
		let form = DateComponentsFormatter()
		form.maximumUnitCount = 2
		form.unitsStyle = .full
		form.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
		guard let took = form.string(from: startAt, to: endedAt) else {
			return "Unknown"
		}
		return took
	}
}
