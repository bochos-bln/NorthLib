//
//  PdfDoc.swift
//
//  Created by Norbert Thies on 08.06.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit
import QuartzCore

/**
 PdfPage is a simple Quartz based class to handle single PDF pages and to convert
 them to images.
 */
open class PdfPage {
  
  /// A single PDF page
  public var page: CGPDFPage
  
  /// The frame of the page's media box - "defines the boundaries of the physical
  ///  medium on which the page is intended to be displayed or printed"
  public var mediaBox: CGRect { page.getBoxRect(.mediaBox) }
  
  /// The frame of the page's crop box - "defines the visible region of default
  ///  user space. When the page is displayed or printed, its contents are to be
  ///   clipped to this rectangle"
  public var frame: CGRect { page.getBoxRect(.cropBox) }
  
  public func image(scale: CGFloat = 1.0, check: (()->(Bool))?) -> UIImage? {
    //Autoreleasepool helps to read debug out, remove it later for tests
    return autoreleasepool { () -> UIImage? in
       
      print(">>>> TRY TO RENDER IMAGE WITH SCALE: \(scale) on MAin? : \(Thread.isMainThread) hasCheckCallback? \(check != nil)")
         var img: UIImage?
         var frame = self.frame
         frame.size.width *= scale
         frame.size.height *= scale
         frame.origin.x = 0
         frame.origin.y = 0
       
         print(">>>> UIGraphicsBeginImageContext WITH SIZE: \(   frame.size)")
      autoreleasepool {
         
      
         UIGraphicsBeginImageContext(frame.size)
        print("lets check!")
        if let chk = check {
          if chk() == true {
            print("prevent mem crash")
            return
          }
        }
         if let ctx = UIGraphicsGetCurrentContext() {
          print("ctx 1")
           ctx.saveGState()
           UIColor.white.set()
          print("ctx 2")
           ctx.fill(frame)
           ctx.translateBy(x: 0.0, y: frame.size.height)
           ctx.scaleBy(x: 1.0, y: -1.0)
          print("ctx 3")
           ctx.scaleBy(x: scale, y: scale)
          print("ctx 3b")
          ctx.endPDFPage()
           ctx.drawPDFPage(page)
          print("ctx 4")
           img = UIGraphicsGetImageFromCurrentImageContext()
         }
         print("ctx end")
         UIGraphicsEndImageContext()
        }
         print(">>>> UIGraphicsEndImageContext WITH SIZE: \(   frame.size)")
         print(">>>>++++++ Rendered PDF Image Size: \(img?.size ?? CGSize.zero)")
         return img
 
    }
    
    
    
   
  }
  
  public func image(width: CGFloat, check: (()->(Bool))?) -> UIImage? {
    let frame = self.frame
    return image(scale:  UIScreen.main.scale * width/frame.size.width, check: check)?.screenScaled()
  }
  
  public func image(height: CGFloat, check: (()->(Bool))?) -> UIImage? {
    let frame = self.frame
    return image(scale:  UIScreen.main.scale * height/frame.size.height, check: check)?.screenScaled()
  }
  
  fileprivate init(page: CGPDFPage) { self.page = page }
}


/**
 PdfDoc is a simple Quartz based class to open PDF documents and to convert
 them to an Image.
 */
open class PdfDoc {
  
  /// The document
  public var doc: CGPDFDocument?  
  
  private var _fname: String?
  /// The file name of a PDF document
  public var fname: String? {
    get { return _fname }
    set {
      _fname = newValue
      if let fn = _fname {
        doc = CGPDFDocument(URL.init(fileURLWithPath: fn) as CFURL)
      } else { doc = nil }
    }
  }
  
  /// Number of pages in document
  public var count: Int { doc!.numberOfPages }
  
  /// PdfDoc[n] returns the n'th page (0<=n)
  public subscript(n: Int) -> PdfPage? {
    if let doc = self.doc, 
       n < count,
       let pg = doc.page(at: n+1) { 
      return PdfPage(page: pg)
    }
    else { return nil }
  }
  
  /// Init with raw PDF data
  public init(data: Data) {
    doc = CGPDFDocument(CGDataProvider(data: data as CFData)!)
  }
  
  /// Init with file name (path)
  public init(fname: String) {
    self.fname = fname
  }
  
}
