//
//  NetworkUtils.swift
//  TestDNS
//
//  Created by Shane Whitehead on 7/3/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation

enum SystemError: Swift.Error, CustomStringConvertible {
	case getaddrinfo(Date, Int32, String, Int32?)
	
	var description: String {
		switch self {
		case .getaddrinfo(let date, let errorCode, let description, let systemError):
			var text = "[\(preferredFormatter.string(from: date))] errorCode = \(errorCode) - \(description)"
			guard let systemError = systemError else {
				return text
			}
			text += "; systemError = \(systemError)"
			return text
		}
	}
}

struct NetworkUtils {
	static func getaddrinfo(node: String, service: String, hints: addrinfo?) throws -> [String] {
		var err: Int32
		var res: UnsafeMutablePointer<addrinfo>?
		
		print("Pinging \(node):\(service)")
		if var hints = hints {
			err = Darwin.getaddrinfo(node, service, &hints, &res)
		} else {
			err = Darwin.getaddrinfo(node, service, nil, &res)
		}
		if err != 0 {
			var errorMessage: String = "Unknown"
			if let pointerToError = gai_strerror(err) {
				errorMessage = String(cString: pointerToError)
			}
			if err == EAI_SYSTEM {
				throw SystemError.getaddrinfo(Date(), err, errorMessage, errno)
			}
			if err != 0 {
				throw SystemError.getaddrinfo(Date(), err, errorMessage, nil)
			}
		}
		defer {
			freeaddrinfo(res)
		}
		guard let firstAddr = res else {
			return []
		}
		
		var next: addrinfo? = firstAddr.pointee
		var addresses: [String] = []
		while next != nil {
			if let addrInfo = next {
				let desc = NetworkUtils.sockaddrDescription(from: addrInfo.ai_addr)
				addresses.append(desc)
			}
			
			next = next?.ai_next?.pointee ?? nil
		}
		
		return addresses
	}
	
	static func sockaddrDescription(from addr: UnsafePointer<sockaddr>) -> String
	{
		var host : String?
		var port : String?
		
		var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
		var servBuffer = [CChar](repeating: 0, count: Int(NI_MAXSERV))
		
		if (getnameinfo(addr, socklen_t(addr.pointee.sa_len),
										&hostBuffer, socklen_t(hostBuffer.count),
										&servBuffer, socklen_t(servBuffer.count),
										NI_NUMERICHOST | NI_NUMERICSERV) == 0) {
			host = String(cString: hostBuffer)
			port = String(cString: servBuffer)
		}
		return "host: " + (host ?? "?") + " port: " + (port ?? "?")
	}
	
}
