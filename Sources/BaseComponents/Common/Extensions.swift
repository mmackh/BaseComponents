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
    fileprivate class NotificationReference {
        let reference: Any

        init(_ reference: Any) {
            self.reference = reference
        }

        deinit {
            NotificationCenter.default.removeObserver(reference)
        }
    }
    
    func observe<T>(file: String = #file, function: String = #function, line: Int = #line, _ notification: T, _ object: Any? = nil, _ handler: @escaping (Notification)->()) {
        guard let notificationName = NSObject.notificationName(notification) else { return }
        let token = NotificationCenter.default.addObserver(forName: notificationName, object: object, queue: .main, using: handler)
        objc_setAssociatedObject(self, "bc_notf_\(file)\(function)\(line)", NotificationReference(token), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
