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
      feedbackCtrl.feedbackView.subjectLabel.text = subject
      feedbackCtrl.feedbackView.messageTextView.text = bodyText
      feedbackCtrl.feedbackView.screenshotAttachmentButton.image = screenshot
    }
    
    guard let feedbackBottomSheet = feedbackBottomSheet else { return }
    
    feedbackBottomSheet.onClose { (slida) in
      finishClosure(true)
      self.feedbackBottomSheet = nil
    }
    self.feedbackBottomSheet?.coverageRatio = 1.0
    self.feedbackBottomSheet?.open()
    
//    delay(seconds: 10) {
//      self.feedbackBottomSheet?.close()
//    }
  
  }
}

open class FeedbackViewController : UIViewController{
  public let feedbackView = FeedbackView()
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(feedbackView)
    pin(feedbackView, to:self.view)
  }
}

public class FeedbackView : UIView {
  static var defaultFontSize = CGFloat(16)
  static var subjectFontSize = CGFloat(32)
  
  let stack = UIStackView()
  
  public let subjectLabel = UILabel()
  public let sendButton = UIButton()
  public let messageTextView = UITextView()
  public let screenshotAttachmentButton = ScaledHeightImageView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 60)))
  public let logAttachmentButton = ScaledHeightImageView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 60)))
  
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
    sendButton.addTarget(self, action: #selector(resignActive), for: .touchUpInside)
    
    hStack1.alignment = .fill
//    hStack2.alignment = .fill
//
//    hStack2.distribution = .fillProportionally
    
    hStack1.axis = .horizontal
//    hStack2.axis = .horizontal
    stack.axis = .vertical
    /// Style
    sendButton.isEnabled = true
    sendButton.layer.cornerRadius = 21
    sendButton.setImage(UIImage(name: "arrow.up"), for: .normal)
    sendButton.imageView?.tintColor = .white
    subjectLabel.numberOfLines = 0
    subjectLabel.font = UIFont.boldSystemFont(ofSize: Self.subjectFontSize)
    logAttachmentButton.image = UIImage(name: "doc.text")

    
    screenshotAttachmentButton.contentMode = .scaleAspectFit
    
    logAttachmentButton.contentMode = .scaleAspectFit
    
    screenshotAttachmentButton.addBorder(.red)
    logAttachmentButton.addBorder(.blue)
    hStack2.addBorder(.green)
    
    /// Add
    hStack1.addArrangedSubview(subjectLabel)
    hStack1.addArrangedSubview(sendButton)
    
    hStack2.addSubview(screenshotAttachmentButton)
//    let spacer = UIView()
    logAttachmentButton.contentMode = .scaleAspectFit
    screenshotAttachmentButton.contentMode = .scaleAspectFit
//    spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
//    screenshotAttachmentButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
//    logAttachmentButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
//    spacer.setContentHuggingPriority(.required, for: .vertical)
//    spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
//    spacer.setContentHuggingPriority(.required, for: .vertical)
    hStack2.addSubview(logAttachmentButton)
    
    //Set Constraints after added to Stack View otherwise Contraint Errosrs are displayed
    sendButton.pinSize(CGSize(width: 42, height: 42))

    screenshotAttachmentButton.pinHeight(70)
    logAttachmentButton.pinHeight(70)
//    screenshotAttachmentButton.intrinsicContentSize
//    screenshotAttachmentButton.pinWidth(20, priority: UILayoutPriority(1))
//    logAttachmentButton.pinWidth(20, priority: UILayoutPriority(1))
    
    pin(screenshotAttachmentButton, to: hStack2, exclude: .right)
    pin(logAttachmentButton, to: hStack2, exclude: .left)
    

    
    stack.addArrangedSubview(hStack1)
    stack.addArrangedSubview(messageTextView)
    stack.addArrangedSubview(hStack2)

    self.addSubview(stack)
    pin(stack, toSafe: self, dist: 12)
  }
}


public class ScaledHeightImageView: UIImageView {

  public override var intrinsicContentSize: CGSize {

        if let myImage = self.image {
            let myImageWidth = myImage.size.width
            let myImageHeight = myImage.size.height
            let myViewWidth = self.frame.size.width

            let ratio = myViewWidth/myImageWidth
            let scaledHeight = myImageHeight * ratio

            return CGSize(width: myViewWidth, height: scaledHeight)
        }
        return CGSize(width: -1.0, height: -1.0)
    }
}
