//
//  Files.swift
//  BaseComponents
//
//  Created by mmackh on 19.03.20.
//  Copyright © 2019 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

public class Files {
    public static var debug: Bool = false
    
    public let path: String
    public var pathURL: URL {
        return URL(fileURLWithPath: path)
    }
    
    public init(name: String, searchPathDirectory: FileManager.SearchPathDirectory = .documentDirectory, createIfNeeded: Bool = true) {
        let basePathURL = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first!
        let pathURL = basePathURL.appendingPathComponent(name)
        let path = pathURL.path
        if createIfNeeded && !FileManager.default.fileExists(atPath: path) {
            let directoryURL = pathURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: nil) {
                do {
                    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    if Files.debug {
                        print("BaseComponents.Files: unable to" ,"CREATE", path,"\n\nERROR\n", error)
                    }
                }
            }
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        }
        self.path = path
    }
    
    @discardableResult
    public func save<T: Codable>(_ obj: T) -> Bool {
        var saved = false
        do {
            if let string = obj as? String {
                try string.write(toFile: path, atomically: false, encoding: .utf8)
                saved = true
            }
            if let data = obj as? Data {
                try data.write(to: pathURL)
                saved = true
            }
            if let image = obj as? UIImage {
                return save(image.jpegData(compressionQuality: 0.7))
            }
            if saved == false {
                let data = try JSONEncoder().encode(obj)
                return save(data)
            }
        } catch {
            if Files.debug {
                print("BaseComponents.Files: unable to" ,"SAVE", path,"\n\nERROR\n", error)
            }
            return false
        }
        return true
    }
    
    public func read<T: Codable>(as type: T.Type) -> T? {
        do {
            if type == String.self {
                return try String(contentsOfFile: path) as? T
            }
            if type == Data.self {
                return try Data(contentsOf: pathURL) as? T
            }
            if type == UIImage.self {
                return UIImage(contentsOfFile: path) as? T
            }
            
            let data = try Data(contentsOf: pathURL)
            let model = try JSONDecoder().decode(type, from: data)
            return model
        } catch {
            if Files.debug {
                print("BaseComponents.Files: unable to" ,"READ", path,"\n\nERROR\n", error)
            }
            return nil
        }
    }
    
    @discardableResult
    public func delete() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            if Files.debug {
                print("BaseComponents.Files: unable to" ,"DELETE", path,"\n\nERROR\n", error)
            }
            return false
        }
        return true
    }
    
    public func exists() -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
