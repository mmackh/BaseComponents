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

#if os(iOS)

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

public class CloudKitAsset: Codable {
    var metadata: [String:String] = [:]
    var fileURL: URL
    var record: CloudKitRecord?
    
    init(fileURL: URL, metadata: [String:String]) {
        self.fileURL = fileURL
        self.metadata = metadata
    }
}

open class CloudKitRecord: Codable {
    public let id: String
    public let changeTag: String
    public let creationDate: Date?
    public let modificationDate: Date?
    public let zoneName: String
    public let zoneOwnerName: String
    public let ckRecordBackingData: Data?
   
    init(record: CKRecord) {
        self.id = record.recordID.recordName
        self.changeTag = record.recordChangeTag ?? ""
        self.creationDate = record.creationDate
        self.modificationDate = record.modificationDate
        
        self.zoneName = record.recordID.zoneID.zoneName
        self.zoneOwnerName = record.recordID.zoneID.ownerName
        
        do {
            self.ckRecordBackingData = try NSKeyedArchiver.archivedData(withRootObject: record, requiringSecureCoding: false)
        } catch {
            self.ckRecordBackingData = nil
        }
    }
    
    func ckRecord() -> CKRecord? {
        do {
            if let ckRecordBackingData = ckRecordBackingData {
                return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(ckRecordBackingData) as? CKRecord
            }
        } catch { }
        return nil
    }
    
    func ckRecordID() -> CKRecord.ID {
        return CKRecord.ID(recordName: id, zoneID: .init(zoneName: zoneName, ownerName: zoneOwnerName))
    }
}

open class CloudKitDataProvider: NSObject {
    public enum ShouldUpdateReason {
        case triggeredByKeyValueStoreChange
        case triggeredExternally
    }
    
    private class Keys {
        static let dataKey = "data"
        static let searchKey = "search"
        
        static let metadataKey = "metadata"
        static let assetKey = "asset"
        static let parentKey = "parent"
    }
    
    public static let queue = DispatchQueue.init(label: "at.BaseComponents.CloudKitData.Async")
    public static var qualityOfService: QualityOfService = .userInteractive
    
    public var container: CKContainer
    public var databaseScope: CKDatabase.Scope
    public var database: CKDatabase {
        get {
            return self.container.database(with: databaseScope)
        }
    }
    public var zone: CKRecordZone
    public var userID: CKRecord.ID?
    
    private static var dateWrittenToKeyValueStore: Date = Date()
    public static var enabledKeyValueStoreUpdateTrigger: Bool = true
    public var onShouldUpdate: ((_ reason: ShouldUpdateReason)->())? = nil
    
    public init(_ databaseScope: CKDatabase.Scope, zone: CKRecordZone = .default(), container: CKContainer = CKContainer.default()) {
        self.databaseScope = databaseScope
        self.zone = zone
        self.container = container
        super.init()
        
        if CloudKitDataProvider.enabledKeyValueStoreUpdateTrigger {
            observe(NSUbiquitousKeyValueStore.didChangeExternallyNotification, NSUbiquitousKeyValueStore.default) { [weak self] (notification) in
                let keyValueStore = NSUbiquitousKeyValueStore.default
                if let storedDate = keyValueStore.object(forKey: "sync") as? Date {
                    if storedDate <= CloudKitDataProvider.dateWrittenToKeyValueStore { return }
                }
                
                self?.triggerOnShouldUpdateHandler(with: .triggeredByKeyValueStoreChange)
            }
        }
    }
    
    static func storeChangeInKeyValueCloud() {
        if !CloudKitDataProvider.enabledKeyValueStoreUpdateTrigger { return }
        
        dateWrittenToKeyValueStore = Date()
        
        DispatchQueue.main.async {
            let keyValueStore = NSUbiquitousKeyValueStore.default
            keyValueStore.set(dateWrittenToKeyValueStore, forKey: "sync")
            keyValueStore.synchronize()
        }
    }
    
    public func triggerOnShouldUpdateHandler(with reason: ShouldUpdateReason) {
        if let onShouldUpdate = onShouldUpdate {
            DispatchQueue.main.async {
                onShouldUpdate(reason)
            }
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
        
        let operation: CKFetchRecordZoneChangesOperation = {
            if #available(iOS 12.0, *) {
                let defaultZoneOptions = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
                defaultZoneOptions.previousServerChangeToken = getToken()
                
                return CKFetchRecordZoneChangesOperation(recordZoneIDs: [zone.zoneID], configurationsByRecordZoneID: [zone.zoneID: defaultZoneOptions])
            } else {
                let defaultZoneOptions = CKFetchRecordZoneChangesOperation.ZoneOptions()
                defaultZoneOptions.previousServerChangeToken = getToken()
                
                return CKFetchRecordZoneChangesOperation(recordZoneIDs: [zone.zoneID], optionsByRecordZoneID: [zone.zoneID:defaultZoneOptions])
            }
        }()
        
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
        
        CloudKitDataProvider.ckRecord(from: object) { (ckRecord, error) in
            guard let ckRecord = ckRecord else {
                respond(nil, error)
                return
            }
            
            if object.record != nil {
                let modifyOperation = CKModifyRecordsOperation()
                modifyOperation.recordsToSave = [ckRecord]
                modifyOperation.savePolicy = .ifServerRecordUnchanged
                modifyOperation.qualityOfService = CloudKitDataProvider.qualityOfService
                modifyOperation.perRecordCompletionBlock = { ckRecord, error in
                    respond(ckRecord, error)
                }
                self.database.add(modifyOperation)
                return
            }
            
            self.database.save(ckRecord) { (ckRecord, error) in
                respond(ckRecord, nil)
            }
        }
    }
    
