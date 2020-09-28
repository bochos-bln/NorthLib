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
    
    guard let feedbackBottomSheet = feedbackBottomSheet else { return }
    
    feedbackBottomSheet.onClose { (slida) in
      finishClosure(true)
      self.feedbackBottomSheet = nil
    }
    
    if UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0 > 0 {
      self.feedbackBottomSheet?.coverage = 235
    }
    else {
      self.feedbackBottomSheet?.coverage = 200
    }
    self.feedbackBottomSheet?.open()
    
    delay(seconds: 10) {
      self.feedbackBottomSheet?.close()
    }
  
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
  public override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .red
    print("QQQ: FeedbackViewController viewDidLoad Ctrl: \(self) View: \(self.view)")
  }
}

public class FeedbackView : UIView{
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
 
  private func setup() {
    
    self.backgroundColor = .red
  }
  

}
