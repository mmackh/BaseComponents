import UIKit
import BaseComponents

public class ConditionalLayoutViewController: UIViewController {
    public override func viewDidLoad() {
        view.color(.background, .systemBackground)
        
        let musicPlayerView: MusicPlayerView = MusicPlayerView()
        musicPlayerView.frame = view.bounds
        musicPlayerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(musicPlayerView)
    }
}

class MusicPlayerView: UIView {
    enum State {
        case compact
        case expanded
        case expandedAlbum
    }
    
    static var compactHeight: CGFloat = 64
    static var compactBackgroundColor: UIColor = .init(white: 0.91, alpha: 1)
    
    var conditionalLayoutView: ConditionalLayoutView? = nil
    
    lazy var splitView: SplitView = {
        addSplitView { [unowned self] (splitView) in
            
            // Padding view to push the drawer down
            splitView.addSubview(UIView()) { (parentRect) -> SplitViewLayoutInstruction in
                return .init(layoutType: .percentage, value: self.currentState == .compact ? 100 : 20)
            }
            
            // Actual drawer
            splitView.addSplitView(configurationHandler: { (musicPlayerSplitView) in
                musicPlayerSplitView.color(.background, MusicPlayerView.compactBackgroundColor)
                
                self.conditionalLayoutView = musicPlayerSplitView.addConditionalLayoutView(configurationHandler: { (conditionalLayoutView) in
                    // Compact Layout
                    conditionalLayoutView.addSubviews({ (targetView) in
                        targetView.didLayoutSubviews {
                            self.currentTrackTitle
                                .size(.body, .bold)
                            
                            self.playButton.transform = .identity
                            self.toggleStateButton.transform = .identity
                        }
                        
                        targetView.direction = .horizontal
                        
                        targetView.addPadding(15)
                        
                        targetView.addSubview(self.albumImageView, layoutType: .fixed, value: 40)
                        
                        targetView.addPadding(15)
                        
                        targetView.addSubview(self.currentTrackTitle, layoutType: .percentage, value: 100)
                        
                        targetView.addPadding(10)
                        
                        targetView.addSubview(self.backwardButton, layoutType: .fixed, value: 30)
                        
                        targetView.addPadding(15)
                        
                        targetView.addSubview(self.playButton, layoutType: .fixed, value: 30)
                        
                        targetView.addPadding(15)
                        
                        targetView.addSubview(self.forwardButton, layoutType: .fixed, value: 30)
                        
                        targetView.addPadding(30)
                        
                        targetView.addSubview(self.toggleStateButton, layoutType: .automatic, value: 0)
                        
                        targetView.addPadding(15)
                    }) { (traitCollection) -> Bool in
                        return self.currentState == .compact
                    }
                    
                    // Expanded Portrait Layout
                    conditionalLayoutView.addSubviews({ (targetView) in
                        targetView.didLayoutSubviews {
                            self.currentTrackTitle
                                .size(.title3, .bold)
                            
                            self.toggleStateButton.transform = .init(rotationAngle: .pi)
                            self.playButton.transform = .init(scaleX: 2.2, y: 2.2)
                            
                        }
                        
                        targetView.addPadding(15)
                        
                        targetView.addSubview(self.toggleStateButton, layoutType: .automatic)
                        
                        targetView.addPadding(10)
                        
                        targetView.addSubview(self.albumImageView, layoutType: .percentage, value: 100, edgeInsets: .init(horizontal: 10, vertical: 10))
                        
                        targetView.addPadding(10)
                        
                        targetView.addSubview(self.trackView, layoutType: .fixed, value: 20)
                        
                        targetView.addPadding(15)
                        
                        targetView.addSplitView(configurationHandler: { (splitView) in
                            splitView.direction = .horizontal
                            
                            splitView.addPadding(layoutType: .equal)
                            splitView.addSubview(currentTrackTitle, layoutType: .automatic)
                            splitView.addPadding(layoutType: .equal)
                        }) { (parentRect) -> SplitViewLayoutInstruction in
                            .init(layoutType: .fixed, value: 40)
                        }
                        
                        targetView.addSubview(self.currentArtist, layoutType: .automatic)
                        
                        targetView.addSplitView(configurationHandler: {  (splitView) in
                            splitView.direction = .horizontal
                            
                            splitView.addPadding(layoutType: .percentage, value: 50)
                            
                            splitView.addSubview(self.backwardButton, layoutType: .fixed, value: 80)
                            splitView.addSubview(self.playButton, layoutType: .fixed, value: 120)
                            splitView.addSubview(self.forwardButton, layoutType: .fixed, value: 80)
                            
                            splitView.addPadding(layoutType: .percentage, value: 50)
                            
                        }) { (parentRect) -> SplitViewLayoutInstruction in
                            return .init(layoutType: .fixed, value: 100)
                        }
                        
                        targetView.addPadding(15)

                        targetView.addSubview(self.albumButton, layoutType: .automatic)
                        
                        targetView.addPadding(30)
                    }) { (traitCollection) -> Bool in
                        return self.currentState == .expanded && self.bounds.height > self.bounds.width
                    }
                                        
                    // Album songs layout
                    conditionalLayoutView.addSubviews({ (targetView) in
                        targetView.didLayoutSubviews {
                            self.currentTrackTitle
                                .size(.body, .bold)
                            
                            self.playButton.transform = .identity
                        }
                        
                        targetView.addPadding(15)
                        
                        targetView.addSubview(UILabel("Track List").size(.largeTitle, .bold), layoutType: .automatic, value: 0, edgeInsets: .init(top: 0, left: 15, bottom: 0, right: 0))
                        
                        targetView.addPadding(15)
                        
                        targetView.addSubview(self.albumTrackDataRender, layoutType: .percentage, value: 100)
                        
                        targetView.addSubview(UIView().color(.background, .hairline), layoutType: .fixed, value: .onePixel)
                        
                        targetView.addSplitView(configurationHandler: { (targetView) in
                            targetView.didLayoutSubviews {
                                self.currentTrackTitle
                                    .size(.body, .bold)
                                
                                self.playButton.transform = .identity
                            }
                            
                            targetView.direction = .horizontal
                            
                            targetView.addPadding(15)
                            
                            targetView.addSubview(self.albumImageView, layoutType: .fixed, value: 40)
                            
                            targetView.addPadding(15)
                            
                            targetView.addSubview(self.currentTrackTitle, layoutType: .percentage, value: 100)
                            
                            targetView.addPadding(10)
                            
                            targetView.addSubview(self.backwardButton, layoutType: .fixed, value: 30)
                            
                            targetView.addPadding(15)
                            
                            targetView.addSubview(self.playButton, layoutType: .fixed, value: 30)
                            
                            targetView.addPadding(15)
                            
                            targetView.addSubview(self.forwardButton, layoutType: .fixed, value: 30)
                            
                            targetView.addPadding(30)
                            
                            targetView.addSubview(self.toggleStateButton, layoutType: .automatic, value: 0)
                            
                            targetView.addPadding(15)
                        }) { (parentRect) -> SplitViewLayoutInstruction in
                            .init(layoutType: .fixed, value: MusicPlayerView.compactHeight)
                        }
                        
                        targetView.addPadding(15)

                        targetView.addSubview(self.albumButton, layoutType: .automatic)
                        
                        targetView.addPadding(30)
                        
                    }) { (traitCollection) -> Bool in
                        return self.currentState == .expandedAlbum
                    }
                    
                    // Expanded Layout Landscape
                    conditionalLayoutView.addSubviews( { (targetView) in
                        targetView.didLayoutSubviews {
                            self.currentTrackTitle
                                .size(.title3, .bold)
                            
                            self.toggleStateButton.transform = .init(rotationAngle: .pi)
                            self.playButton.transform = .init(scaleX: 2.2, y: 2.2)
                        }
                        
                        targetView.addPadding(15)
                        
                        targetView.addSubview(self.toggleStateButton, layoutType: .automatic)
                        
                        targetView.addPadding(15)
                        
                        targetView.addSplitView(configurationHandler: { (splitView) in
                            splitView.direction = .horizontal
                            
                            splitView.addSplitView(configurationHandler: { (splitView) in
                                splitView.addSubview(self.albumImageView, layoutType: .percentage, value: 100)
                                
                                splitView.addPadding(15)
                                
                                splitView.addSubview(self.trackView, layoutType: .fixed, value: 20)
                                
                                splitView.addPadding(30)
                            }) { (parentRect) -> SplitViewLayoutInstruction in
                                .init(layoutType: .percentage, value: 50)
                            }
                            
                            splitView.addPadding(10)
                            
                            splitView.addSplitView(configurationHandler: { (splitView) in
                                splitView.addSplitView(configurationHandler: { (splitView) in
                                    splitView.direction = .horizontal
                                    
                                    splitView.addPadding(layoutType: .equal)
                                    splitView.addSubview(self.currentTrackTitle, layoutType: .automatic)
                                    splitView.addPadding(layoutType: .equal)
                                }) { (parentRect) -> SplitViewLayoutInstruction in
                                    .init(layoutType: .fixed, value: 40)
                                }
                                
                                splitView.addSubview(self.currentArtist, layoutType: .automatic)
                                
                                splitView.addPadding(layoutType: .percentage, value: 50)

                                splitView.addSplitView(configurationHandler: { (splitView) in
                                    splitView.direction = .horizontal
                                    
                                    splitView.addPadding(layoutType: .percentage, value: 50)
                                    
                                    splitView.addSubview(self.backwardButton, layoutType: .fixed, value: 80)
                                    splitView.addSubview(self.playButton, layoutType: .fixed, value: 120)
                                    splitView.addSubview(self.forwardButton, layoutType: .fixed, value: 80)
                                    
                                    splitView.addPadding(layoutType: .percentage, value: 50)
                                    
                                }) { (parentRect) -> SplitViewLayoutInstruction in
                                    return .init(layoutType: .fixed, value: 100)
                                }
                                
                                splitView.addPadding(layoutType: .percentage, value: 50)
                                                                
                                splitView.addSplitView(configurationHandler: { (splitView) in
                                    splitView.direction = .horizontal
                                    
                                    splitView.addSubview(self.albumButton, layoutType: .percentage, value: 50)
                                    
                                    splitView.addSubview(self.toggleStateButton, layoutType: .percentage, value: 50)
                                    
                                }) { (parentRect) -> SplitViewLayoutInstruction in
                                    .init(layoutType: .fixed, value: 30)
                                }
                                
                                splitView.addPadding(15)
                                
                            }) { (parentRect) -> SplitViewLayoutInstruction in
                                .init(layoutType: .percentage, value: 50)
                            }

                            
                        }) { (parentRect) -> SplitViewLayoutInstruction in
                            .init(layoutType: .percentage, value: 100)
                        }
                        
                        targetView.addPadding(15)
                    }) { (traitCollection) -> Bool in
                        return self.currentState == .expanded && self.bounds.height < self.bounds.width
                    }
                    
                }, valueHandler: { (parentRect) -> SplitViewLayoutInstruction in
                    .init(layoutType: .percentage, value: 100)
                })
                
                
                let tap = UITapGestureRecognizer { (tap) in
                    self.currentState = self.currentState == .compact ? .expanded : .compact
                }
                musicPlayerSplitView.addGestureRecognizer(tap)
                
            }) { (parentRect) -> SplitViewLayoutInstruction in
                return self.currentState == .compact ? .init(layoutType: .fixed, value: MusicPlayerView.compactHeight) : .init(layoutType: .percentage, value: 80)
            }
            
            splitView.insertSafeAreaInsetsPadding(form: self, paddingDirection: .bottom)
        }
    }()
    
    
    let currentTrackTitle: UILabel = UILabel("Another Brick in the Wall")
        .color(.text, .darkGray)
    let currentArtist: UILabel = UILabel("Pink Floyd")
        .align(.center)
        .color(.text, .gray)
        .size(using: UIFont.systemFont(ofSize: 15, weight: .regular))
    var trackView: SplitView = {
        let splitView = SplitView()
        splitView.direction = .horizontal
                                   
        splitView.addSubview(UILabel("0:30").size(.footnote, .monoSpaceDigit).color(.text, .gray).align(.right), layoutType: .fixed, value: 80)

        splitView.addPadding(10)

        let trackSlider = UISlider()
        trackSlider.value = 0.25
        splitView.addSubview(trackSlider, layoutType: .percentage, value: 100)

        splitView.addPadding(10)

        splitView.addSubview(UILabel("3:21").size(.footnote, .monoSpaceDigit).color(.text, .gray).align(.left), layoutType: .fixed, value: 80)
        
        return splitView
    }()
    
