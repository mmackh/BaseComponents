import UIKit
import PlaygroundSupport
import BaseComponents

/*
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
 */

class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Advanced Layout"
        
        view.addSplitView { [unowned self] splitView in
            splitView.direction = .vertical
            
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .top)
            
            splitView.addPadding(layoutType: .equal)
            
            splitView.addSubview(UILabel("Hello from BaseComponents. \nI'm SplitView").align(.center), layoutType: .automatic, edgeInsets: .init(horizontal: self.view.layoutMargins.left))
            
            splitView.addPadding(layoutType: .equal)
        }
    }
}

class ComponentRenderViewController: UIViewController, UICollectionViewDelegate {
    class ListCell: UICollectionViewListCell {
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            accessories = [.outlineDisclosure()]
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func bindObject(_ obj: AnyObject) {
            var config = self.defaultContentConfiguration()
            config.text = obj as? String
            
            contentConfiguration = config
        }
    }
    
    lazy var componentRender: ComponentRender<String> = {
        let componentRender: ComponentRender<String> = .init(layout: .list(style: self.tableViewStyle, configuration: { config in
            
            
        }))
        componentRender.collectionView.contentInsetAdjustmentBehavior = .never
        componentRender.collectionView.delegate = self
        return componentRender
    }()
    
    lazy var tableViewStyle: UICollectionLayoutListConfiguration.Appearance = .grouped {
        didSet {
            componentRender.layoutUpdateSettings = .init(animate: true, completionHandler: nil)
            componentRender.layout = .list(style: tableViewStyle, configuration: { listConfiguration in
                
            })
        }
    }
    
    let selectedTableRowLabel: UILabel =  UILabel("Nothing Selected")
    
    var interfaceBuilderTree: InterfaceBuilder.Tree?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Component Render"
        
        view.color(.background, .systemBackground)
        
        view.addSplitView { splitView in
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .top)

            splitView.addSubview(self.componentRender) { superviewBounds in
                .init(layoutType: .equal, value: 0)
            }

            splitView.addPadding(.onePixel).color(.background, .hairline)
            
            splitView.addSplitView (configurationHandler: { splitView in
                splitView.insertLayoutMarginsPadding(form: self.view, paddingDirection: .left)
                
                splitView.addSubview(UILabel("LABEL"), layoutType: .equal)
                
            }, layoutType: .fixed, value: 44)
        }
        
//        interfaceBuilderTree = view.build { [unowned self] in
//                VSplit {
//
//                    Padding(observe: self.view, .safeAreaInsets(direction: .top))
//
//                    Separator()
//
//                    Equal {
//                        self.componentRender
//                    }
//
//                    Separator()
//
//                    HSplit {
//                        Padding(observe: self.view, .layoutMargins(direction: .left))
//
//                        Fixed(20) {
//                            UIImageView(symbol: "chevron.right", pointSize: 20).mode(.center)
//                        }
//
//                        Padding(10)
//
//                        Equal {
//                            self.selectedTableRowLabel
//                        }
//
//                        //Padding(observe: self.view, .layoutMargins, .right)
//                    } size: {
//                        .init(.fixed, 44)
//                    }
//                }
//        }
        
        componentRender.updateSnapshot { builder in
            builder.animated = false
            builder.appendSection(using: ListCell.self, items: ["Cat", "Horse", "Donkey", "Dog", "Tiger"])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        self.selectedTableRowLabel.text = "Selected: \(componentRender.item(for: indexPath) ?? "Nothing")"
        
        tableViewStyle = tableViewStyle == .grouped ? .sidebar : .grouped
        print("switching styles")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(self.view.layoutMargins)
        //interfaceBuilderTree?.invalidateLayout()
    }
}


// let liveViewController = ScrollingViewController().embedInNavigationController()
let liveViewController = ComponentRenderViewController().embedInNavigationController()
liveViewController.view.frame = .init(x: 0, y: 0, width: 320, height: 480)
PlaygroundPage.current.liveView = liveViewController
