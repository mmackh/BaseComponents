//
//  CloudData.swift
//  BaseComponents
//
//  Created by mmackh on 14.05.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


import Foundation
import CloudKit

public protocol CloudKitDataCodable: AnyObject, Codable {
    var record: CloudKitRecord? { get set }
    func searchableKeywords() -> String?
    
    func equalTo(_ ckRecord: CKRecord) -> Bool
}

public extension CloudKitDataCodable {
    func equalTo(_ ckRecord: CKRecord) -> Bool {
        guard let record = record else { return false }
        if ckRecord.recordID.recordName != record.id ||
           ckRecord.recordType != String(describing: type(of: self)) ||
           ckRecord.modificationDate != record.modificationDate {
            return false
        }
        return true
    }
}

open class CloudKitRecord: Codable {
    public let id: String
    public let changeTag: String
    public let creationDate: Date?
    public let modificationDate: Date?
    public let zoneName: String
    public let zoneOwnerName: String
   
    init(record: CKRecord) {
        self.id = record.recordID.recordName
        self.changeTag = record.recordChangeTag ?? ""
        self.creationDate = record.creationDate
        self.modificationDate = record.modificationDate
        
        
        self.zoneName = record.recordID.zoneID.zoneName
        self.zoneOwnerName = record.recordID.zoneID.ownerName
    }
    
    func ckRecordID() -> CKRecord.ID {
        return CKRecord.ID(recordName: id, zoneID: .init(zoneName: zoneName, ownerName: zoneOwnerName))
    }
}

open class CloudKitDataProvider {
    private class Keys {
        static let dataKey = "data"
        static let searchKey = "search"
    }
    
    public static let queue = DispatchQueue.init(label: "at.BaseComponents.CloudKitData.Async")
    public static var qualityOfService: QualityOfService = .userInteractive
    
    public var container = CKContainer.default()
    public var databaseScope: CKDatabase.Scope
    public var database: CKDatabase {
        get {
            return self.container.database(with: databaseScope)
        }
    }
    public var zone: CKRecordZone
    public var userID: CKRecord.ID?
    public var onShouldUpdate: (()->())? = nil
    
    public init(_ databaseScope: CKDatabase.Scope, zone: CKRecordZone = .default()) {
        self.databaseScope = databaseScope
        self.zone = zone
        
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyValueChanged(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    @objc func onKeyValueChanged(_ notification:Notification) {
        if let onShouldUpdate = onShouldUpdate {
            onShouldUpdate()
        }
    }
    
    static func storeChangeInKeyValueCloud() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let keyValueStore = NSUbiquitousKeyValueStore.default
            keyValueStore.set(Date(), forKey: "sync")
            keyValueStore.synchronize()
        }
    }
    
