//
//  UserDefaultsData.swift
//  BaseComponents
//
//  Created by mmackh on 21.06.21.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

@propertyWrapper
open class UserDefaultsData<T> {
    let key: String
    let defaultValue: T
    
    var cacheValue: T? = nil
    var cache: Bool

    public init(_ key: String, defaultValue: T, cache: Bool = false) {
        self.key = key
        self.defaultValue = defaultValue
        self.cache = cache
    }

    public var wrappedValue: T {
        get {
            if cache, let cacheValue = cacheValue { return cacheValue }
            let diskValue = UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
            self.cacheValue = diskValue
            return diskValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            cacheValue = nil
        }
    }
}
