//
//  DiskData.swift
//  BaseComponents
//
//  Created by mmackh on 19.03.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

public class DiskData: CustomDebugStringConvertible {
    public var debugDescription: String {
        return String(describing: type(of: self)) + ": " + path
    }
    
    public static var debug: Bool = false
    
    public let pathURL: URL
    public let path: String
    public let name: String
    
    public init(pathURL: URL) {
        self.pathURL = pathURL
        self.path = pathURL.path
        self.name = pathURL.lastPathComponent
    }
}

public class File: DiskData {
    
    public var directory: Directory
    
    public init(name: String, searchPathDirectory: FileManager.SearchPathDirectory = .documentDirectory, createIfNeeded: Bool = true) {
        let basePathURL = Directory.basePathURL(for: searchPathDirectory)
        let pathURL = basePathURL.appendingPathComponent(name)
        self.directory = Directory(enclosing: pathURL)
        super.init(pathURL: pathURL)
        
        let path = pathURL.path
        
        if createIfNeeded && !FileManager.default.fileExists(atPath: path) {
            if !FileManager.default.fileExists(atPath: directory.path) {
                directory.create()
            }
            self.create()
        }
    }
    
    public init(pathURL: URL, enclosingDirectory: Directory? = nil) {
        self.directory = (enclosingDirectory == nil) ? Directory(pathURL: pathURL) : enclosingDirectory!
        super.init(pathURL: pathURL)
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
            if DiskData.debug {
                print("BaseComponents.DiskData.File: unable to" ,"SAVE", path,"\n\nERROR\n", error)
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
            if DiskData.debug {
                print("BaseComponents.DiskData.File: unable to" ,"READ", path,"\n\nERROR\n", error)
            }
            return nil
        }
    }
    
    @discardableResult
    public func copy(to file: File, overwrite: Bool = true) -> Bool {
        do {
            if overwrite {
                file.delete()
            }
            try FileManager.default.copyItem(at: pathURL, to: file.pathURL)
        } catch {
            if DiskData.debug {
                print("BaseComponents.DiskData.File: unable to" ,"COPY", path,"\n\nERROR\n", error)
            }
            return false
        }
        return true
    }
    
    @discardableResult
    public func delete() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            if DiskData.debug {
                print("BaseComponents.DiskData.File: unable to" ,"DELETE", path,"\n\nERROR\n", error)
            }
            return false
        }
        return true
    }
    
    public func exists() -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    @discardableResult
    public func create() -> Bool {
        return FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
    }
}

// Read & Write UIImages with File
public extension File {
    enum Quality: Float {
        case png
        case jpgOriginal = 1.0
        case jpgHigh = 0.8
        case jpgMedium = 0.5
        case jpgLow = 0.3
    }
    
    @discardableResult
    func save(_ obj: UIImage, quality: Quality = .jpgHigh) -> Bool {
        return save(quality == .png ? obj.pngData() : obj.jpegData(compressionQuality: CGFloat(quality.rawValue)))
    }
    
    func read(as type: UIImage) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
}

public class Directory: DiskData {
    fileprivate init(enclosing filePathURL: URL) {
        super.init(pathURL: filePathURL.deletingLastPathComponent())
    }
    
    public override init(pathURL: URL) {
        super.init(pathURL: pathURL)
    }
    
    public init(searchPathDirectory: FileManager.SearchPathDirectory) {
        super.init(pathURL: Directory.basePathURL(for: searchPathDirectory))
    }
    
    public static func basePathURL(for searchPathDirectory: FileManager.SearchPathDirectory) -> URL
    {
        return FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first!
    }
    
    @discardableResult
    public func create() -> Bool {
        do {
            try FileManager.default.createDirectory(at: self.pathURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            if File.debug {
                print("BaseComponents.DiskData.Directory: unable to" ,"CREATE", pathURL,"\n\nERROR\n", error)
            }
            return false
        }
        return true
    }
    
    public func contents(skipHiddenFiles: Bool = true) -> [DiskData] {
        do {
            var directoryContents: [DiskData] = []
            let fileManager = FileManager.default
            let diskDataURLs = try fileManager.contentsOfDirectory(at: self.pathURL, includingPropertiesForKeys: [.isDirectoryKey], options: skipHiddenFiles ? .skipsHiddenFiles : [])
            for diskDataURL in diskDataURLs {
                if try diskDataURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false {
                    directoryContents.append(Directory(pathURL: diskDataURL))
                } else {
                    directoryContents.append(File(pathURL: diskDataURL, enclosingDirectory: self))
                }
            }
            return directoryContents
            
        } catch {
            if DiskData.debug {
                print("BaseComponents.DiskData.Directory: unable to" ,"LIST", self.pathURL.path,"\n\nERROR\n", error)
            }
        }
        return []
    }
    
    public func exists() -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    public func newFile(name: String, createIfNeeded: Bool = true) -> File {
        let file = File(pathURL: pathURL.appendingPathComponent(name))
        if createIfNeeded && !file.exists() {
            file.create()
        }
        return file
    }
    
    public func newDirectory(name: String, createIfNeeded: Bool = true) -> Directory {
        let directory = Directory(pathURL: pathURL.appendingPathComponent(name, isDirectory: createIfNeeded))
        if createIfNeeded && !directory.exists() {
            directory.create()
        }
        return directory
    }
    
    public func zip(completionHandler: (File)->()) {
        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.coordinate(readingItemAt: pathURL, options: .forUploading, error: nil) { (url) in
            completionHandler(File(pathURL: url))
        }
    }
}
