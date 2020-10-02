//
//  FeedbackComposer.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 25.09.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit

public class FeedbackBottomSheet : BottomSheet{
  
  // Keyboard change notification handler, shifts sheet if necessary
  @objc override func handleKeyboardChange(notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
      as? NSValue)?.cgRectValue else { return }
    guard kbDistance == nil else { return }
    kbDistance = keyboardFrame.size.height
    slideUp(keyboardFrame.size.height)
  }
  
  public override func slideUp(_ dist: CGFloat) {
      guard isOpen else { return }
      UIView.animate(seconds: duration) { [weak self] in
        guard let self = self else { return }
        self.bottomConstraint.constant -= (dist)
        self.heightConstraint.constant -= (dist)
        self.active.view.layoutIfNeeded()
      }
  }
}

open class FeedbackComposer : DoesLog{
  static let shared = FeedbackComposer()
  public init() {}
  ///Remember Bottom Sheet due its strong reference to active (VC) it wount be de-inited
  var feedbackBottomSheet : BottomSheet?
  
  
  let _feedbackViewController = FeedbackViewController()
  open var feedbackViewController : FeedbackViewController {
    get { return _feedbackViewController }
  }
  
  
  public func send(subject:String,
            bodyText: String,
            screenshot:UIImage?=nil,
            logData:Data?=nil,
            finishClosure:@escaping ((Bool)->())
  ){
    guard let currentVc = UIViewController.top() else {
      log("Error, no Controller to Present")
      return;
    }
    
    //ToDo may do nothing if still presented!?
    if feedbackBottomSheet == nil {
      feedbackBottomSheet = FeedbackBottomSheet(slider: feedbackViewController,
                                        into: currentVc)
    }
    else {
      feedbackBottomSheet?.active = currentVc
    }
    
    if let feedbackCtrl = feedbackBottomSheet?.slider as? FeedbackViewController {
      feedbackCtrl.feedbackView.messageTextView.text = bodyText
      feedbackCtrl.screenshot = screenshot
      if let data = logData {
         feedbackCtrl.logString = String(data:data , encoding: .utf8)
      }
      
      feedbackCtrl.subject = subject
      feedbackCtrl.feedbackView.sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
    }
    
    guard let feedbackBottomSheet = feedbackBottomSheet else { return }
    
    feedbackBottomSheet.onClose { (slida) in
      finishClosure(true)
      self.feedbackBottomSheet = nil
    }
    self.feedbackBottomSheet?.coverageRatio = 1.0
    self.feedbackBottomSheet?.open()
  }
  
  @objc open func handleSend(){
    if let feedbackCtrl = feedbackBottomSheet?.slider as? FeedbackViewController {
      feedbackCtrl.handleSend()
    }
  }
}

open class FeedbackViewController : UIViewController{
  
  public var subject : String? {
    didSet {
         feedbackView.subjectLabel.text = subject
       }
  }
  public var logString: String? = "-"
  public var screenshot: UIImage? {
    didSet {
      feedbackView.screenshotAttachmentButton.image = screenshot
    }
  }
  
  @objc open func handleSend(){
    print("not implemented here")
    //API Requests and more needs to be overwritten in inherited Classes
  }
  
  public let feedbackView = FeedbackView()

  //TODO: Optimize, take care of Memory Leaks
  func showScreenshot(){
    print("Open detail View")
    let oi = OptionalImageItem()
    oi.image = self.feedbackView.screenshotAttachmentButton.image
    let ziv = ZoomedImageView(optionalImage:oi)
    let vc = UIViewController()
    vc.view.addSubview(ziv)
    pin(ziv, to: vc.view)
    let overlay = Overlay(overlay: vc, into: self)
    
    vc.view.frame = self.view.frame
    vc.view.setNeedsLayout()
    vc.view.layoutIfNeeded()
    overlay.overlaySize = self.view.frame.size
    let openToRect = self.view.frame
    
    ziv.addBorder(.green)
    
    let child = self.feedbackView.screenshotAttachmentButton
    let fromFrame = child.convert(child.frame, to: self.view)
    
    overlay.openAnimated(fromFrame: fromFrame,
                         toFrame: openToRect)
  }
  
  //TODO: Optimize, take care of Memory Leaks
  func showLog(){
    let logVc = UIViewController()
    let logView = SimpleLogView()
    logView.append(txt: logString ?? "")
    logVc.view.addSubview(logView)
    pin(logView, to: logVc.view)
    self.present(logVc, animated: true) {
      print("done!!")
    }
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(feedbackView)
    pin(feedbackView, to:self.view)
    
    feedbackView.screenshotAttachmentButton.onTapping { [weak self] (_) in
      self?.showScreenshot()
    }
    
    feedbackView.logAttachmentButton.onTapping {  [weak self] (_) in
      self?.showLog()
    }
    /// Setup Attatchment Menus
   _ = logAttatchmentMenu
   _ = screenshotAttatchmentMenu
  }
  
