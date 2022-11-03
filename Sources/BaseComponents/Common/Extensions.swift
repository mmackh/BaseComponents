//
//  Extensions.swift
//  BaseComponents
//
//  Created by mmackh on 24.12.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public extension DispatchQueue {
    func async(after timeInterval: TimeInterval, execute work: @escaping @convention(block) () -> Void) {
        asyncAfter(deadline: .now() + timeInterval, execute: work)
    }
    
    private static var tokens: [String] = []
    func once(file: String = #file, function: String = #function, line: Int = #line, execute work: () -> Void, else: (()->())? = nil) {
        once(token: "\(file)\(function)\(line)", execute: work, else: `else`)
    }
    
    func once(token: String, execute work: ()->Void, else: (()->())? = nil) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if DispatchQueue.tokens.contains(token) {
            if let `else` = `else` {
                `else`()
            }
            return
        }
        DispatchQueue.tokens.append(token)
        work()
    }
}

public extension String {
    var lastPathComponent: String {
        if let url = URL(string: self) {
            return url.lastPathComponent
        }
        return ""
    }
    
    var pathExtension: String {
        if let url = URL(string: self) {
            return url.pathExtension
        }
        return ""
    }
}

/*
 NotificationCenter
 */
public extension NSObject {
    static var notificationObserverCounter: Int = 10
    
    fileprivate class NotificationReference {
        let reference: Any

        init(_ reference: Any) {
            self.reference = reference
        }

        deinit {
            NotificationCenter.default.removeObserver(reference)
        }
    }
    
    func observe<T>(_ notification: T, _ object: Any? = nil, _ handler: @escaping (Notification)->()) {
        guard let notificationName = NSObject.notificationName(notification) else { return }
        let token = NotificationCenter.default.addObserver(forName: notificationName, object: object, queue: .main, using: handler)
        objc_setAssociatedObject(self, "bc_notf_\(NSObject.notificationObserverCounter)", NotificationReference(token), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        NSObject.notificationObserverCounter += 1
    }

    func emit<T>(_ notification: T, obj: Any? = nil) {
        guard let notificationName = NSObject.notificationName(notification) else { return }
        NotificationCenter.default.post(name: notificationName, object: obj)
    }
    
    fileprivate static func notificationName<T>(_ input: T) -> Notification.Name? {
        if let notificationNameString = input as? String {
            return Notification.Name.init(notificationNameString)
        }
        if let notificationNameObject = input as? Notification.Name {
            return notificationNameObject
        }
        return nil
    }
}

public extension Array where Element: Equatable {
    enum `Type` {
        case first
        case last
        case all
    }
    
    @discardableResult
    mutating func remove(_ item: Element, type: `Type` = .first) -> Bool {
        switch type {
        case .first:
            if let idx = firstIndex(of: item) {
                remove(at: idx)
                return true
            }
        case .last:
            if let idx = lastIndex(of: item) {
                remove(at: idx)
                return true
            }
        case .all:
            removeAll { element in
                element == item
            }
        }
        return false
    }
}


public extension URLSession {
    
    /// is valid response
    /// - Parameter response: response
    /// - Returns: if it's valid, return true, or return false 
   func isValidResponse(response: HTTPURLResponse) -> Bool {
    guard (200..<300).contains(response.statusCode),
      let headers = response.allHeaderFields as? [String: String],
      let contentType = headers["Content-Type"], contentType.hasPrefix("application/json") else {
      return false
    }

    return true
  }
}

public extension URLRequest {
    init?(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        self.init(url: url)
    }

    var curlString: String {
        guard let url = url else { return "" }

        var baseCommand = "curl \(url.absoluteString)"
        if httpMethod == "HEAD" {
            baseCommand += " --head"
        }

        var command = [baseCommand]
        if let method = httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }

        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }

        if let data = httpBody,
            let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }

        return command.joined(separator: " \\\n\t")
    }
}

public extension NSURLRequest {
    @objc convenience init?(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        self.init(url: url)
    }

    @objc var curlString: String {
        return (self as URLRequest).curlString
    }
}