    public func update(onRecordChanged: @escaping(_ ckRecord: CKRecord)->(), onRecordDeleted: @escaping(_ recordID: String, _ type: String)->(), completionBlock: @escaping(Error?)->()) {
        let serverChangeTokenFile: File = File(name: "at.BaseComponents.CloudKitData.serverChangeToken")
        func saveToken(_ token: CKServerChangeToken?) {
            if let token = token {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                    serverChangeTokenFile.save(data)
                } catch { }
            }
        }
        func getToken() -> CKServerChangeToken? {
            var token: CKServerChangeToken? = nil
            do {
                token = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: serverChangeTokenFile.read(as: Data.self) ?? Data())
            } catch { }
            return token
        }
        
        let defaultZoneOptions = CKFetchRecordZoneChangesOperation.ZoneOptions()
        defaultZoneOptions.previousServerChangeToken = getToken()
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zone.zoneID], optionsByRecordZoneID: [zone.zoneID:defaultZoneOptions])
        operation.recordChangedBlock = { record in
            onRecordChanged(record)
        }
        operation.recordWithIDWasDeletedBlock = { recordID, type in
            onRecordDeleted(recordID.recordName, type)
        }
        operation.recordZoneChangeTokensUpdatedBlock = { (recordZoneID, serverChangeToken, data) in
            saveToken(serverChangeToken)
        }

        operation.recordZoneFetchCompletionBlock = { (recordZoneID, serverChangeToken, clientChangeTokenData, moreComing, recordZoneError) in
          if recordZoneError != nil {
            return
          }
          saveToken(serverChangeToken)
        }

        operation.fetchRecordZoneChangesCompletionBlock = { (error) in
            completionBlock(error)
        }
        
        database.add(operation)
    }
    
    public func save<T: CloudKitDataCodable>(_ object: T, completionHandler: @escaping(T?, Error?)->()) {
        func respond(_ ckRecord: CKRecord?, _ error: Error?) {
            func signal(_ object: T?, _ error: Error?) {
                DispatchQueue.main.async {
                    completionHandler(object, error)
                }
            }
            
            if let ckRecord = ckRecord {
                object.record = CloudKitRecord(record: ckRecord)
                signal(object, nil)
                CloudKitDataProvider.storeChangeInKeyValueCloud()
            } else {
                signal(nil, error)
            }
        }
        
        CloudKitDataProvider.ckRecord(from: object) { (record, error) in
            guard let record = record else {
                respond(nil, error)
                return
            }
            
            if object.record != nil {
                let modifyOperation = CKModifyRecordsOperation()
                modifyOperation.recordsToSave = [record]
                modifyOperation.savePolicy = .allKeys
                modifyOperation.qualityOfService = CloudKitDataProvider.qualityOfService
                modifyOperation.perRecordCompletionBlock = { ckRecord, error in
                    respond(ckRecord, error)
                }
                self.database.add(modifyOperation)
                return
            }
            
            self.database.save(record) { (ckRecord, error) in
                respond(ckRecord, nil)
            }
        }
    }
    
    public func fetch<T: CloudKitDataCodable>(_ type: T.Type, with request: CloudKitRequest = .init(), completionHandler: @escaping([T]?,Error?) -> ()) {
        CloudKitDataProvider.queue.async {
            let limitRequestToCurrentUser = request.limitResultsToCurrentUser && self.database.databaseScope == .public
            
            if limitRequestToCurrentUser && self.userID == nil {
                self.container.fetchUserRecordID { (userID, error) -> Void in
                    if let userID = userID {
                        self.userID = userID
                        self.fetch(type, with: request, completionHandler: completionHandler)
                    } else {
                        completionHandler(nil,error)
                    }
                }
                return
            }
            
            var targetArray: [T] = []
            
            var predicate = limitRequestToCurrentUser ?
                NSPredicate(format: "creatorUserRecordID == %@", self.userID!)
                : NSPredicate(value: true)
            if let requestPredicate = request.predicate {
                predicate = requestPredicate
            }
            
            let query = CKQuery(recordType: String(describing: type), predicate: predicate)
            let operation = CKQueryOperation(query: query)
            operation.qualityOfService = CloudKitDataProvider.qualityOfService
            operation.resultsLimit = request.resultsLimit
            operation.zoneID = self.zone.zoneID
            
            func addModelFromRecord(_ ckRecord: CKRecord) {
                CloudKitDataProvider.model(type, from: ckRecord, completionHandler: { object, error in
                    if let object = object {
                        targetArray.append(object)
                    }
                })
            }
            
            func continueFetchIfNecessary(with cursor: CKQueryOperation.Cursor?, error: Error?) {
                guard let cursor = cursor else {
                    DispatchQueue.main.async {
                        if error != nil {
                            completionHandler(nil, error)
                        } else {
                            completionHandler(targetArray, nil)
                        }
                    }
                    return
                }
                let operation = CKQueryOperation(cursor: cursor)
                operation.qualityOfService = CloudKitDataProvider.qualityOfService
                operation.zoneID = self.zone.zoneID
                operation.recordFetchedBlock = { record in
                    addModelFromRecord(record)
                }
                operation.queryCompletionBlock = { (cursor, error) in
                    continueFetchIfNecessary(with: cursor, error: error)
                }
                self.database.add(operation)
            }
            
            operation.recordFetchedBlock = { record in
                addModelFromRecord(record)
            }
            operation.queryCompletionBlock = { (cursor, error) in
                continueFetchIfNecessary(with: cursor, error: error)
            }
            self.database.add(operation)
        }
    }
    
    public func delete<T: CloudKitDataCodable>(_ object: T, completionHandler: @escaping(Error?)->()) {
        guard let record = object.record else { return }
        CloudKitDataProvider.queue.async {
            self.database.delete(withRecordID: record.ckRecordID()) { (recordID, error) in
                DispatchQueue.main.async {
                    if error == nil {
                        CloudKitDataProvider.storeChangeInKeyValueCloud()
                    }
                    completionHandler(error)
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

public extension CloudKitDataProvider {
    static func ckRecord<T: CloudKitDataCodable>(from object: T, completionHandler: @escaping(CKRecord?,Error?)->()) {
        queue.async {
            let recordType = String(describing: type(of: object))
            var data: Data?
            do {
                let recordBackup = object.record
                data = try JSONEncoder().encode(object)
                object.record = recordBackup
                let ckRecord: CKRecord = {
                    if let record = object.record {
                        return CKRecord(recordType: recordType, recordID: record.ckRecordID())
                    }
                    return CKRecord(recordType: recordType)
                }()
                ckRecord[Keys.dataKey] = data
                ckRecord[Keys.searchKey] = object.searchableKeywords()
                completionHandler(ckRecord, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }
    
    static func model<T: CloudKitDataCodable>(_ type: T.Type, from record: CKRecord?, completionHandler:(T?, Error?)->()) {
        if let record = record, let data = record[Keys.dataKey] as? Data {
            do {
                let model = try JSONDecoder().decode(type, from: data)
                model.record = CloudKitRecord(record: record)
                completionHandler(model, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
        completionHandler(nil, nil)
    }
}

public struct CloudKitRequest {
    public let resultsLimit: Int = 50
    public let limitResultsToCurrentUser: Bool = true
    public let predicate: NSPredicate?
    
    public init(predicate: NSPredicate? = nil) {
        self.predicate = predicate
    }
}

//TODO: be able to attach assets
public class Asset {
    var data: Data? = nil
    var metadata: [String:String] = [:]
    
    var fileURL: URL
    var key: String
    
    init(key: String, fileURL: URL) {
        self.key = key
        self.fileURL = fileURL
    }
}
