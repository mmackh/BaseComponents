import UIKit
import PlaygroundSupport
import BaseComponents


class MainViewController : UIViewController {
    enum Component: String, CaseIterable {
        case SplitView
        case ScrollingView
        case ConditionalLayoutView
    }
    
    lazy var render: DataRender = { [unowned self] in
        let config = DataRenderConfiguration(cellClass: UITableViewCell.self)
        let render = DataRender(configuration: config)
        render.beforeBind { (itemRenderProperties) in
            let cell = itemRenderProperties.cell as! UITableViewCell
            cell.textLabel?.text = (itemRenderProperties.object as? Component)?.rawValue
            cell.accessoryType = .disclosureIndicator
        }
        render.adjustInsets = true
        render.onSelect { (itemRenderProperties) in
            let targetVC: UIViewController!
            switch itemRenderProperties.object as! Component {
            case .SplitView:
                targetVC = SplitViewController()
            case .ScrollingView:
                targetVC = ScrollingViewController()
            case .ConditionalLayoutView:
                targetVC = ConditionalLayoutViewController()
            }
            self.navigationController?.pushViewController(targetVC, animated: true)
        }
        render.renderArray(Component.allCases)
        
        return render
    }()
    
    override func viewDidLoad() {
        title = "Base Components"
        
        DebugController.register(name: "ScrollingView Push") { (coordinator) in
            coordinator.push(ScrollingViewController())
        }
        
        DebugController.register(name: "ScrollingView Present") { (coordinator) in
            coordinator.present(ScrollingViewController())
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem("Debug").addAction({ (item) in
            
            DebugController.open(completionHandler: nil)
        })
        
        self.view.addSplitView { [unowned self] (splitView) in
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .top)
            
            splitView.addSubview(self.render, layoutType: .equal)
            
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .bottom)
            
        }
    }
}

class FormViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        largeTitle = "Form"
        
        let formRender = FormRender()
        formRender.add(section: [FormRender.TextField(title: "Full Name", placeholder: "John Appleseed")])
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
        let scrollingView: ScrollingView = ScrollingView()
        
        public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            selectionStyle = .none
            
            scrollingView.automaticallyAdjustsLayoutMarginInsets = true
            contentView.addSubview(scrollingView)
            
            buildLayout()
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        open func buildLayout() {
            
        }
    }

    open class FormComponent {
        var cellClass: BaseCell.Type {
            BaseCell.self
        }
    }
    
    open class TextField: FormComponent {
        let textField: UITextField = UITextField()
        override var cellClass: FormRender.BaseCell.Type {
            Cell.self
        }
        
        class Cell: BaseCell {
            open override func buildLayout() {
                scrollingView.addSubview(UILabel("Test"))
                scrollingView.addSubview(UILabel("Test"))
            }
            
            override func bindObject(_ obj: AnyObject) {
                
            }
        }
        
        init(title: String, placeholder: String? = nil) {
            
        }
    }
    
    fileprivate var sections: [[FormComponent]] = []
    
    init() {
        super.init(configuration: .init(cellClass: BaseCell.self, renderClass: Table.self))
        adjustInsets = true
        
        itemAutomaticRowHeightCacheKeyHandler { (itemLayoutProperties) -> AnyHashable in
            itemLayoutProperties.indexPath
        }
        
        registerCellClass(FormRender.TextField.Cell.self)
        itemCellClassHandler { (itemLayoutProperties) -> AnyClass in
            return (itemLayoutProperties.object as! FormComponent).cellClass
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


//let liveViewController = MainViewController().embedInNavigationController()
let liveViewController = FormViewController().embedInNavigationController()
liveViewController.view.frame = .init(x: 0, y: 0, width: 320, height: 480)
PlaygroundPage.current.liveView = liveViewController
