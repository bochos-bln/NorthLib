//
//  FeedbackComposer.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 25.09.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit

public class FeedbackComposer : DoesLog{
  /**
  **Discussion**
   - place: in taz.neo not north Lib because of:
        - colors
        - fonts, font sizes
  
  
  */
  
  static let shared = FeedbackComposer()
  
  
  public static func send(subject:String,
                          bodyText: String,
                          screenshot:UIImage?=nil,
                          logData:Data?=nil,
                          finishClosure:@escaping ((Bool)->())
  ){
    FeedbackComposer.shared.send(subject: subject,
                            bodyText: bodyText,
                            screenshot: screenshot,
                            logData: logData,
                            finishClosure: finishClosure)
  }
  
  ///Remember Bottom Sheet due its strong reference to active (VC) it wount be de-inited
  var feedbackBottomSheet : BottomSheet?
  
  func send(subject:String,
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
      feedbackBottomSheet = BottomSheet(slider: FeedbackViewController(),
                                        into: currentVc)
    }
    else {
      feedbackBottomSheet?.active = currentVc
    }
    
    if let feedbackCtrl = feedbackBottomSheet?.slider as? FeedbackViewController {
      feedbackCtrl.feedbackView.subjectLabel.text = subject
      feedbackCtrl.feedbackView.messageTextView.text = bodyText
    }
    
    guard let feedbackBottomSheet = feedbackBottomSheet else { return }
    
    feedbackBottomSheet.onClose { (slida) in
      finishClosure(true)
      self.feedbackBottomSheet = nil
    }
    let height = currentVc.view.bounds.size.height
      - currentVc.view.safeAreaInsets.top
      - currentVc.view.safeAreaInsets.bottom
      - 10
//    print("sh: \(screenHeight)  ctrlH: \(cvcHeight)")//SE both: 667 - StatusBar
    //Tabbar: 44 StatusBar 20 VC 667 - 647 CTRL.V.H => 20 on SE Safe Areas: UIEdgeInsets(top: 20.0, left: 0.0, bottom: 0.0, right: 0.0)
    //XSMax 896 Tabbar inkl SafeArea: 78 Tabbar 44 // StatusBar inkl SafeArea : 44  Safe Areas: UIEdgeInsets(top: 44.0, left: 0.0, bottom: 34.0, right: 0.0)
    // RequestedHeight: DH - SAtop - sh Bottom -x=10
//    print("Safe Areas: \(currentVc.view.safeAreaInsets)")
    self.feedbackBottomSheet?.coverage = height
    
    
//    if UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0 > 0 {
//      self.feedbackBottomSheet?.coverage = 335
//    }
//    else {
//      self.feedbackBottomSheet?.coverage = 300
//    }
    self.feedbackBottomSheet?.open()
    
//    delay(seconds: 10) {
//      self.feedbackBottomSheet?.close()
//    }
  
  }
}

/**
 
 QQQ: FeedbackViewController viewDidLoad Ctrl: <NorthLib.FeedbackViewController: 0x7fca8df28180
 > View: Optional(<UIView: 0x7fca8df192e0;
 
 QQQ: Composer: NorthLib.FeedbackComposer BottomSheet: Optional(<die_tageszeitung.IssueVC: 0x7fca8e052c00>) Ctrl:Optional(<UIView: 0x7fca8df289b0; frame = (0 20; 375 215); clipsToBounds = YES; layer = <CALayer: 0x600002041de0>>) View:
 QQQ: FeedbackViewController viewDidLoad Ctrl: <NorthLib.FeedbackViewController: 0x7fca8df8dc10> View: Optional(<UIView: 0x7fca8df8f070; frame = (0 0; 375 812); autoresize = W+H; layer = <CALayer: 0x6000020b8620>>)
 QQQ: Composer: NorthLib.FeedbackComposer BottomSheet: Optional(<die_tageszeitung.SectionVC: 0x7fca95014200>) Ctrl:Optional(<UIView: 0x7fca8df8e0d0; frame = (0 20; 375 215); clipsToBounds = YES; layer = <CALayer: 0x6000020b8c60>>) View:
 QQQ: FeedbackViewController viewDidLoad Ctrl: <NorthLib.FeedbackViewController: 0x7fca8dd1ab40> View: Optional(<UIView: 0x7fca8dd48fb0; frame = (0 0; 375 812); autoresize = W+H; layer = <CALayer: 0x60000208d600>>)
 QQQ: Composer: NorthLib.FeedbackComposer BottomSheet: Optional(<die_tageszeitung.ArticleVC: 0x7fca9684b800>) Ctrl:Optional(<UIView: 0x7fca8dd37c70; frame = (0 20; 375 215); clipsToBounds = YES; layer = <CALayer: 0x60000208d5c0>>) View:
 
 */