    public func fetch<T: CloudKitDataCodable>(_ type: T.Type, with request: Request = .init(), completionHandler: @escaping([T]?,Error?) -> ()) {
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
            query.sortDescriptors = request.sortDescriptors
            
            let operation = CKQueryOperation(query: query)
            operation.qualityOfService = CloudKitDataProvider.qualityOfService
            operation.resultsLimit = request.resultsLimit
            operation.zoneID = self.zone.zoneID
            operation.recordFetchedBlock = { record in
                addModelFromRecord(record)
            }
            operation.queryCompletionBlock = { (cursor, error) in
                continueFetchIfNecessary(with: cursor, error: error)
            }
            self.database.add(operation)
            
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

    public struct Request {
        public var resultsLimit: Int = 50
        public var limitResultsToCurrentUser: Bool = true
        public var predicate: NSPredicate?
        public var sortDescriptors: [NSSortDescriptor] = [.init(key: "modificationDate", ascending: false)]
        
        public init(predicate: NSPredicate? = nil) {
            self.predicate = predicate
        }
    }
}

/**
 Manage assets for `CloudKitCodable` objects
 */
public extension CloudKitDataProvider {
    func add<T: CloudKitDataCodable>(asset: CloudKitAsset, to object: T, action: CKRecord_Reference_Action = .deleteSelf,completionHandler: @escaping(CloudKitAsset?, Error?)->()) {
        func signal(_ asset: CloudKitAsset?,_ error: Error?) {
            DispatchQueue.main.async {
                completionHandler(asset, error)
            }
        }
        
        CloudKitDataProvider.queue.async {
            if let parentRecord = object.record?.ckRecordID() {
                let ckRecord = CKRecord(recordType: String(describing: CloudKitAsset.self))
                do {
                    try ckRecord[Keys.dataKey] = NSKeyedArchiver.archivedData(withRootObject: asset.metadata, requiringSecureCoding: false)
                } catch {
                    signal(nil, error)
                    return
                }
                ckRecord[Keys.parentKey] = CKRecord.Reference(recordID: parentRecord, action: action)
                ckRecord[Keys.assetKey] = CKAsset(fileURL: asset.fileURL)
                
                self.database.save(ckRecord) { (savedCKRecord, error) in
                    if error != nil || savedCKRecord == nil {
                        signal(nil, error)
                        return
                    }
                    guard let savedCKRecord = savedCKRecord else { return }
                    asset.record = CloudKitRecord(record: savedCKRecord)
                    signal(asset, error)
                }
            }
        }
    }
    
    func getAssets<T: CloudKitDataCodable>(for object: T, completionHandler: @escaping([CloudKitAsset]?, Error?)->()) {
        CloudKitDataProvider.queue.async {
            guard let recordName = object.record?.ckRecordID().recordName else { return }
            
            let predicate = NSPredicate(format: "%@ = %@",Keys.parentKey, recordName)
            let query = CKQuery(recordType: String(describing: CloudKitAsset.self), predicate: predicate)
            query.sortDescriptors = [.init(key: "modifiedDate", ascending: false)]
            
            var targetArray: [CloudKitAsset] = []
            
            let operation = CKQueryOperation(query: query)
            operation.qualityOfService = CloudKitDataProvider.qualityOfService
            operation.resultsLimit = 50
            operation.zoneID = self.zone.zoneID
            operation.recordFetchedBlock = { record in
                addAssetFromRecord(record)
            }
            operation.queryCompletionBlock = { (cursor, error) in
                continueFetchIfNecessary(with: cursor, error: error)
            }
            self.database.add(operation)
            
            func addAssetFromRecord(_ ckRecord: CKRecord) {
                if let ckAsset = ckRecord[Keys.assetKey] as? CKAsset, let fileURL = ckAsset.fileURL, let metadataData = ckRecord[Keys.metadataKey] as? Data {
                    do {
                        guard let metadata = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(metadataData) as? [String:String] else { return }
                        let asset = CloudKitAsset(fileURL: fileURL, metadata: metadata)
                        asset.record = CloudKitRecord(record: ckRecord)
                        targetArray.append(asset)
                    } catch {
                        
                    }
                }
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
                    addAssetFromRecord(record)
                }
                operation.queryCompletionBlock = { (cursor, error) in
                    continueFetchIfNecessary(with: cursor, error: error)
                }
                self.database.add(operation)
            }
        }
    }
    
    func removeAsset<T: CloudKitDataCodable>(_ asset: CloudKitAsset, from object: T, completionHandler: @escaping(Error?)->()) {
        guard let record = asset.record else { return }
        CloudKitDataProvider.queue.async {
            self.database.delete(withRecordID: record.ckRecordID()) { (recordID, error) in
                DispatchQueue.main.async {
                    if error == nil {
                        
                    }
                    completionHandler(error)
                }
            }
        }
    }
    
    static func storeAssetChangeInKeyValueCloud<T: CloudKitDataCodable>(for object: T) {
        if !CloudKitDataProvider.enabledKeyValueStoreUpdateTrigger { return }
        
        guard let record = object.record else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let keyValueStore = NSUbiquitousKeyValueStore.default
            keyValueStore.set(Date(), forKey: record.id)
            keyValueStore.synchronize()
        }
    }
    
}

/**
 Extension to handle the conversions between `CloudKitCodable` and `CKRecord`
 */
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
                    if let ckRecord = object.record?.ckRecord() {
                        return ckRecord
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

#endif
