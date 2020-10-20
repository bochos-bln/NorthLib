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
  
  //Pass context not needed due context cannot be stopped
  //  check does mem warning occoured due draw not working in all cases sometimes mem warning just came in ctx.drawPDFPage(page)
  //autorealeasepools did not work also (untill ios 13.6) need test ioS 14 with its prevent out of mem rendering concept
  //Good news: ios 13.7 & iOS 14 wount crash on excessive memory usage, so workaround only needed for lower versions
  public func image(scale: CGFloat = 1.0, passContext: ((CGContext)->())?) -> UIImage? {
     //Autoreleasepool helps to read debug out, remove it later for tests
     return autoreleasepool { () -> UIImage? in
//      let maxMemMb = 650.0/2.3
      let maxMemMb:CGFloat = CGFloat(ProcessInfo.processInfo.physicalMemory)/(1024.0*1024.0*5.3)
      let maxZomSqrt:CGFloat = CGFloat((1024.0*256.0*maxMemMb))/(self.frame.size.width * self.frame.size.height)
    let maxZoom = (sqrt(maxZomSqrt)*10).rounded()/10
      
    
      
    print(">>> ++ Max Zoom for RamUsage of: \(maxMemMb)MB is: \(maxZoom)x")
        var scale = scale
//      if scale > maxZoom {
//        scale = maxZoom
//    }
    /*** IP XS Max iOS 13.6
     CRASH
     >> RAM available: 1643 used: 723 total: 3751
     >>>> TRY TO RENDER IMAGE WITH SCALE: 16.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 1162.0 MB
          0.7
     
     >>> RAM available: 1080 used: 723 total: 3751
     >>>> TRY TO RENDER IMAGE WITH SCALE: 15.5 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 1090.0 MB
     
     >>> RAM available: 1037 used: 723 total: 3751
     >>>> TRY TO RENDER IMAGE WITH SCALE: 15.5 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 1090.0 MB
     
      OK
     RAM available: 1047 used: 723 total: 3751
     >>>> TRY TO RENDER IMAGE WITH SCALE: 15.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 1021.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (13394.0, 19984.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (13394.0, 19984.0)
     >>>>++++++ Rendered PDF Image Size: (13394.0, 19984.0)
     >>>> Image Size: 1021 MB
     */
    
    /*** IP 5s Max iOS 12.X
     CRASH
     >>> RAM available: 111 used: 19 total: 1000
     >>>> TRY TO RENDER IMAGE WITH SCALE: 5.58125 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 141.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (4984.0, 7436.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (4984.0, 7436.0)
     >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
     >>>> Image Size: 141 MB
     >>> RAM available: 294 used: 21 total: 1000
     >>>> TRY TO RENDER IMAGE WITH SCALE: 15.5 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 1090.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (13840.0, 20650.0)

     
     >>>>++++++ Rendered PDF Image Size: (1280.0, 1910.0)
     >>> RAM available: 391 used: 18 total: 1000
     >>>> TRY TO RENDER IMAGE WITH SCALE: 2.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 18.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (1786.0, 2665.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (1786.0, 2665.0)
     >>>>++++++ Rendered PDF Image Size: (1786.0, 2665.0)
     >>>> Image Size: 18 MB
     >>> RAM available: 366 used: 19 total: 1000
     >>>> TRY TO RENDER IMAGE WITH SCALE: 5.58125 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 141.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (4984.0, 7436.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (4984.0, 7436.0)
     >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
     >>>> Image Size: 141 MB
     >>> RAM available: 206 used: 21 total: 1000
     >>>> TRY TO RENDER IMAGE WITH SCALE: 12.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 653.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (10715.0, 15987.0)
     
     !!! ;:-)  EXC_RESOURCE RESOURCE_TYPE_MEMORY (limit=650 MB, unused=0x0)
       https://stackoverflow.com/questions/5887248/ios-app-maximum-memory-budget
       Lowest is iPhone X with 50%of 2785MB
       Lets calc the max Zoom Factor!
       Total RAM: ProcessInfo.processInfo.physicalMemory/(1024*1024)
       Max RAM: ProcessInfo.processInfo.physicalMemory/(1024*1024)*0.5 / 2.4 Max useable
       Max RAM: ProcessInfo.processInfo.physicalMemory/(1024*1024) * 1/5 Max useable
       Max ImgSize: ProcessInfo.processInfo.physicalMemory/(1024*1024*5)
       
       
       
     >>> ++ Max Zoom for RamUsage of: 300.0MB is: 8.130706067004093x
     >>>> TRY TO RENDER IMAGE WITH SCALE: 2.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 18.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (1786.0, 2665.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (1786.0, 2665.0)
     >>>>++++++ Rendered PDF Image Size: (1786.0, 2665.0)
     >>>> Image Size: 18 MB
     >>> RAM available: 282 used: 19 total: 1000
     >>> ++ Max Zoom for RamUsage of: 300.0MB is: 8.130706067004093x
     >>>> TRY TO RENDER IMAGE WITH SCALE: 5.58125 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 141.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (4984.0, 7436.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (4984.0, 7436.0)
     >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
     >>>> Image Size: 141 MB
     >>> RAM available: 200 used: 21 total: 1000
     >>> ++ Max Zoom for RamUsage of: 300.0MB is: 8.130706067004093x
     >>>> TRY TO RENDER IMAGE WITH SCALE: 12.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 653.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (10715.0, 15987.0)
     
     
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 2.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 18.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (1786.0, 2665.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (1786.0, 2665.0)
     >>>>++++++ Rendered PDF Image Size: (1786.0, 2665.0)
     >>>> Image Size: 18 MB
     >>> RAM available: 348 used: 37 total: 1000
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 5.58125 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 141.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (4984.0, 7436.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (4984.0, 7436.0)
     >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
     >>>> Image Size: 141 MB
     >>> RAM available: 210 used: 21 total: 1000
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 12.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 653.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (10715.0, 15987.0)
     
     
     >>> RAM available: 379 used: 19 total: 1000
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 5.58125 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 141.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (4984.0, 7436.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (4984.0, 7436.0)
     >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
     >>>> Image Size: 141 MB
     >>> RAM available: 172 used: 19 total: 1000
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 11.5 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 600.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (10268.0, 15321.0)
     
     
     >>> RAM available: 266 used: 19 total: 1000
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 5.58125 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 141.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (4984.0, 7436.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (4984.0, 7436.0)
     >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
     >>>> Image Size: 141 MB
     >>> RAM available: 227 used: 21 total: 1000
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 10.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 454.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (8929.0, 13323.0)
     
     >>>> Image Size: 18 MB
     >>> RAM available: 276 used: 37 total: 1000
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 5.58125 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 141.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (4984.0, 7436.0)
     >>>> UIGraphicsEndImageContext WITH SIZE: (4984.0, 7436.0)
     >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
     >>>> Image Size: 141 MB
     >>> RAM available: 171 used: 21 total: 1000
     >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
     >>>>> TRY TO RENDER IMAGE WITH SCALE: 8.0 on MAin? : false haspassContextCallback? true
     >>>> Expect Mem Usage: 290.0 MB
     >>>> UIGraphicsBeginImageContext WITH SIZE: (7143.0, 10658.0)
     >>> xxxx WARNING RECIVE MEM WARNING!!!!!
     >>> RAM available: 188 used: 598 total: 1000
     >>> xxxx WARNING RECIVE MEM WARNING!!!!!
     >>> RAM available: 228 used: 612 total: 1000
     
       
       >>> RAM available: 246 used: 21 total: 1000
       >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
       >>>>> TRY TO RENDER IMAGE WITH SCALE: 8.0 on MAin? : false haspassContextCallback? true
       >>>> Expect Mem Usage: 290.0 MB
       >>>> UIGraphicsBeginImageContext WITH SIZE: (7143.0, 10658.0)
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 192 used: 598 total: 1000
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 207 used: 627 total: 1000
       
       ENABLE AUTORELEASEPOOLS MAKES NO DIFFERENCE!
       >>> RAM available: 206 used: 21 total: 1000
       >>> ++ Max Zoom for RamUsage of: 650.0MB is: 11.968075276363525x
       >>>>> TRY TO RENDER IMAGE WITH SCALE: 8.0 on MAin? : false haspassContextCallback? true
       >>>> Expect Mem Usage arp: 290.0 MB
       >>>> UIGraphicsBeginImageContext WITH SIZE: (7143.0, 10658.0)
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 137 used: 599 total: 1000
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       
       
       FRAGEN: Wieso steigt der Mem Footprint auf 650MB mit AUTORELEASEPOOLS
       
       
       
       >>>> Image Size: 18 MB
       >>> AfterRender RAM available: 287 used: 56 total: 1000
       >>> RAM available: 272 used: 19 total: 1000
       >>> ++ Max Zoom for RamUsage of: 200.0MB is: 7.0x
       >>>>> TRY TO RENDER IMAGE WITH SCALE: 5.58125 on MAin? : false haspassContextCallback? true
       >>>> Expect Mem Usage arp: 141.0 *2.3: 324.29999999999995 MB
       >>>> UIGraphicsBeginImageContext WITH SIZE: (4984.0, 7436.0)
       >>>> UIGraphicsEndImageContext WITH SIZE: (4984.0, 7436.0)
       >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
       >>>> Image Size: 141 MB
       >>> AfterRender RAM available: 324 used: 304 total: 1000
       >>> RAM available: 220 used: 101 total: 1000
       >>> ++ Max Zoom for RamUsage of: 200.0MB is: 7.0x
       >>>>> TRY TO RENDER IMAGE WITH SCALE: 7.0 on MAin? : false haspassContextCallback? true
       >>>> Expect Mem Usage arp: 222.0 *2.3: 510.59999999999997 MB
       >>>> UIGraphicsBeginImageContext WITH SIZE: (6250.0, 9326.0)
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 173 used: 601 total: 1000
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
     
       
       OK:
       
       >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
       >>>> Image Size: 141 MB
       >>> AfterRender RAM available: 307 used: 304 total: 1000
       >>> RAM available: 303 used: 305 total: 1000
       >>> ++ Max Zoom for RamUsage of: 196.07843137254903MB is: 6.6x
       >>>>> TRY TO RENDER IMAGE WITH SCALE: 6.6 on MAin? : false haspassContextCallback? true
       >>>> Expect Mem Usage arp: 198.0 *2.3: 455.4 MB
       >>>> UIGraphicsBeginImageContext WITH SIZE: (5893.0, 8793.0)
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 157 used: 603 total: 1000
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 258 used: 417 total: 1000
       >>>> UIGraphicsEndImageContext WITH SIZE: (5893.0, 8793.0)
       >>>>++++++ Rendered PDF Image Size: (5893.0, 8793.0)
       >>>> Image Size: 197 MB
       >>> AfterRender RAM available: 369 used: 417 total: 1000
       
       Perfekt:
       
       >>>>++++++ Rendered PDF Image Size: (4984.0, 7436.0)
       >>>> Image Size: 141 MB
       >>> AfterRender RAM available: 273 used: 304 total: 1000
       >>> RAM available: 157 used: 21 total: 1000
       >>> ++ Max Zoom for RamUsage of: 196.07843137254903MB is: 6.6x
       >>>>> TRY TO RENDER IMAGE WITH SCALE: 6.6 on MAin? : false haspassContextCallback? true
       >>>> Expect Mem Usage arp: 198.0 *2.3: 455.4 MB
       >>>> UIGraphicsBeginImageContext WITH SIZE: (5893.0, 8793.0)
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 254 used: 417 total: 1000
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 257 used: 417 total: 1000
       >>>> UIGraphicsEndImageContext WITH SIZE: (5893.0, 8793.0)
       >>>>++++++ Rendered PDF Image Size: (5893.0, 8793.0)
       >>>> Image Size: 197 MB
       >>> AfterRender RAM available: 327 used: 417 total: 1000
       
       Looked good then Fail:
       iPhone XS Max with 3,7GB Ram
       
       n-1 Render @11.7x OK
       nth Render with Max of 12.5x Crash
       Readon 11.7 used too much memory then render max crashed
       
       Solutions Zoom Levels:
       1 / 3x /  6x / max
       1 / 2x /  4x / 8x / 16x XX  / max
       1 /  4x / 8x / 16x XX  / max
       1 bekannt
        max bekannt 1.....32
       
       render 1x 2x 4x 16x = zoom
       wenn zoom 80% von max zoom => zoom = max zoom
       
       
       
       >>> AfterRender RAM available: 1250 used: 1815 total: 3751
       NextRendering ZoomScale: 20.130434782608695 = 12501.0 / 1242.0
       NextRendering ZoomScale: 20.130434782608695 = 12501.0 / 1242.0
       >>> RAM available: 896 used: 1815 total: 3751
       >>> ++ Max Zoom for RamUsage of: 707.7977594339623MB is: 12.5x
       >>>>> TRY TO RENDER IMAGE WITH SCALE: 14.0 on MAin? : false haspassContextCallback? true
       >>>> Expect Mem Usage arp: 889.0 *2.3: 2044.6999999999998 MB
       >>>> UIGraphicsBeginImageContext WITH SIZE: (12501.0, 18652.0)
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       >>> RAM available: 718 used: 1993 total: 3751
       >>> xxxx WARNING RECIVE MEM WARNING!!!!!
       
       
     **/
    
  
    
       print(">>>>> TRY TO RENDER IMAGE WITH SCALE: \(scale) on MAin? : \(Thread.isMainThread) haspassContextCallback? \(passContext != nil)")
          var img: UIImage?
          var frame = self.frame
    frame.size.width = (frame.size.width * scale).rounded()
    frame.size.height = (frame.size.height * scale).rounded()
          frame.origin.x = 0
          frame.origin.y = 0
      let mem:CGFloat = (frame.size.width*frame.size.height*4/(1024*1024)).rounded()
    
      print(">>>> Expect Mem Usage arp: \(mem) *2.3: \(mem*2.3) MB")
          print(">>>> UIGraphicsBeginImageContext WITH SIZE: \(   frame.size)")
       autoreleasepool {
          UIGraphicsBeginImageContext(frame.size)
         print("lets check!")
          if let ctx = UIGraphicsGetCurrentContext() {
            if let passCtx = passContext {
              passCtx(ctx)
            }
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
            ctx.drawPDFPage(page)
           print("ctx 4")
            img = UIGraphicsGetImageFromCurrentImageContext()
          }
          print("ctx end")
          UIGraphicsEndImageContext()
         }
          print(">>>> UIGraphicsEndImageContext WITH SIZE: \(   frame.size)")
          print(">>>>++++++ Rendered PDF Image Size: \(img?.size ?? CGSize.zero)")
    if let cimg = img?.cgImage {
      print("Release cg image")
//        CGImageRelease(cimg)//CGImageRelease' is unavailable: Core Foundation objects are automatically memory manag
    }
    print(">>>> Image Size: \(img?.mbSize ?? 0) MB")
      
      let imgData = img?.jpegData(compressionQuality: 1.0)
      print("JPG Image Size: \(imgData!.count/(1024*1024)) MB")
      
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

extension UIImage {
  var mbSize: UInt64{
    guard let cgimg = self.cgImage else { return 0}
    return UInt64((cgimg.height * cgimg.bytesPerRow)/(1024*1024));
  }
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
