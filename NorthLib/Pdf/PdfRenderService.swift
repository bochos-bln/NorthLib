//
//  PdfRenderService.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 13.11.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit
import PDFKit

/// Service that renders PDF's on limited count of Threads,
/// each parallel render open its own file handle
/// to avoid memory leaks within unclosed UIGraphicsContext PDF File handles
class PdfRenderService{

  private static let sharedInstance = PdfRenderService()
  private init(){}
  
  private let userInteractiveSemaphore = DispatchSemaphore(value: 2)//How many 1:! Renderings parallel?
  private let backgroundSemaphore = DispatchSemaphore(value: 4)//How many 1:! Renderings parallel?
  
  private let userInteractiveQueue = DispatchQueue.init(label: "imageRendererQueue",
                                 qos: .userInteractive,
                                 attributes: .concurrent,
                                 autoreleaseFrequency: .workItem,
                                 target: nil)
  
  private let backgroundQueue = DispatchQueue.init(label: "backgroundImageRendererQueue",
                                 attributes: .concurrent,
                                 autoreleaseFrequency: .workItem,
                                 target: nil)
    
  public static func render(item:ZoomedPdfImageSpec,
                            scale:CGFloat = 1.0,
                            backgroundRenderer : Bool = false,
                            finischedCallback: @escaping((UIImage?)->())){
    sharedInstance.enqueueRender(item: item,
                               scale: scale,
                               backgroundRenderer : backgroundRenderer,
                               finischedCallback: finischedCallback)
  }
  
  public static func render(item:ZoomedPdfImageSpec,
                            width: CGFloat,
                            backgroundRenderer : Bool = false,
                            finischedCallback: @escaping((UIImage?)->())){
    print("render image with pixel width: \(width)")
    sharedInstance.enqueueRender(item: item,
                               width: width,
                               backgroundRenderer : backgroundRenderer,
                               finischedCallback: finischedCallback)
  }
  
  public static func render(item:ZoomedPdfImageSpec,
                            height: CGFloat,
                            backgroundRenderer : Bool = false,
                            finischedCallback: @escaping((UIImage?)->())){
    sharedInstance.enqueueRender(item: item,
                               height: height,
                               backgroundRenderer : backgroundRenderer,
                               finischedCallback: finischedCallback)
  }
  
  private func enqueueRender(item:ZoomedPdfImageSpec,
                             scale:CGFloat = 1.0,
                             width: CGFloat? = nil,
                             height: CGFloat? = nil,
                             backgroundRenderer : Bool = false,
                             finischedCallback: (@escaping(UIImage?)->())){
    let queue = backgroundRenderer ? backgroundQueue : userInteractiveQueue
    let semaphore = backgroundRenderer ? backgroundSemaphore : userInteractiveSemaphore
    
    
    queue.async {
      guard let url = item.pdfUrl else {
        finischedCallback(nil)
        return
      }
      guard let index = item.pdfPageIndex else{
        finischedCallback(nil)
        return
      }
      semaphore.wait()
      let pdfPage = PDFDocument(url: url)?.page(at: index)
      ///Check if stopped meanwhile
      if let pdfPage = pdfPage, item.renderingStoped == false {
        var img : UIImage?
        if let w = width {
          img = pdfPage.image(width: w)
        }
        else if let h = height {
          img = pdfPage.image(height: h)
        }
        else {
          img = pdfPage.image(scale:scale)
        }
        finischedCallback(img)
      }
      semaphore.signal()
    }
  }
}

extension PDFPage {
  fileprivate func image(scale: CGFloat = 1.0) -> UIImage? {
    var img: UIImage?
    guard let ref = self.pageRef else { return nil}
    var _frame = self.bounds(for: .mediaBox)
    _frame.size.width *= scale
    _frame.size.height *= scale
    _frame.origin.x = 0
    _frame.origin.y = 0
    if _frame.width > 300 {
      print("TRY TO RENDER IMAGE WITH: \(_frame.size)")
    }
    UIGraphicsBeginImageContext(_frame.size)
    
    if let ctx = UIGraphicsGetCurrentContext() {
      ctx.saveGState()
      UIColor.white.set()
      ctx.fill(_frame)
      ctx.translateBy(x: 0.0, y: _frame.size.height)
      ctx.scaleBy(x: 1.0, y: -1.0)
      ctx.scaleBy(x: scale, y: scale)
      ctx.drawPDFPage(ref)
      img = UIGraphicsGetImageFromCurrentImageContext()
      ctx.restoreGState()
    }
    
    UIGraphicsEndImageContext()
    if _frame.width > 300 {
      print("rendered image width: \(_frame.width) imagesize: \(img?.mbSize ?? 0) MB")
    }
    return img
  }
  
  fileprivate func image(width: CGFloat) -> UIImage? {
    guard let frame = self.frame else { return nil }
    return image(scale:  width/frame.size.width)?.screenScaled()
  }
  
  fileprivate func image(height: CGFloat) -> UIImage? {
    guard let frame = self.frame else { return nil }
    return image(scale:  height/frame.size.height)?.screenScaled()
  }
  
  var frame: CGRect? { self.pageRef?.getBoxRect(.cropBox) }
}

