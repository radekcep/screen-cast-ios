//
//  ConsoleLoggerDelegate.swift
//  
//
//  Created by Radek Čep on 16.01.2022.
//

import Foundation
import GoogleCast

class ConsoleLoggerDelegate: NSObject, GCKLoggerDelegate {
    func logMessage(_ message: String, at _: GCKLoggerLevel, fromFunction function: String, location: String) {
        print("\(location): \(function) - \(message)")
    }
}
