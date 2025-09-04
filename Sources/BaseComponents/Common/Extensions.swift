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
    private enum AssociatedKeys {
        static var notificationTokens: UInt8 = 0
    }

    fileprivate final class NotificationReference {
        let reference: NSObjectProtocol

        init(_ reference: NSObjectProtocol) {
            self.reference = reference
        }

        deinit {
            NotificationCenter.default.removeObserver(reference)
        }
    }

    private var notificationReferences: NSMutableArray {
        get {
            if let array: NSMutableArray = objc_getAssociatedObject(self, &AssociatedKeys.notificationTokens) as? NSMutableArray {
                return array
            }
            let array: NSMutableArray = NSMutableArray()
            objc_setAssociatedObject(self, &AssociatedKeys.notificationTokens, array, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return array
        }
    }

    @discardableResult
    func observe<T>(_ notification: T, _ object: Any? = nil, _ handler: @escaping (Notification) -> ()) -> NSObjectProtocol? {
        guard let notificationName: Notification.Name = NSObject.notificationName(notification) else { return nil }
        let token: NSObjectProtocol = NotificationCenter.default.addObserver(forName: notificationName, object: object, queue: OperationQueue.main, using: handler)
        notificationReferences.add(NotificationReference(token))
        return token
    }

    func emit<T>(_ notification: T, obj: Any? = nil) {
        guard let notificationName: Notification.Name = NSObject.notificationName(notification) else { return }
        NotificationCenter.default.post(name: notificationName, object: obj)
    }

    fileprivate static func notificationName<T>(_ input: T) -> Notification.Name? {
        if let notificationNameString: String = input as? String {
            return Notification.Name(notificationNameString)
        }
        if let notificationNameObject: Notification.Name = input as? Notification.Name {
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

/*
 Excempt variable from Codable, e.g.:
 @TransientCodable
 var temporaryName: Any? = nil
 */
@propertyWrapper
public struct TransientCodable<Variable>: Codable {
    private(set) var value: Variable!
    public var wrappedValue: Variable {
        get { value }
        set { value = newValue }
    }
    
    public init(wrappedValue value: Variable) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws { }
    
    public func encode(to encoder: Encoder) throws {  }
}