  lazy var logAttatchmentMenu : ContextMenu = {
    let menu = ContextMenu(view: self.feedbackView.logAttachmentButton)
    menu.addMenuItem(title: "View", icon: "eye") {[weak self]  (_) in
      self?.showLog()
    }
    menu.addMenuItem(title: "Löschen", icon: "trash.circle") { (_) in
      self.feedbackView.logAttachmentButton.removeFromSuperview()
    }
    menu.addMenuItem(title: "Abbrechen", icon: "multiply.circle") { (_) in }
    return menu
  }()
  
  lazy var screenshotAttatchmentMenu : ContextMenu = {
    let menu = ContextMenu(view: self.feedbackView.screenshotAttachmentButton)
    menu.addMenuItem(title: "View", icon: "eye") { [weak self]  (_) in
      self?.showScreenshot()
    }
    menu.addMenuItem(title: "Löschen", icon: "trash.circle") { (_) in
      self.feedbackView.screenshotAttachmentButton.removeFromSuperview()
      //self.screenshot = nil
    }
    menu.addMenuItem(title: "Abbrechen", icon: "multiply.circle") { (_) in }
    return menu
  }()
  
  /// Define the menu to display on long touch of a MomentView
  public var attatchmentMenu: [(title: String, icon: String, closure: (String)->())] = []
  
  /// Add an additional menu item
  public func addMenuItem(title: String, icon: String, closure: @escaping (String)->()) {
    attatchmentMenu += (title: title, icon: icon, closure: closure)
  }
  
  public var mainmenu1 : ContextMenu?
  public var mainmenu2 : ContextMenu?
  
}

public class FeedbackView : UIView {
  static var defaultFontSize = CGFloat(16)
  static var subjectFontSize = CGFloat(32)
  
  let stack = UIStackView()
  
  public let subjectLabel = UILabel()
  public let sendButton = UIButton()
  public let messageTextView = UITextView()
  public let screenshotAttachmentButton = XImageView()// ScaledHeightImageView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 60)))
  public let logAttachmentButton = XImageView()//ScaledHeightImageView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 60)))
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  @objc func resignActive() {
    messageTextView.resignFirstResponder()
  }
 
  private func setup() {
    self.onTapping { [weak self] (_) in
      guard let self = self else { return }
      if self.messageTextView.isFirstResponder {
        self.messageTextView.resignFirstResponder()
      }
    }
    
    let hStack1 = UIStackView()
    let hStack2 = UIView()
    
    hStack1.alignment = .fill
    hStack1.axis = .horizontal
    stack.axis = .vertical
    /// Style
    sendButton.isEnabled = true
    sendButton.addBorder(.red)
    sendButton.layer.cornerRadius = 21
    sendButton.setImage(UIImage(name: "arrow.up"), for: .normal)
    sendButton.imageView?.tintColor = .white
    subjectLabel.numberOfLines = 0
    subjectLabel.font = UIFont.boldSystemFont(ofSize: Self.subjectFontSize)
    logAttachmentButton.image = UIImage(name: "doc.text")
    
    screenshotAttachmentButton.contentMode = .scaleAspectFit
    logAttachmentButton.contentMode = .scaleAspectFit
    
    /// Add
    hStack1.addArrangedSubview(subjectLabel)
    hStack1.addArrangedSubview(sendButton)
    
    hStack2.addSubview(screenshotAttachmentButton)
    logAttachmentButton.contentMode = .center
    screenshotAttachmentButton.contentMode = .scaleAspectFit
    hStack2.addSubview(logAttachmentButton)
    
    //Set Constraints after added to Stack View otherwise Contraint Errosrs are displayed
    sendButton.pinSize(CGSize(width: 42, height: 42))

    screenshotAttachmentButton.pinHeight(70)
    logAttachmentButton.pinHeight(70)
    
    pin(screenshotAttachmentButton, to: hStack2, exclude: .right)
    pin(logAttachmentButton, to: hStack2, exclude: .left)
    
    stack.addArrangedSubview(hStack1)
    stack.addArrangedSubview(messageTextView)
    stack.addArrangedSubview(hStack2)

    self.addSubview(stack)
    pin(stack, toSafe: self, dist: 12)
  }
}

extension UIImageView {
    func addAspectRatioConstraint(image: UIImage?) {
        if let image = image {
            removeAspectRatioConstraint()
            let aspectRatio = image.size.width / image.size.height
            let constraint = NSLayoutConstraint(item: self, attribute: .width,
                                                relatedBy: .equal,
                                                toItem: self, attribute: .height,
                                                multiplier: aspectRatio, constant: 0.0)
            addConstraint(constraint)
        }
    }
    
    func removeAspectRatioConstraint() {
        for constraint in self.constraints {
            if (constraint.firstItem as? UIImageView) == self,
               (constraint.secondItem as? UIImageView) == self {
                removeConstraint(constraint)
            }
        }
    }
}

public class XImageView: UIImageView {
  override public var image: UIImage?{
    didSet{
      addAspectRatioConstraint(image: image)
    }
  }
}
