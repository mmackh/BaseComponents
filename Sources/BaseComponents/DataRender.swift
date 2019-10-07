//
//  DataRender.swift
//  BaseComponents
//
//  Created by mmackh on 04.10.19.
//  Copyright © 2019 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

public enum DataRenderMode: Int {
    case collection
    case table
}

public enum DataRenderScrollDirection: Int {
    case vertical
    case horizontal
}

public enum DataRenderType: Int {
    case cell
    case header
    case footer
}

extension UITableViewCell {
    
    @objc func bindObject(_ obj: AnyObject) {
        
    }
}

extension UICollectionViewCell {
    
    @objc func bindObject(_ obj: AnyObject) {
        
    }
}

/// Configuration requires either a subclass of UITableViewCell or UICollectionViewCell to be passed in as cellClass
public struct DataRenderConfiguration {
    
    /// Subclass either UITableViewCell or UICollectionView and implement bindObject
    let cellClass: AnyClass
    
    /// Render class can be either a subclass of UITableView or UICollectionView
    var renderClass: AnyClass?
    
    /// Reverses scrolling direction. Array rendering is inverted and DataRender will now scroll from bottom to top first
    public var reverseScollingDirection: Bool? = false
    
    /// Only applies to UICollectionView
    public var scrollDirection: DataRenderScrollDirection? = .vertical
}

struct DataRenderItemLayoutProperties {
    var indexPath: IndexPath?
    var renderBounds: CGRect = CGRect.zero
    var insets: UIEdgeInsets = UIEdgeInsets.zero
    var spacing: CGFloat = 0
    weak var render: DataRender?
}

struct DataRenderItemRenderProperties {
    var indexPath: IndexPath
    weak var cell: UIView?
    weak var object: AnyObject! = nil
    weak var render: DataRender?
}

class DataRender: UIView {
    fileprivate var array: Array<AnyObject> = []
    fileprivate var arrayBackup: Array<AnyObject> = []
    
    fileprivate var renderMultiDimensionalArray = false
    
    fileprivate var tableView: UITableView? = nil
    fileprivate var collectionView: UICollectionView? = nil
    
    fileprivate let edgeInsets = UIEdgeInsets.zero
    
    fileprivate var configuration: DataRenderConfiguration! = nil
    
    public private(set) var mode: DataRenderMode = .table
    
    // Common closures
    
    private var itemSizeHandler: ((DataRenderItemLayoutProperties) -> CGSize)?
    public func itemSizeHandler(_ itemSizeHandler: @escaping (DataRenderItemLayoutProperties) -> CGSize) {
        self.itemSizeHandler = itemSizeHandler
    }
    
    private var beforeBind: ((DataRenderItemRenderProperties) -> Void)?
    public func beforeBind(_ beforeBind: @escaping (DataRenderItemRenderProperties) -> Void) {
        self.beforeBind = beforeBind
    }
    
    private var beforeDisplay: ((DataRenderItemRenderProperties) -> Void)?
    public func beforeDisplay(_ beforeDisplay: @escaping (DataRenderItemRenderProperties) -> Void) {
        self.beforeDisplay = beforeDisplay
    }
    
    private var onSelect: ((DataRenderItemRenderProperties) -> Void)?
    public func onSelect(_ onSelect: @escaping (DataRenderItemRenderProperties) -> Void) {
        self.onSelect = onSelect
    }
    
