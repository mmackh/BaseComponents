# BaseComponents

## Introduction

BaseComponents aims to provide easily reusable and understandable components to increase productivity with UIKit. Formerly written in Objective-C and used extensivly in production, the time has come to transition to Swift.

**Important Note: API for Components is currently unstable.**

### Components Roadmap
- [x] DataRender
- [x] SplitView
- [ ] KeyboardManager
- [ ] ActionSheet
- [ ] ProgressIndicator
- [ ] ControlClosures

## Documentation

Documentation on the components is currently severly lacking. I'm working on improving it over time and pull requests are always welcome.

## Components

### DataRender

DataRender abstracts all the tedious protocols one would need to implement when dealing with UICollectionView or UITableView. You decide whether to render a cell using a table or a grid, simply by choosing the appropriate superclass.

```
import UIKit

class Cell: UITableViewCell {
    override func bindObject(_ obj: AnyObject) {
        textLabel?.text = obj as? String
        detailTextLabel?.text = "Subtitle"
    }
}

class ViewController: UIViewController {
    
    lazy var dataRender: DataRender = {
        let configuration = DataRenderConfiguration(cellClass: Cell.self)
        let dataRender = DataRender(configuration: configuration)
        dataRender.rowHeight = 54
        view.addSubview(dataRender)
        return dataRender
    }()
    
    override func viewDidLoad() {
        title = "Data Render"
        
        let array = [["Hello","World"],["Swift 5.1"]]
        dataRender.renderArray(array as Array<AnyObject>)
        dataRender.onRefresh { (DataRender) in
            DataRender.refreshing = false
        }
        dataRender.onSelect { (DataRenderItemRenderProperties) in
            print("Selected:", DataRenderItemRenderProperties.object as! String)
        }
    }
    
    override func viewDidLayoutSubviews() {
        if #available(iOS 11.0, *) {
            var insets = view.safeAreaInsets
            insets.left = 0
            insets.right = 0
            dataRender.insets = insets
        } else {
            // Fallback on earlier versions
        }
    }
}
```

### SplitView

AutoLayout is slow and tedious. UIStackedView is IDK. I've never used it. I've been writing all my layout in code since before it was released. SplitView is fast. You determine the direction and size of a view, either in % or px and SplitView will arrange everything else. Putting the sample code from below into a ViewController will allow you to observe SplitView's behaviour when switching between a vertical and horizontal layout, as well as when adding and removing views.

```
import UIKit

class ViewController: UIViewController {
    private var showHorizontal = true

    private lazy var label: UILabel = {
        var label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.black
        label.textAlignment = .center
        label.text = "Subview Counter"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        weak var weakSelf = self

        SplitView(superview: view) { splitView in

            splitView.direction = .vertical

            let containerSplit = SplitView(superview: splitView) { splitView in

                splitView.direction = .vertical
                splitView.clipsToBounds = true

                splitView.addSubview(weakSelf!.label, layoutType: .automatic)
            }
            splitView.addSubview(containerSplit) { (_) -> SplitViewLayoutInstruction in

                let suggestedEdgeInsets = SplitView.suggestedSuperviewInsets()

                return SplitViewLayoutInstruction(value: 100, layoutType: .percentage, edgeInsets: suggestedEdgeInsets)
            }

            let tapGesture = UITapGestureRecognizer(target: weakSelf, action: #selector(animateRootSplit))
            tapGesture.numberOfTapsRequired = 2
            containerSplit.addGestureRecognizer(tapGesture)

            let longPress = UILongPressGestureRecognizer(target: weakSelf, action: #selector(removeFromSplit(longPress:)))
            containerSplit.addGestureRecognizer(longPress)
        }
    }

    @objc
    func animateRootSplit(gesture: UITapGestureRecognizer) {
        let splitView = gesture.view as! SplitView

        showHorizontal = !showHorizontal
        splitView.direction = showHorizontal ? .horizontal : .vertical

        let targetColor = showHorizontal ? UIColor.cyan : UIColor.magenta
        let view = UIView()
        view.backgroundColor = targetColor
        let targetFrame = splitView.subviews.last?.frame ?? CGRect.zero
        view.frame = targetFrame.offsetBy(dx: 0, dy: targetFrame.height)
        splitView.addSubview(view, layoutType: .equal)
        
        updateLabel(splitView: splitView)

        UIView.animate(withDuration: 0.3) {
            splitView.invalidateLayout()
        }
    }

    @objc
    func removeFromSplit(longPress: UILongPressGestureRecognizer) {
        if longPress.state != .recognized {
            return
        }

        let splitView = longPress.view as! SplitView

        if splitView.subviews.count == 1 {
            return
        }

        splitView.subviews.last?.removeFromSuperview()

        updateLabel(splitView: splitView)

        UIView.animate(withDuration: 0.3) {
            splitView.invalidateLayout()
        }
    }

    func updateLabel(splitView: SplitView) {
        label.text = String(format: "%i Subviews", splitView.subviews.count)
    }
}
```
