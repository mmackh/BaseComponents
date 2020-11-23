import UIKit
import BaseComponents

public class SplitViewController: UIViewController {
    enum Color: Int {
        case red
        case green
        case blue
    }
    
    var containerSplitView: SplitView!
    var currentColor: Color = .blue
    
    public override func viewDidLoad() {
        view.color(.background, .systemBackground)
        
        view.addSplitView { [unowned self] (splitView) in
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .top)
            
            self.containerSplitView = splitView.addSplitView(configurationHandler: { (splitView) in
                splitView.addSubview(UIView().color(.background, .red), layoutType: .equal)
                splitView.addSubview(UIView().color(.background, .green), layoutType: .equal)
                splitView.addSubview(UIView().color(.background, .blue), layoutType: .equal)
            }, layoutType: .percentage, value: 100)
            
            splitView.addSubview(UIView().color(.background, .hairline), layoutType: .fixed, value: .onePixel)
            
            splitView.addSplitView(configurationHandler: { (splitView) in
                splitView.direction = .horizontal
                
                splitView.addSubview(UIButton(symbol: "plus").addAction(for: .touchUpInside, { (button) in
                    var targetColor = currentColor.rawValue + 1
                    if (targetColor > 2) {
                        targetColor = 0
                    }
                    self.currentColor = Color(rawValue: targetColor)!
                    
                    var color: UIColor!
                    switch self.currentColor  {
                    case .red:
                        color = .red
                    case .green:
                        color = .green
                    case .blue:
                        color = .blue
                    }
                    
                    let subview = UIView().color(.background, color)
                    if let lastSubview = self.containerSplitView.subviews.last {
                        subview.frame = lastSubview.frame
                    }
                    
                    self.containerSplitView.addSubview(subview, layoutType: .equal)
                    
                    UIView.animate(withDuration: 0.4) {
                        self.containerSplitView.invalidateLayout()
                    }
                    
                }), layoutType: .equal)
                
                splitView.addSubview(UIView().color(.background, .hairline), layoutType: .fixed, value: .onePixel)
                
                splitView.addSubview(UIButton(symbol: "minus").addAction(for: .touchUpInside, { (button) in
                    
                    if let subview = self.containerSplitView.subviews.last {
                        subview.removeFromSuperview()
                    }
                    
                    UIView.animate(withDuration: 0.4) {
                        self.containerSplitView.invalidateLayout()
                    }
                    
                }), layoutType: .equal)
                
                splitView.addSubview(UIView().color(.background, .hairline), layoutType: .fixed, value: .onePixel)
                
                splitView.addSubview(UIButton(symbol: "arrow.2.squarepath").addAction(for: .touchUpInside, { (button) in
                    
                    self.containerSplitView.direction = self.containerSplitView.direction == .horizontal ? .vertical : .horizontal
                    UIView.animate(withDuration: 0.4) {
                        self.containerSplitView.invalidateLayout()
                    }
                    
                }), layoutType: .equal)
                
            }, layoutType: .fixed, value: 44)
        }
        
    }
}