    lazy public var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    private var onRefresh: ((_ dataRender: DataRender) -> Void)? {
        didSet {
            if mode == .table {
                tableView?.insertSubview(refreshControl, at: 0)
            } else {
                collectionView?.insertSubview(refreshControl, at: 0)
            }
        }
    }
    public var refreshing: Bool = false {
        didSet {
            if (refreshing) {
                refreshControl.beginRefreshing()
                refreshControl.sendActions(for: .valueChanged)
                if (mode == .table) {
                    tableView?.setContentOffset(CGPoint(x: 0, y: -refreshControl.bounds.size.height), animated: true)
                }
            } else if (refreshControl.isRefreshing) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.refreshControl.endRefreshing()
                    if (self.mode == .table) {
                        self.tableView?.setContentOffset(CGPoint.zero, animated: true)
                    }
                }
            }
            
            
        }
    }
    public func onRefresh(_ onRefresh: @escaping ((_ dataRender: DataRender) -> Void)) {
        self.onRefresh = onRefresh
    }
    @objc private func refresh(_refreshControl: UIRefreshControl) {
        if let onRefresh = onRefresh {
            weak var dataRender = self
            onRefresh(dataRender!)
        }
    }
    
    // Common customisations
    public var shouldPersistObjectSelections = false
    
    override var backgroundColor: UIColor? {
        didSet {
            tableView?.backgroundColor = backgroundColor
            collectionView?.backgroundColor = backgroundColor
        }
    }
    
    public var insets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            tableView?.contentInset = insets
            tableView?.scrollIndicatorInsets = insets
            
            if let collectionView = collectionView {
                let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
                flowLayout.sectionInset = insets
            }
        }
    }
    
    // UITableView specific customisations
    public var rowHeight: CGFloat = 44.0 {
        didSet {
            tableView?.rowHeight = rowHeight
        }
    }
    
    public var separatorColor: UIColor? = nil {
        didSet {
            tableView?.separatorColor = separatorColor
        }
    }
    
    // UICollectionView specific customisations
    public var itemSpacing: CGFloat = 5.0 {
        didSet {
            collectionView?.invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: -
    // MARK: Init
    
    /// Designated initialiser, pass in superview und DataRenderConfiguration
    required init(configuration: DataRenderConfiguration) {
        
        super.init(frame: CGRect.zero)
        
        self.configuration = configuration
        
        mode = configuration.cellClass.isSubclass(of: UITableViewCell.self) ? .table : .collection
        
        let renderClass: AnyClass = (configuration.renderClass == nil) ? (mode == .table ? UITableView.self : UICollectionView.self) : configuration.renderClass!
        
        backgroundColor = .clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if mode == .table {
            let targetClass = renderClass as! UITableView.Type
            tableView = {
                let tableView = targetClass.init(frame: bounds, style: .plain)
                tableView.autoresizingMask = autoresizingMask
                tableView.dataSource = self
                tableView.delegate = self
                tableView.rowHeight = rowHeight
                tableView.register(configuration.cellClass, forCellReuseIdentifier: NSStringFromClass(configuration.cellClass))
                tableView.rowHeight = rowHeight
                tableView.scrollsToTop = true
                tableView.contentInset = insets
                tableView.scrollIndicatorInsets = insets
                tableView.delaysContentTouches = false
                if #available(iOS 11, *) {
                    tableView.contentInsetAdjustmentBehavior = .never
                }
                if (configuration.reverseScollingDirection!) {
                    tableView.transform = CGAffineTransform(scaleX: 1, y: -1);
                }
                addSubview(tableView)
                return tableView
            }()
            
        }
        
        if mode == .collection {
            let targetClass = renderClass as! UICollectionView.Type
            collectionView = {
                let collectionView = targetClass.init(frame: bounds, collectionViewLayout: collectionViewLayout(sectionInset: insets, scrollDirection: configuration.scrollDirection!))
                collectionView.autoresizingMask = autoresizingMask
                collectionView.dataSource = self
                collectionView.delegate = self
                collectionView.register(configuration.cellClass, forCellWithReuseIdentifier: NSStringFromClass(configuration.cellClass))
                collectionView.delaysContentTouches = false
                collectionView.scrollsToTop = true
                collectionView.isOpaque = true
                collectionView.alwaysBounceVertical = configuration.scrollDirection == .vertical
                collectionView.alwaysBounceHorizontal = configuration.scrollDirection == .horizontal
                if #available(iOS 11, *) {
                    collectionView.contentInsetAdjustmentBehavior = .never
                }
                if (configuration.reverseScollingDirection!) {
                    collectionView.transform = CGAffineTransform(scaleX: -1, y: -1);
                }
                addSubview(collectionView)
                return collectionView
            }()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        frame = newSuperview?.bounds ?? CGRect.zero
    }
    
    
    // MARK: -
    // MARK: Public common methods
    
    public func renderArray(_ array: Array<AnyObject>) {
        
        renderMultiDimensionalArray = false
        if let item: AnyObject = array.first {
            if (item is Array<Any> || item is NSArray)
            {
                renderMultiDimensionalArray = true
            }
        }
        
        if (configuration.reverseScollingDirection!) {
            if (renderMultiDimensionalArray) {
                var tempArray: Array<Array> = [] as! Array<Array<Any>>
                for subArray in array.reversed() {
                    let subArrayCast = subArray as! Array<AnyObject>
                    tempArray.append(subArrayCast.reversed() as Array)
                }
                self.array = tempArray as Array<AnyObject>
                self.arrayBackup = tempArray as Array<AnyObject>
            } else { 
                self.array = array.reversed()
                self.arrayBackup = array.reversed()
            }
        } else {
            self.array = array
            self.arrayBackup = array
        }
        
        
        reloadData()
    }
    
    public func reloadData() {
        tableView?.reloadData()
        collectionView?.reloadData()
    }
    
    public static func size(forEqualNumberOfColumns columns: Int, rows: Int, itemLayoutProperties: DataRenderItemLayoutProperties) -> CGSize
    {
        let fColumns = CGFloat(columns)
        let fRows = CGFloat(rows)
        
        let horizontalReduction = (itemLayoutProperties.spacing * (fColumns - 1.0)) + itemLayoutProperties.insets.left + itemLayoutProperties.insets.right
        let verticalReduction = (itemLayoutProperties.spacing * (fRows - 1.0)) + itemLayoutProperties.insets.top + itemLayoutProperties.insets.bottom
        
        var updatedRenderBounds = itemLayoutProperties.renderBounds
        updatedRenderBounds.size.width -= horizontalReduction
        updatedRenderBounds.size.height -= verticalReduction
        return CGSize(width: updatedRenderBounds.size.width/fColumns, height: updatedRenderBounds.size.height/fRows)
    }
    
    /// Optionally register additional cellClasses that can be retured via the classForCell closure
    public func registerCellClass(_ cellClass: AnyClass) {
        tableView?.register(cellClass, forCellReuseIdentifier: NSStringFromClass(cellClass))
    }
    
    // MARK: -
    // MARK: Private common methods
    
    
    
}

