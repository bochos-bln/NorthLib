//
//  OptionalImage.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 06.11.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import PDFKit




// MARK: - ZoomedPdfImageSpec : OptionalImage (Protocol)
public protocol ZoomedPdfImageSpec : OptionalImage, DoesLog {
  var sectionTitle: String? { get set}
  var pageTitle: String? { get set}
  var pdfUrl: URL? { get }
  var pdfPageIndex: Int? { get }
  var renderingStoped: Bool { get }
  var preventNextRenderingDueFailed: Bool { get }
  var nextZoomStep: CGFloat { get }
  
  var canRequestHighResImg: Bool { get }
  var nextRenderingZoomScale: CGFloat { get }
  
  func renderImageWithNextScale(finishedCallback: ((Bool) -> ())?)
  func renderFullscreenImageIfNeeded(finishedCallback: ((Bool) -> ())?)
  func renderImageWithScale(scale: CGFloat, finishedCallback: ((Bool) -> ())?)
}

extension ZoomedPdfImageSpec{
  public var canRequestHighResImg: Bool {
    get {
      if preventNextRenderingDueFailed { return false }
      log("canRequestHighResImg: \(nextRenderingZoomScale <= PdfDisplayOptions.Page.maxRenderingZoom) nextRenderingZoomScale \(nextRenderingZoomScale) <= \(PdfDisplayOptions.Page.maxRenderingZoom) PdfDisplayOptions.Page.maxRenderingZoom")
      return nextRenderingZoomScale <= PdfDisplayOptions.Page.maxRenderingZoom
    }
  }
  
  public func renderImageWithNextScale(finishedCallback: ((Bool) -> ())?){
    log("Optional Image, renderImageWithNextScale: \(self.nextRenderingZoomScale) current:\((image?.size.width ?? 0)/UIScreen.main.nativeBounds.width) nextRenderingZoomScale: \(nextRenderingZoomScale)")
    renderImageWithScale(scale: self.nextRenderingZoomScale, finishedCallback:finishedCallback)
  }
}

public class ZoomedPdfImage: OptionalImageItem, ZoomedPdfImageSpec {
  public var preventNextRenderingDueFailed: Bool = false
  
  public var sectionTitle: String?
  public var pageTitle: String?
  public private(set) var pdfUrl: URL?
  public private(set) var pdfPageIndex: Int?
  
  convenience init(url:URL?, index:Int) {
    self.init()
    self.pdfUrl = url
    self.pdfPageIndex = index
  }
    
  var calculatedNextScreenZoomScale: CGFloat?
  
  public var nextRenderingZoomScale: CGFloat {
    get{
      if calculatedNextScreenZoomScale == nil {
        calculatedNextScreenZoomScale = calculateNextScreenZoomScale
      }
      return calculatedNextScreenZoomScale!
    }
  }
  
  public override weak var image: UIImage? {
    didSet{
      calculatedNextScreenZoomScale = nil
      preventNextRenderingDueFailed = false
    }
  }
  
  //want screen zoom scales 1, 4, 8, 12...
  
  var calculateNextScreenZoomScale: CGFloat {
    get{
      guard let img = self.image else { return 1.0 }
      let currentScale = img.size.width/UIScreen.main.nativeBounds.width
      #warning("TODO @Ringo MATH+KISS")
      switch currentScale {
        case _ where currentScale <= 1.0:
          return 3.0
        case _ where currentScale <= 3.0:
          return 6.0//wrong fpr iPad!!!
        default:
          return PdfDisplayOptions.Page.maxRenderingZoom
      }
    }
  }
  #warning("TODO @Ringo MATH+KISS")
  /**
  iPad need other zoom steps
   iPad 1x 2x 4/5x
   iPhone 1x 3x 6x
  
  
   */
  ///returns the next zoom step ratio from current zoom step e.g. for scrollview to calculate how deep to zoom
  public var nextZoomStep: CGFloat {
    get {
      ///Usually a ratio between current and next but issues with division by 0 and expensive cals use simple switch
      /// Expect 3,6,max == 8
      if nextRenderingZoomScale == 3.0 { return 3.0 }
      else if nextRenderingZoomScale == PdfDisplayOptions.Page.maxRenderingZoom {
        return PdfDisplayOptions.Page.maxRenderingZoom/3.0
      }
      return 2.0
    }
  }
  
