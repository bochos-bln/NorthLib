//
//  PdfViewController.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// Provides functionallity to interact between PdfOverviewCollectionVC and Pages with PdfPagesCollectionVC
public class PdfViewController : UIViewController, CanRotate{
  var thumbnailController : PdfOverviewCollectionVC?
  var pageController : PdfPagesCollectionVC?
  var overlay : Overlay?
  var pdfModel : PdfModel? = PdfModelItem(url: PdfModelHelper.demoDocUrl())
  
  public init() {
    guard let pdfModel = pdfModel else { fatalError("init() pdfModel is nil cannot show something usefull") }
    Log.minLogLevel = .Debug
    thumbnailController = PdfOverviewCollectionVC(pdfModel:pdfModel)
    pageController = PdfPagesCollectionVC(data: pdfModel)
    super.init(nibName: nil, bundle: nil)
    guard let detailController = pageController else {return }
    overlay = Overlay(overlay:detailController , into: self)
    overlay?.onRequestUpdatedCloseFrame(closure: { [weak self] in
      guard let self = self else { return nil}
      return self.thumbnailController?.frameAtIndex(index: self.pageController?.index ?? 0)
    })
    
    detailController.onX { [weak self] in
      self?.log("All Images current Size: \(pdfModel.imageSizeMb) MB", logLevel: .Debug)
    }

    return;
      
    detailController.onX { [weak self] in
      guard let self = self else { return}
      self.overlay?.close(animated: true)
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    guard let thumbnailController = thumbnailController else {return }
    thumbnailController.clickCallback = { [weak self] (sourceFrame, pdfModel) in
      guard let self = self else { return }
      guard let overlay = self.overlay else { return }
      self.pageController?.data = pdfModel
      overlay.openAnimated(fromFrame: sourceFrame, toFrame: self.pageController?.view.frame ?? CGRect.zero)
    }
    
    self.addChild(thumbnailController)
    self.view.addSubview(thumbnailController.view)
    pin(thumbnailController.view, to: self.view)
    thumbnailController.didMove(toParent: self)

    
    self.overlay?.maxAlpha = 0.9
    self.overlay?.open(animated: false, fromBottom: false)
    self.overlay?.setCloseActionToShrink() //Fix where to close to
  }
  
}