extension DataRender: UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    override func layoutSubviews() {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func objectForIndexPath(_ indexPath: IndexPath) -> AnyObject {
        var object: AnyObject! = nil
        if (renderMultiDimensionalArray) {
            object = array[indexPath.section][indexPath.row]
        } else {
            object = array[indexPath.row]
        }
        return object
    }
    
    // MARK: -
    // MARK: Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return renderMultiDimensionalArray ? array.count : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (renderMultiDimensionalArray) {
            return array[section].count
        }
        return array.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let itemSizeHandler = itemSizeHandler {
            weak var render = self
            return itemSizeHandler(DataRenderItemLayoutProperties(indexPath: indexPath,renderBounds: tableView.bounds,insets: tableView.contentInset,spacing: 0.0,render: render)).height
        }
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let beforeDisplay = beforeDisplay {
            weak var render = self
            beforeDisplay(DataRenderItemRenderProperties(indexPath: indexPath, cell: cell, object: objectForIndexPath(indexPath), render: render))
        }
        
        if (configuration.reverseScollingDirection!)
        {
            cell.contentView.transform = tableView.transform
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(configuration.cellClass), for: indexPath)
        let object = objectForIndexPath(indexPath)
        if let beforeBind = beforeBind {
            weak var render = self
            beforeBind(DataRenderItemRenderProperties(indexPath: indexPath, cell: cell, object: object, render: render))
        }
        cell.bindObject(object)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (!shouldPersistObjectSelections) {
            tableView.deselectRow(at: indexPath, animated: false)
        }
        
        if let onSelect = onSelect {
            let cell = tableView.cellForRow(at: indexPath)
            let object = objectForIndexPath(indexPath)
            weak var render = self
            onSelect(DataRenderItemRenderProperties(indexPath: indexPath, cell: cell, object: object, render: render))
        }
    }
    
    // MARK: -
    // MARK: Collection View
    
    func collectionViewLayout(sectionInset: UIEdgeInsets, scrollDirection: DataRenderScrollDirection) -> UICollectionViewLayout {

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInset
        layout.scrollDirection = (scrollDirection == DataRenderScrollDirection.vertical) ? .vertical : .horizontal
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        return layout
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return renderMultiDimensionalArray ? array.count : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (renderMultiDimensionalArray) {
            return array[section].count
        }
        return array.count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let beforeDisplay = beforeDisplay {
            weak var render = self
            beforeDisplay(DataRenderItemRenderProperties(indexPath: indexPath, cell: cell, object: objectForIndexPath(indexPath), render: render))
        }
        
        if (configuration.reverseScollingDirection!)
        {
            cell.contentView.transform = collectionView.transform
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(configuration.cellClass), for: indexPath)
        let object = objectForIndexPath(indexPath)
        if let beforeBind = beforeBind {
            weak var render = self
            beforeBind(DataRenderItemRenderProperties(indexPath: indexPath, cell: cell, object: object, render: render))
        }
        cell.bindObject(object)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let itemSizeHandler = itemSizeHandler {
            weak var render = self
            let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
            return itemSizeHandler(DataRenderItemLayoutProperties(indexPath: indexPath,renderBounds: collectionView.bounds,insets: flowLayout.sectionInset,spacing: flowLayout.minimumLineSpacing, render: render))
        }
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!shouldPersistObjectSelections) {
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        
        if let onSelect = onSelect {
            let cell = collectionView.cellForItem(at: indexPath)
            let object = objectForIndexPath(indexPath)
            weak var render = self
            onSelect(DataRenderItemRenderProperties(indexPath: indexPath, cell: cell, object: object, render: render))
        }
    }
}