    let albumImageView: UIImageView = UIImageView().image(urlString: "https://upload.wikimedia.org/wikipedia/en/c/cb/PinkFloydAnotherBrickCover.jpg").mode(.scaleAspectFit)
    let playButton: UIButton = UIButton(symbol: "play.fill", accessibility: "Play")
    let backwardButton: UIButton = UIButton(symbol: "backward.fill", accessibility: "Go Back")
    let forwardButton: UIButton = UIButton(symbol: "forward.fill", accessibility: "Go Forward")
    lazy var toggleStateButton: UIButton = {
        let button = UIButton(symbol: "chevron.compact.up", accessibility: "Expand", weight: .bold, mode: .scaleAspectFit).tint(.lightGray).addAction(for: .touchUpInside) { [unowned self] (button) in
            self.currentState = self.currentState == .compact ? .expanded : .compact
        }
        return button
    }()
    lazy var albumButton: UIButton = {
        let button = UIButton(symbol: "music.note.list", accessibility: "Collapse", weight: .bold, mode: .scaleAspectFit).addAction(for: .touchUpInside) { [unowned self] (button) in
            self.currentState = self.currentState == .expandedAlbum ? .expanded : .expandedAlbum
        }
        return button
    }()
    lazy var albumTrackDataRender: DataRender = {
        let config = DataRenderConfiguration(cellClass: UITableViewCell.self)
        let dataRender = DataRender(configuration: config)
        dataRender.backgroundColor = .clear
        dataRender.rowHeight = UITableView.automaticDimension
        dataRender.beforeBind { (itemRenderProperties) in
            let cell = itemRenderProperties.cell as! UITableViewCell
            cell.textLabel?.text = itemRenderProperties.object as? String
            cell.textLabel?.numberOfLines = 0
            cell.backgroundColor = .clear
            cell.textLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        }
        dataRender.renderArray(["1. Wait, what is this?",
                                "2. Seems like the latest tech",
                                "3. Could have been done in SwiftUI",
                                "4. But no, that's not it",
                                "5. It's UIKit!!",
                                "6. It's ConditionalLayoutView feat. BaseComponents"])
        return dataRender
    }()
    
    var currentState: State = .compact {
        didSet {
            
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.7, options: .allowUserInteraction, animations: {
                
                self.splitView.invalidateLayout()
                
                if oldValue == .expandedAlbum || self.currentState == .expandedAlbum {
                    self.conditionalLayoutView?.invalidateLayout()
                }
                
            }, completion: nil)
            
            self.trackView.alpha = 0
            self.trackView.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8).concatenating(.init(translationX: 0, y: 20))
            
            self.currentArtist.alpha = 0
            self.currentArtist.transform = .init(translationX: 0, y: 20)
            
            self.albumTrackDataRender.alpha = 0
            
            UIView.animate(withDuration: 0.3, delay: 0.15, options: .allowUserInteraction, animations: {
                self.albumTrackDataRender.alpha = 1
                
                self.trackView.alpha = 1
                self.trackView.transform = .identity
                
                self.currentArtist.alpha = 1
                self.currentArtist.transform = .identity
            }, completion: nil)
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        splitView.invalidateLayout()
        
        self.playButton.tag = 77
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
