import UIKit
import BaseComponents

public class ScrollingViewController: UIViewController {
    public override func viewDidLoad() {
        view.color(.background, .systemBackground)
        
        view.addScrollingView { (scrollingView) in
            scrollingView.automaticallyAdjustsLayoutMarginInsets = true
            scrollingView.alwaysBounceVertical = true
            
            let headline = PerformLabel("Welcome to BaseComponents").size(.title1, .bold)
            scrollingView.addSubview(headline)
            
            scrollingView.addPadding(10)
            
            scrollingView.addScrollingView { (scrollingView) in
                scrollingView.edgeInsets = .init(horizontal: 15, vertical: 15)
                scrollingView.border(.systemRed, width: 1, cornerRadius: 12).color(.background, UIColor.systemRed.alpha(0.2))
                
                scrollingView.addSubview(UILabel("I am a nested ScrollView. I calculate my own height. Insets are set to 15pts.").size(.footnote, .bold))
                
                scrollingView.addPadding(10)
                
                scrollingView.addSubview(UILabel("Soon, nested-nested ScrollView.").size(.footnote))
                
                scrollingView.addPadding(10)
                
                scrollingView.addScrollingView { (scrollingView) in
                    scrollingView.edgeInsets = .init(horizontal: 5, vertical: 5)
                    scrollingView.border(.systemGreen, width: 1, cornerRadius: 8).color(.background, UIColor.systemGreen.alpha(0.2))
                    
                    scrollingView.addSubview(UILabel("I'm a nested-nested ScrollView. Insets are set to 5pts").size(.footnote))
                    
                    scrollingView.addPadding(5)
                    
                    scrollingView.addScrollingView { (scrollingView) in
                        scrollingView.edgeInsets = .init(horizontal: 2, vertical: 2)
                        scrollingView.border(.systemPurple, width: 1, cornerRadius: 4).color(.background, UIColor.purple.alpha(0.2))
                        
                        scrollingView.addSubview(UILabel("I'm a nested-nested-nested ScrollView. Insets are set to 2pts. Might be very nested, but still able to determine my own height and affect my parent's overall height.").size(.footnote))
                    }
                }
            }
            
            scrollingView.addPadding(10)
            
            let subtitle = PerformLabel("BaseComponents aims to provide easily reusable and understandable components to increase productivity with UIKit. Formerly written in Objective-C and used extensively in production, the time has come to transition to Swift.").size(.callout).color(.text, .secondaryLabel)
            scrollingView.addSubview(subtitle)
            
            scrollingView.addPadding(20)
            
            let chapterTitle = PerformLabel("Design Goals").size(.title3)
            scrollingView.addSubview(chapterTitle)
            
            scrollingView.addPadding(10)
            
            let body = PerformLabel("""
1. BaseComponents allows you to write efficient & understandable code in a short amount of time by abstracting the tedious stuff. Implementing data sources or delegates takes a lot of boilerplate and often there's no need. Closures provide us with the ability to mentally connect the component with an action and is therefore the preferred way of passing values async in this library.

2. BaseComponents is flexible, meaning that you don't always have to use the components that come with it. Everything is built on top of UIKit, so mix and match if the project requires it. Don't be afraid of using UITableView instead of DataRender if you need the flexibility of tweaking every single value.

3. BaseComponents is evolving. Like Swift, this library will evolve over time to account for new improvements in the language and to cover more features. Documentation will improve and so will the understanding of what is needed next. SwiftUI is on the horizon as the next big thing, but in the mean time, I'm sure that UIKit will stick around. Particularly due to stability and predictability across iOS versions.
""")
            scrollingView.addSubview(body)
        }
        
    }
}
