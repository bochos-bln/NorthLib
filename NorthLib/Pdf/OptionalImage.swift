//
//  OptionalImage.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 06.11.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import PDFKit

struct ZoomedPdfImageSpecConstants {
  static let maxRenderingZoom:CGFloat = 8.0
}


// MARK: - ZoomedPdfImageSpec : OptionalImage (Protocol)
public protocol ZoomedPdfImageSpec : OptionalImage {
  var pdfUrl: URL? { get }
  var pdfPageIndex: Int? { get }
  var renderingStoped: Bool { get }
  
  var canRequestHighResImg: Bool { get }
  var nextRenderingZoomScale: CGFloat { get }
  
  func renderImageWithNextScale()
  func renderFullscreenImageIfNeeded()
  func renderImageWithScale(scale: CGFloat)
}

extension ZoomedPdfImageSpec{
  public var canRequestHighResImg: Bool {
    get {
      return nextRenderingZoomScale <= ZoomedPdfImageSpecConstants.maxRenderingZoom
    }
  }
  
  public var nextRenderingZoomScale: CGFloat {
    get {
      guard let img = image else {
        ///if there is no image yet, generate the Image within minimum needed scale
        return 1.0
      }
      return 2*img.size.width/UIScreen.main.nativeBounds.width
    }
  }
  
  public func renderImageWithNextScale(){
    renderImageWithScale(scale: self.nextRenderingZoomScale)
  }
}

public class ZoomedPdfImage: OptionalImageItem, ZoomedPdfImageSpec {
 
  public private(set) var pdfUrl: URL?
  public private(set) var pdfPageIndex: Int?
  public private(set) var currentScreenZoomScale : CGFloat = 1.0
  
  convenience init(url:URL?, index:Int) {
    self.init()
    self.pdfUrl = url
    self.pdfPageIndex = index
  }
  
  //want screen zoom scales 1, 4, 8, 12...
  public var calculateNextScreenZoomScale: CGFloat {
    get{
      switch currentScreenZoomScale {
        case _ where currentScreenZoomScale <= 1.0:
          return 3.0
        case _ where currentScreenZoomScale <= 3.0:
          return 6.0
        default:
          return ZoomedPdfImageSpecConstants.maxRenderingZoom
      }
    }
  }
  
  public var renderingStoped = false
  
  public private(set) var pageDescription: String = ""
  
  var calculatedNextScreenZoomScale: CGFloat?
  
  public var nextScreenZoomScale: CGFloat {
    get{
      if calculatedNextScreenZoomScale == nil {
        calculatedNextScreenZoomScale = calculateNextScreenZoomScale
      }
      return calculatedNextScreenZoomScale!
    }
  }
  
  public override weak var image: UIImage? {
    didSet{
      print("ZoomedPdfImage image set at \(calculatedNextScreenZoomScale ?? 0)x")
      calculatedNextScreenZoomScale = nil
    }
  }
  
  public func renderFullscreenImageIfNeeded() {
    self.renderImageWithScale(scale:1.0)
  }
  
  public func renderImageWithScale(scale: CGFloat) {
    //Prevent Multiple time max rendering
    if scale > ZoomedPdfImageSpecConstants.maxRenderingZoom {
      return
    }
    PdfRenderService.render(item: self,
                            width: UIScreen.main.nativeBounds.width*scale) { img in
      onMain { [weak self] in
        guard let self = self else { return }
        guard let newImage = img else { return }
        if self.renderingStoped { return }
        self.image = newImage
      }
    }
  }
  
  public func stopRendering(){
    self.renderingStoped = true
    self.image = nil
  }
  
  
}
