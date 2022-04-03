//
//  ComponentRender.swift
//  BaseComponents
//
//  Created by mmackh on 03.06.21.
//  Copyright © 2021 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#if os(iOS)

import UIKit
import Foundation

@available(iOS 14, *)
open class ComponentRender<ItemIdentifierType>: UIView where ItemIdentifierType: Hashable {
    private var registrations: Set<String> = []
    private var sections: Dictionary<Int, String> = [:]
    
    private var snapshot: NSDiffableDataSourceSnapshot<Int, ItemIdentifierType>?
    
    public enum Layout {
        case list(style: UICollectionLayoutListConfiguration.Appearance, configuration: ((_ listConfiguration: inout UICollectionLayoutListConfiguration)->())? = nil)
        case compositional(builder: ()->(UICollectionViewLayout))
    }
    
    public class SnapshotBuilder {
        fileprivate var sections: [Section] = []
        
        public var animated: Bool = false
        public var completionHandler: (()->())? = nil
        
        init() { }
        
        public func appendSection(using cellClass: UICollectionViewCell.Type, items: [ItemIdentifierType]) {
            sections.append(Section(cellClass, items: items))
        }
    }
    
    public struct LayoutUpdateSettings {
        public let animate: Bool
        public let completionHandler: ((Bool)->())?
        
        public init(animate: Bool, completionHandler: ((Bool)->())?) {
            self.animate = animate
            self.completionHandler = completionHandler
        }
    }
    
    fileprivate class Section: NSObject {
        let cellClass: UICollectionViewCell.Type
        let items: [ItemIdentifierType]
        
        public init(_ cellClass: UICollectionViewCell.Type, items: [ItemIdentifierType]) {
            self.cellClass = cellClass
            self.items = items
        }
        
        public override var hash: Int {
            NSStringFromClass(cellClass).hash
        }
    }
    public var layoutUpdateSettings: LayoutUpdateSettings = .init(animate: false, completionHandler: nil)
    public var layout: Layout {
        didSet {
            self.collectionView.setCollectionViewLayout(self.collectionViewLayout, animated: layoutUpdateSettings.animate) { [weak self] Bool in
                self?.layoutUpdateSettings.completionHandler?(Bool)
            }
        }
    }
    
    public lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: self.collectionViewLayout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return collectionView
    }()
    
    public var collectionViewLayout: UICollectionViewLayout {
        switch layout {
        case .list(let appearance, let configurationHandler):
            var configuration: UICollectionLayoutListConfiguration = .init(appearance: appearance)
            configurationHandler?(&configuration)
            return UICollectionViewCompositionalLayout.list(using: configuration)
        case .compositional(let builder):
            return builder()
        }
    }
    
    public lazy var dataSource = UICollectionViewDiffableDataSource<Int, ItemIdentifierType>(collectionView: collectionView) { [unowned self] collectionView, indexPath, object in
    
        let cell: UICollectionViewCell = {
            if let reuseIdentifier = sections[indexPath.section] {
                return collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: "", for: indexPath)
        }()
        
        cell.bindObject(object as AnyObject)
        
        return cell
    }
    
    @available(*, unavailable)
    public init() {
        self.layout = .list(style: .plain)
        
        super.init(frame: .zero)
    }
    
    @available(*, unavailable)
    public override init(frame: CGRect) {
        self.layout = .list(style: .plain)
        
        super.init(frame: frame)
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(layout: Layout) {
        self.layout = layout
        
        super.init(frame: .zero)
        
        addSubview(collectionView)
    }
    
    private func register(_ section: Section, idx: Int) {
        let reuseIdentifier = NSStringFromClass(section.cellClass)
        
        sections[idx] = reuseIdentifier
        
        if registrations.contains(reuseIdentifier) {
            return
        }
        
        collectionView.register(section.cellClass, forCellWithReuseIdentifier: reuseIdentifier)
        registrations.insert(reuseIdentifier)
    }
    
    public func updateSnapshot(_ builder: (_ builder: SnapshotBuilder)->(), animated: Bool = false, completionHandler: (()->())? = nil) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ItemIdentifierType>()
        
        sections.removeAll()
        
        let snapshotBuilder: SnapshotBuilder = .init()
        builder(snapshotBuilder)
        
        for (idx, section) in snapshotBuilder.sections.enumerated() {
            register(section, idx: idx)
            snapshot.appendSections([idx])
            snapshot.appendItems(section.items)
        }
        
        self.snapshot = snapshot
        
        self.dataSource.apply(snapshot, animatingDifferences: snapshotBuilder.animated) {
            if let completionHandler = snapshotBuilder.completionHandler {
                completionHandler()
            }
        }
    }
    
    public func item(for indexPath: IndexPath) -> ItemIdentifierType? {
        dataSource.itemIdentifier(for: indexPath)
    }
    
    public func reloadData() {
        collectionView.reloadData()
    }
}

#endif
