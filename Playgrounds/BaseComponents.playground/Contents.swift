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

//let liveViewController = MainViewController().embedInNavigationController()
let liveViewController = ScrollingViewController()
liveViewController.view.frame = .init(x: 0, y: 0, width: 320, height: 480)


PlaygroundPage.current.liveView = liveViewController
