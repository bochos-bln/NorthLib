//
//  PdfViewController.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// Provides functionallity to interact between PdfOverviewCollectionVC and Pages with PdfPagesCollectionVC
open class PdfViewController : UIViewController, CanRotate{
  public private(set) var thumbnailController : PdfOverviewCollectionVC?
  public private(set) var pageController : PdfPagesCollectionVC?
  public private(set) var overlay : Overlay?
  var pdfModel : PdfModel? = PdfModelItem(url: PdfModelHelper.demoDocUrl())
  
  public init() {
    guard let pdfModel = pdfModel else { fatalError("init() pdfModel is nil cannot show something usefull") }
    Log.minLogLevel = .Debug
    thumbnailController = PdfOverviewCollectionVC(pdfModel:pdfModel)
    pageController = PdfPagesCollectionVC(data: pdfModel)
    super.init(nibName: nil, bundle: nil)
    guard let detailController = pageController else {return }
    overlay = Overlay(overlay:detailController , into: self)
    overlay?.closeRatio = 0.8//Fix ScrollView e.g. ZoomedImageView in ScrollView close Ratio Issue
    overlay?.onRequestUpdatedCloseFrame(closure: { [weak self] in
      guard let self = self else { return nil}
      return self.thumbnailController?.frameAtIndex(index: self.pageController?.index ?? 0)
    })
    
    detailController.onX { [weak self] in
      guard let self = self else { return}
      self.overlay?.close(animated: true)
      self.log("All Images current Size: \(pdfModel.imageSizeMb) MB", logLevel: .Debug)
    }
  }
  
  #warning ("@Ringo: Memory Leaks fixed remove unused Code @20-11-19")
  deinit {
//    print("SUCCESSFULL DEINIT PdfViewController")
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isBeingDismissed {
      print("cleanup")
      ///Cleanup
      for ctrl in self.children {
        ctrl.removeFromParent()
      }
      pageController?.menu.menu = []
      pageController?.onX {}
      pageController?.pdfModel = nil
      pageController?.images = []
      pageController?.collectionView = nil
      thumbnailController?.clickCallback = nil
      thumbnailController?.pdfModel = nil
      thumbnailController = nil
      overlay?.onRequestUpdatedCloseFrame(closure: nil)
      pageController = nil
      overlay = nil
      pdfModel = nil
    }
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    guard let thumbnailController = thumbnailController else {return }
    thumbnailController.clickCallback = { [weak self] (sourceFrame, pdfModel) in
      guard let self = self else { return }
      guard let overlay = self.overlay else { return }
      self.pageController?.pdfModel = pdfModel
      overlay.openAnimated(fromFrame: sourceFrame, toFrame: self.pageController?.view.frame ?? CGRect.zero)
    }
    
    self.view.addSubview(thumbnailController.view)
    pin(thumbnailController.view, to: self.view)
    
    self.overlay?.maxAlpha = 0.9
    self.overlay?.open(animated: false, fromBottom: false)
    self.overlay?.setCloseActionToShrink() //Fix where to close to
  }
  
}
