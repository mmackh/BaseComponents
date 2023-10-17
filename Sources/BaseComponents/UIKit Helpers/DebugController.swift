//
//  DebugController.swift
//  BaseComponents
//
//  Created by mmackh on 13.12.20.
//  Copyright © 2020 Maximilian Mackh. All rights reserved.

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#if os(iOS) || os(visionOS)

import UIKit

@available(iOSApplicationExtension, unavailable)
open class DebugController: UIViewController {    
    public class Store {
        fileprivate class Item {
            let name: String
            let presentationHandler: (_ coordinator: Coordinator)->()
            
            fileprivate init(name: String, presentationHandler: @escaping((_ coordinator: Coordinator)->())) {
                self.name = name
                self.presentationHandler = presentationHandler
            }
        }
        fileprivate var items: [Item] = []
        
        public static let defaultStore: Store = Store()
        
        public func register(name: String, presentationHandler: @escaping((_ coordinator: Coordinator)->())) {
            items.append(Item(name: name, presentationHandler: presentationHandler))
        }
    }
    
    public class Coordinator {
        weak var parentViewController: UIViewController?
        var animated: Bool = true
        
        init(_ parentViewController: UIViewController) {
            self.parentViewController = parentViewController
        }
        
        public func push(_ viewController: UIViewController) {
            parentViewController?.navigationController?.pushViewController(viewController, animated: animated)
            
        }
        
        public func present(_ viewController: UIViewController, completionHandler: (()->())? = nil) {
            parentViewController?.present(viewController, animated: animated, completion: completionHandler)
        }
    }
    
    let store: Store
    let render = DataRender(configuration: .init(cellClass: UITableViewCell.self))
    
    init(_ store: Store) {
        self.store = store
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.color(.background, .systemGroupedBackground)
        } else {
            #if !os(visionOS)
            view.color(.background, .groupTableViewBackground)
            #endif
        }
        
        title = "Debug"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem("Done", style: .done).addAction({ [unowned self] (item) in
            self.dismiss(animated: true, completion: nil)
        })
        
        render.adjustInsets = true
        render.beforeBind { (itemRenderProperties) in
            let cell = itemRenderProperties.cell as! UITableViewCell
            let item = itemRenderProperties.object as! Store.Item
            
            cell.textLabel?.text = item.name
            cell.accessoryType = .disclosureIndicator
        }
        render.onSelect { [unowned self] (itemRenderProperties) in
            let item = itemRenderProperties.object as! Store.Item
            item.presentationHandler(Coordinator(self))
        }
        render.renderArray(store.items)
        view.addSubview(render)
    }
    
    public static func register(name: String, presentationHandler: @escaping((_ coordinator: Coordinator)->())) {
        Store.defaultStore.register(name: name, presentationHandler: presentationHandler)
    }
    
    @discardableResult
    public static func open(viewController: UIViewController? = nil, store: Store = Store.defaultStore, completionHandler: ((DebugController)->())?) -> DebugController {
        let debugController = DebugController(store)
        let navigationController = debugController.embedInNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        currentViewController()?.present(navigationController, animated: true, completion: { [unowned debugController] in
            if let completionHandler = completionHandler {
                completionHandler(debugController)
            }
        })
        return debugController
    }
    
    public func debugRegisteredViewController(at index: Int = 0) {
        self.store.items[index].presentationHandler(Coordinator(self))
    }
    
    public static func currentViewController() -> UIViewController? {
        guard let keyWindow: UIWindow = keyWindow(), let viewController = keyWindow.rootViewController else { return nil }
        return iterateChildViewControllers(viewController)
    }
    
    public static func keyWindow() -> UIWindow? {
        #if os(visionOS)
            return UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        #else
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        } else {
            return UIApplication.shared.keyWindow
        }
        #endif
    }
    
    fileprivate static func iterateChildViewControllers(_ viewController: UIViewController) -> UIViewController {
        if let navigationController = viewController as? UINavigationController {
            return iterateChildViewControllers(navigationController.visibleViewController ?? navigationController.viewControllers.first ?? viewController)

        } else if let tabBarController = viewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return iterateChildViewControllers(selectedViewController)
            }

        } else if let presentedViewController = viewController.presentedViewController {
            return iterateChildViewControllers(presentedViewController)
        }
        return viewController
    }
}

#endif