  public var renderingStoped = false
  
  public private(set) var pageDescription: String = ""
    
  public func renderFullscreenImageIfNeeded(finishedCallback: ((Bool) -> ())?) {
    self.renderImageWithScale(scale:1.0, finishedCallback: finishedCallback)
  }
  
  public func renderImageWithScale(scale: CGFloat, finishedCallback: ((Bool) -> ())?) {
    //Prevent Multiple time max rendering
    if scale > PdfDisplayOptions.Page.maxRenderingZoom {
      return
    }
    let baseWidth = UIScreen.main.bounds.width*UIScreen.main.scale
    log("Optional Image, render Image with scale: \(scale) is width: \(baseWidth*scale) 1:1 image width should be: \(baseWidth)")
    PdfRenderService.render(item: self,
                            width: baseWidth*scale) { img in
      onMain { [weak self] in
        guard let self = self else { return }
        self.log("Optional Image, render Image with scale done rendered?: \(img != nil)")
        self.preventNextRenderingDueFailed = img == nil
        guard let newImage = img else { finishedCallback?(false); return }
        if self.renderingStoped { return }
        self.image = newImage
        finishedCallback?(true)
      }
    }
  }
  
  public func stopRendering(){
    self.renderingStoped = true
    self.image = nil
   
  }
  
  //Device Types: iPhone, iPad
  /**
    iPhone: (personal categorization) What about Screen Scales
      small: iPhone 5+, SE1
      medium 6s, 7, 8, 12mini
      large: 6s+, 7+, 8+, X, XS, 11, 11Pro, XR, SE2, 12, 12Pro
      extra large: XSMax, 11 Pro Max, 12 Pro Max
    iPad:
      Mini 2-5 (7,9")
      iPad 5-8th (9,7"-10,2")
      Air 1-4 (9,7 / 10,5 / 10,9")
      Pro 1.-4. Gen (9,7 / 11" / 12,9")
    iPad Problematic
      - older iPads have less CPU Power and smaller RAM => Max Zoom is Limited
        => Limit scould be handled by 40% RAM Usage of Render Function
          @see: PdfRenderService.swift => extension PDFPage => image/avoidRenderDueExpectedMemoryIssue
        => so i can use higher zoom scales
      - diffferent screen Scales let UserExperiance may be different e.g. difference between iPad and iPhone 5s
      - different Padges with different Layout e.g. 2 Column vs. 6 Column make double Tap & Zoom difficult
      - But User expects every time same depth
      - is Double Tap 1 Level enought?  Problem User zoomed in 2nd Time he cannot go back to 1st Step by Double Tap
      => Solutions
        => Create Model wich allows more than 2 Presets
        => may create own DSL
        => structure needs Step 0 == 1:1, ...
        => getter for next/prev/max
        => bool if last render failed, and was higher than 1.0
      ....Lets GO!
   */
}


/**
 
 
 Good Idea but What about RealLife?
  Where is the Page base Resolution NEEDED?
  Where is the current SCale memory? NEEDED?
 
 */
public struct ZoomScales {
  public enum ZoomScaleType  {case iPhone, iPad}
  
  struct Steps {
    static let iPad:[CGFloat] = [1,2,4,6,8]
    static let iPhone:[CGFloat] = [1,3,7]
  }
  
  var steps:[CGFloat]
  public private(set) var type : ZoomScaleType
  
  public init(_ type : ZoomScaleType = .iPhone){
    self.type = type
    switch type {
      case .iPhone:
        steps = Steps.iPhone
      case .iPad:
        steps = Steps.iPad
    }
  }
  
  
  public var currentScreenScale : CGFloat = 0
  
  //NEEDED?
  public var nextScreenScale : CGFloat {
    get {
      return 2.0
    }
  }
  
}
