//
//  PdfPagesCollectionVC.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

//PagePDFVC array von pages mit Image und page
/// Provides functionallity to view, zoom in PDF Pages. Swipe on Side Corner shows next/prev Page if available
public class PdfPagesCollectionVC : ImageCollectionVC, CanRotate{
  
  public var menuItems: [(title: String, icon: String, closure: (String)->())] = [] {
    didSet {
      var newItems = menuItems
      newItems.insert((title: "Zoom 1:1", icon: "1.magnifyingglass", closure: { [weak self] _ in
        if let ziv = self?.currentView as? ZoomedImageView  {
          ziv.scrollView.setZoomScale(1.0, animated: true)
        }
      }), at: 0)
      menu.menu = newItems
    }
  }
  
  lazy var menu = ContextMenu(view: view)
    
  var pdfModel : PdfModel? {
    didSet{
      updateData()
    }
  }
  
  func updateData(){
    guard let model = pdfModel else { return }
    self.index = model.index
    super.count = model.count
    self.collectionView?.reloadData()
  }
  
  init(data:PdfModel) {
    self.pdfModel = data
    super.init()
    updateData()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    #warning("TODO @Ringo on Menu appear white bg appears, set .clear did not work @NThies Ideas? in Caroussel this did not appear!")
    self.collectionView?.backgroundColor = .clear//UIColor(white: 1.0, alpha: 0.95)//TODO::DARKMODE!
    self.pageControlMaxDotsCount = Device.singleton == .iPad ? 25 : 9
    self.pageControl?.layer.shadowColor = UIColor.lightGray.cgColor
    self.pageControl?.layer.shadowRadius = 3.0
    self.pageControl?.layer.shadowOffset = CGSize(width: 0, height: 0)
    self.pageControl?.layer.shadowOpacity = 1.0
    self.pageControl?.pageIndicatorTintColor = UIColor.white
    self.pageControl?.currentPageIndicatorTintColor = UIColor.red//Const.SetColor.CIColor.color
    self.pinBottomToSafeArea = false
  }
  
  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    //Fix Issue iPad: rotation page is missalligned
    //simple soloution due rotation animation is much longer
    //worked on iPad Air 2
    if let ziv = self.currentView as? ZoomedImageViewSpec {
      onMainAfter(0.3) {
        ziv.invalidateLayout()
      }
    }
  }
  
  public override func didReceiveMemoryWarning() {
    print("☠️☠️☠️\nRECIVE MEMORY WARNING\n☠️☠️☠️☠️\nPdfPagesCollectionVC->didReceiveMemoryWarning\n   ")
  }

  public override func setupViewProvider(){
    viewProvider { [weak self] (index, oview) in
      guard let self = self else { return UIView() }
      let dataItem = self.pdfModel?.item(atIndex: index)
      if let ziv = oview as? ZoomedImageView {
        ziv.optionalImage = dataItem
        dataItem?.renderFullscreenImageIfNeeded(finishedCallback: nil)
        return ziv
      }
      else {
        let ziv = ZoomedImageView(optionalImage: dataItem)
        ziv.backgroundColor = .clear
        ziv.scrollView.backgroundColor = .clear //.red/black work .clear not WTF
        ziv.onTap { [weak self] (oimg, x, y) in
          guard let self = self else { return }
          self.zoomedImageViewTapped(oimg, x, y)
        }
        ziv.onHighResImgNeeded(zoomFactor: 1.1) { (optionalImage, finishedCallback) in
          guard let oPdfImg = optionalImage as? ZoomedPdfImageSpec else { return }
          oPdfImg.renderImageWithNextScale(finishedCallback:finishedCallback)
        }
        dataItem?.renderFullscreenImageIfNeeded(finishedCallback: nil)
        return ziv
      }
    }
    
    onEndDisplayCell { (_, optionalView) in
      guard let ziv = optionalView as? ZoomedImageView,
            let _pdfImg = ziv.optionalImage as? ZoomedPdfImageSpec else { return }
//      print(">> END DISPLAY \(ziv.hashValue)")
      var pdfImg = _pdfImg
      if ziv.imageView.image == pdfImg.image {
//        print(">> END DISPLAY \(ziv.hashValue) set Images nil for pdf idx: \(pdfImg.pdfPageIndex)")
        pdfImg.image = nil
        ziv.imageView.image = nil
      }
    }
    
    onDisplay { (_, optionalView) in
      guard let ziv = optionalView as? ZoomedImageView,
            let pdfImg = ziv.optionalImage as? ZoomedPdfImageSpec else { return }
//      print(">> START DISPLAY \(ziv.hashValue)")
      if ziv.imageView.image == nil
//          || ziv.imageView.image != pdfImg.image
      {
        ziv.optionalImage = pdfImg
        
        if pdfImg.image == nil {
          pdfImg.renderFullscreenImageIfNeeded(finishedCallback: nil)
        }
        //!= nil // Waiting Image????
        ziv.imageView.image = pdfImg.image
        pdfImg.renderFullscreenImageIfNeeded(finishedCallback: nil)
//        print(">> START DISPLAY \(ziv.hashValue) set Image for pdf idx: \(pdfImg.pdfPageIndex)")
      }
    }
  }
  
}