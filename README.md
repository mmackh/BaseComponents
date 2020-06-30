# BaseComponents

## Introduction

BaseComponents aims to provide easily reusable and understandable components to increase productivity with UIKit. Formerly written in Objective-C and used extensivly in production, the time has come to transition to Swift.

Current Version: 0.8

**Important Note: API for Components is currently unstable.**

### Components Roadmap

#### Layout
- [x] ConditionalLayoutView
- [x] ScrollingView
- [x] SplitView

#### Storage
- [x] DiskData
- [x] CloudKitData

#### Networking
- [x] NetFetch

#### UIKit Helpers
- [x] ControlClosures
- [x] Conveniences
- [x] DataRender
- [x] KeyboardManager

#### UIKit Reimplementations
- [x] PerformLabel

#### UI Components
- [x] CountdownPickerView
- [x] NotificationView
- [x] ProgressView
- [x] SheetView

## Reasoning

1) BaseComponents allows you to write efficient & understandable code in a short amount of time by abstracting the tedious stuff. Implementing data sources or delegates takes a lot of boilerplate and often there's no need. Closures provide us with the ability to mentally connect the component with an action and is therefore the preferred way of passing values async in this library.

2) BaseComponents is flexible, meaning that you don't always have to use the components that come with it. Everything is built on top of UIKit, so mix and match if the project requires it. Don't be afraid of using UITableView instead of DataRender if you need the flexibility of tweaking every single value.

3) BaseComponents is evolving. Like Swift, this library will evolve over time to account for new improvements in the language and to cover more features. Documentation will improve and so will the understanding of what is needed next. SwiftUI is on the horizon as the next big thing, but in the mean time, I'm sure that UIKit will stick around. Particularly due to stability and predictability across iOS versions.

## Sample Code

![Screenshot](https://user-images.githubusercontent.com/948693/71639820-2a930100-2c7e-11ea-8700-24bb3c0b6318.png)

When looking at the sample code blow, we have a View Controller that supports:
- Dynamic Type
- Self-sizing cells
- Refresh control, reloading the data
- Layout fully in code
- Minimal state
- Easily understandable components
- Fetching JSON data and binding it to a model
- Responding to size of Keyboard

```
import UIKit

import BaseComponents

struct Post: Codable {
    var userId: Int?
    var id: Int?
    var title: String?
    var body: String?
}

public class PostCell: UITableViewCell {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        textLabel?.lines(0)
            .size(.body, .bold)
        detailTextLabel?.lines(3)
            .size(.subheadline)
            .color(.text, .black)
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func bindObject(_ obj: AnyObject) {
        let post = obj as! Post
        let title = post.title!
        let subtitle = "Posted by News"
        let headline = title.appendingFormat("\n%@", subtitle)
        let range = (headline as NSString).range(of: subtitle)
        let attributedString = NSMutableAttributedString(string: headline)
        attributedString.addAttribute(.font, value: UIFont.size(.footnote), range: range)
        attributedString.addAttribute(.foregroundColor, value: UIColor.lightGray, range: range)
        textLabel?.attributedText = attributedString
        detailTextLabel?.text = post.body?.replacingOccurrences(of: "\n", with: "")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

public class KeybardViewController: UIViewController {

    lazy var dataRender: DataRender = {
        let configuration = DataRenderConfiguration(cellClass: PostCell.self)
        let dataRender = DataRender(configuration: configuration)
        dataRender.rowHeight = UITableView.automaticDimension
        dataRender.clipsToBounds = true
        return dataRender
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Welcome to BaseComponents"
        
        view.backgroundColor = UIColor.white

        let splitView = view.addSplitView { (splitView) in
            
            splitView.insertSafeAreaInsetsPadding(form: self.view, paddingDirection: .top)
            
            let segmentedControl = UISegmentedControl(items: ["Hello","World","Swift"])
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.addAction(for: .valueChanged) { (segmentedControl) in
                let item = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!
                print(item)
            }
            splitView.addSubview(segmentedControl, layoutType: .fixed, value: 44.0, edgeInsets: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10))
        
            dataRender.onRefresh { [weak self] (render) in
                let request = NetFetchRequest(urlString: "https://jsonplaceholder.typicode.com/posts") { (response) in
                    self?.dataRender.refreshing = false
                    self?.view.showProgressView(false)
                    if let posts = response.bind([Post].self) {
                        NotificationView.show(.success, in: self?.dataRender, for: 2, message: "Updated to the latest News", position: .bottom)
                        self?.dataRender.renderArray(posts)
                    }
                    else {
                        NotificationView.show(.error, in: self?.view, for: 2, message: "Check your Network Connection")
                    }
                }
                NetFetch.fetch(request)
            }
            dataRender.onSelect { (itemProperites) in
                let post = itemProperites.object as! Post
                print("Read:",post.body!)
            }
            splitView.addSubview(dataRender, layoutType: .percentage, value: 100)
            dataRender.refreshing = true
            
            splitView.addSubview(UIView().color(.background, .init(white: 0.89, alpha: 1)), layoutType: .fixed, value: 0.5)
            
            splitView.addSplitView(configurationHandler: { (splitView) in
                splitView.direction = .horizontal
                
                let valueLabel = PerformLabel("0.00")
                    .size(.body, [.monoSpaceDigit,.bold])
                    .lines(0)
                
                let slider = UISlider()
                    .addAction(for: .valueChanged) { (slider) in
                        valueLabel.text = NSString(format: "%.02f", slider.value) as String
                }
                splitView.addSubview(slider, layoutType: .percentage, value: 100, edgeInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0))
                splitView.addSubview(valueLabel, layoutType: .automatic, edgeInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
            }) { (parentRect) -> SplitViewLayoutInstruction in
                return .init(layoutType: .fixed, value: 44)
            }
            
            splitView.addSubview(UIView().color(.background, .init(white: 0.89, alpha: 1)), layoutType: .fixed, value: 0.5)
            
            let textField = UITextField(placeholder: "Enter a new Title")
                .align(.center)
                .size(.body)
                .addAction(for: .editingChanged) { (textField) in
                    print(textField.text!)
                }
                .addAction(for: .editingDidEnd, { (textField) in
                    self.title = textField.text
                })
                .shouldReturn { (textField) -> (Bool) in
                    textField.resignFirstResponder()
                    return true
                }
            splitView.addSubview(textField, layoutType: .fixed, value: 84.0)
            
            let paddingView = UIView()
            splitView.addSubview(paddingView) { (parentRect) -> SplitViewLayoutInstruction in
                var bottomInset: CGFloat = 0.0;
                if #available(iOS 11.0, *) {
                    bottomInset = self.view.safeAreaInsets.bottom
                }
                if KeyboardManager.visibility == .visible {
                    bottomInset = 0
                }
                return SplitViewLayoutInstruction(layoutType: .fixed, value: bottomInset)
            }
            
        }
        splitView.direction = .vertical
        
        KeyboardManager.manage(rootView: view, resizableChildSplitView: splitView)
        
        view.showProgressView(true, type: .appleStyle)
    }
    
}

```

## Documentation

Documentation on the components, particularly in code, is currently severly lacking. I'm working on improving it over time and pull requests are always welcome.
