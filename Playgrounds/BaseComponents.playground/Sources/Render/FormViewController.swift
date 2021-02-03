/*
 
 WIP: Do not use

import UIKit
import BaseComponents

class FormViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        largeTitle = "Form"
        
        let formRender = FormRender()
        
        let login = FormRender.Button { (button) in
            button.text("Login")
        }
        formRender.add(section: [login])
        
        let username = FormRender.TextField(title: "Username") { (textField) in
            textField.color(.background, .green)
        }
        
        let password = FormRender.TextField(title: "Password") { (textField) in
            
        }
        formRender.add(section: [username,password])
        
        let test = FormRender.TextField(title: "Test") { (textField) in
            
        }
        
        let test1 = FormRender.TextField(title: "Test X") { (textField) in
            
        }
        formRender.add(section: [test,test1])
        
        view.addSubview(formRender)
    }
}

open class FormRender: DataRender {
    fileprivate class Table: UITableView {
        override init(frame: CGRect, style: UITableView.Style) {
            var groupedStyle = UITableView.Style.grouped
            if #available(iOS 13, *) {
                groupedStyle = .insetGrouped
            }
            super.init(frame: frame, style: groupedStyle)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class BaseCell: UITableViewCell {
        let scrollingView: ScrollingView = {
            let scrollingView: ScrollingView = ScrollingView()
            scrollingView.automaticallyAdjustsLayoutMarginInsets = true
            return scrollingView
        }()
        
        public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            contentView.addSubview(scrollingView)
            
            selectionStyle = .none
            
            buildLayout()
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            separatorInset.left = layoutMargins.left
        }
        
        func buildLayout() {
        
        }
    }

    open class FormComponent {
        var configurationHandler: ((AnyObject)->())? = nil
        
        init() {
        }
    }
    
    open class TextField: FormComponent {
        init(title: String, configurationHandler: @escaping (UITextField)->()) {
            super.init()
            
            self.configurationHandler = { component in
                configurationHandler(component as! UITextField)
            }
        }
        
        class Cell: BaseCell {
            let titleLabel: UILabel = UILabel().size(.footnote, .bold)
            let textField: UITextField = UITextField()
            
            override func buildLayout() {
                scrollingView.addSubview(titleLabel)
                scrollingView.addPadding(4)
                scrollingView.addSubview(textField, layoutType: .automatic)
            }
        }
    }
    
    open class Button: FormComponent {
        init(configurationHandler: @escaping(UIButton)->()) {
            super.init()
            
            self.configurationHandler = { component in
                configurationHandler(component as! UIButton)
            }
        }
        
        class Cell: BaseCell {
            let button: UIButton = UIButton("")
            
            override func buildLayout() {
                scrollingView.addSubview(button)
                scrollingView.addSubview(UIView().color(.background, .red), layoutType: .fixed, value: 200)
            }
        }
    }
    
    fileprivate var sections: [[FormComponent]] = []
    
    init() {
        super.init(configuration: .init(cellClass: TextField.Cell.self, renderClass: Table.self))
        adjustInsets = true
        
        itemAutomaticRowHeightCacheKeyHandler { (itemLayoutProperties) -> AnyHashable in
            itemLayoutProperties.indexPath
        }
    }
    
    
    @available(*, unavailable)
    required public init(configuration: DataRenderConfiguration) {
        fatalError("init(configuration:) has not been implemented")
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func add(section items: [FormComponent]) {
        sections.append(items)
        renderArray(sections)
    }
}

class AutoDimensionRender: UIView {
    enum LayoutType {
        case list(appearance: UICollectionLayoutListConfiguration.Appearance)
        case grid(columns: Int, vertical: Bool)
    }
    
    struct Item {
        let indexPath: IndexPath
        let object: AnyObject
        let cell: Render.Cell
        let layoutPass: Bool
    }
    
    let render: Render
    var layoutType: LayoutType = .list(appearance: .plain) {
        didSet {
            render.layoutType = layoutType
            render.collectionView.reloadData()
        }
    }
    
    init(layoutType: LayoutType, layoutHandler: @escaping (Item)->(ScrollingView)) {
        self.render = Render(self.layoutType, layoutHandler: layoutHandler)
        super.init(frame: .zero)
        
        addSubview(render.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class Render: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
        class Cell: UICollectionViewCell {
            
        }
        
        let layoutHandler: (Item)->(ScrollingView)
        var layoutType: LayoutType
        var array: [AnyObject] = []
        lazy var collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            let collectionView = UICollectionView()
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            collectionView.register(Cell.self, forCellWithReuseIdentifier: "Cell")
            collectionView.scrollsToTop = true
            collectionView.isOpaque = true
            return collectionView
        }()
        lazy var cellRegistration: UICollectionView.CellRegistration<UICollectionViewCell,AnyObject> = UICollectionView.CellRegistration { (cell, indexPath, _) in
                if let cell = cell as? UICollectionViewListCell {
                    cell.accessories = [.disclosureIndicator()]
                }
            }
        
        var layout: UICollectionViewLayout {
            get {
                collectionView.collectionViewLayout
            }
        }
        let dimensionCell: Cell = Cell()
        
        init(_ layoutType: LayoutType, layoutHandler: @escaping (Item)->(ScrollingView)) {
            self.layoutType = layoutType
            self.layoutHandler = layoutHandler
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            array.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
            self.layoutHandler(.init(indexPath: indexPath, object: object(for: indexPath), cell: cell, layoutPass: false))
            return cell
        }
        
        func object(for indexPath: IndexPath) -> AnyObject {
            array[indexPath.row]
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            let scrollView = self.layoutHandler(.init(indexPath: indexPath, object: object(for: indexPath), cell: dimensionCell, layoutPass: true))
            scrollView.layoutPass = true
            scrollView.invalidateLayout()
            
                
            scrollView.layoutPass = false
            return .zero
        }
    }
 }

 */