public class FeedbackViewController : UIViewController{
  
   let feedbackView = FeedbackView()
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    let scrollView = UIScrollView()
   
    scrollView.addSubview(feedbackView)
    feedbackView.pinWidth(UIScreen.main.bounds.size.width)
    pin(feedbackView.left, to: scrollView.left)
    pin(feedbackView.top, to: scrollView.top)
//    feedbackView.pinHeight(400)
//    feedbackView.pinHeight(to: self.view.height, priority: .fittingSizeLevel)
    self.view.addSubview(scrollView)
    pin(scrollView, to: self.view)
  }
  
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
//    feedbackView.pinHeight(self.view.frame.size.height)
    feedbackView.pinHeight(to: self.view.height)
  }
}

public class FeedbackView : UIView{
   static var defaultFontSize = CGFloat(16)
   static var subjectFontSize = CGFloat(32)
  
  let stack = UIStackView()
  
  let subjectLabel = UILabel()
  let sendButton = UIButton()
  let messageTextView = UITextView()
  let screenshotAttachmentButton = ImageView()
  let logAttachmentButton = ImageView()
  
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
 
  private func setup() {
    let hStack1 = UIStackView()
    let hStack2 = UIStackView()
    hStack1.addBorder(.yellow)
    hStack2.addBorder(.yellow)
    stack.addBorder(.magenta)
    subjectLabel.addBorder(.red)
    sendButton.addBorder(.green)
    messageTextView.addBorder(.blue)
    screenshotAttachmentButton.addBorder(.purple)
    logAttachmentButton.addBorder(.yellow)
    
    hStack1.alignment = .fill
    hStack2.alignment = .fill
    
    hStack1.distribution = .fillProportionally
    
    hStack1.axis = .horizontal
    hStack2.axis = .horizontal
    stack.axis = .vertical
    
    /// Style
    sendButton.setBackgroundColor(color: .blue, forState: .normal)
    sendButton.setBackgroundColor(color: .lightGray, forState: .disabled)
    sendButton.isEnabled = true
    sendButton.layer.cornerRadius = 21
//    sendButton.pinWidth(42, priority: .required)
//    sendButton.pinHeight(42)
    sendButton.pinSize(CGSize(width: 42, height: 42))
    sendButton.setImage(UIImage(name: "arrow.up"), for: .normal)
    sendButton.imageView?.tintColor = .white
    subjectLabel.numberOfLines = 0
    subjectLabel.font = UIFont.boldSystemFont(ofSize: Self.subjectFontSize)
//    messageTextView.numberOfLines = 0
//    messageTextView.isEnabled = true
    /***DEMO JUST FOR TEST***/
    
//    UIStackView
    
    messageTextView.pinHeight(52, priority: UILayoutPriority(100))//set minHeight!
    /***DEMO JUST FOR TEST***/
    subjectLabel.pinHeight(52, priority: .fittingSizeLevel)//set minHeight!
    screenshotAttachmentButton .pinSize(CGSize(width: 32, height: 40))//PinHeight Later!!
    logAttachmentButton.pinSize(CGSize(width: 32, height: 40))//PinHeight Later!!
    /// Add
//    hStack1.addArrangedSubview(subjectLabel)
//    hStack1.addArrangedSubview(sendButton)
//
//    hStack2.addArrangedSubview(screenshotAttachmentButton)
//    hStack2.addArrangedSubview(logAttachmentButton)
    
    stack.addArrangedSubview(subjectLabel)
    stack.addArrangedSubview(messageTextView)
    stack.addArrangedSubview(logAttachmentButton)

    self.addSubview(stack)
    pin(stack, to: self, dist: 12)
    
    ///bla
    self.backgroundColor = .yellow
    
    screenshotAttachmentButton.backgroundColor = .green
    logAttachmentButton.backgroundColor = .blue
    
  }
}
