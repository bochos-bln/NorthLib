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
  
  /// Light status bar because of black background TBD at Zoom in the white Newspaper is in bg on zoom out the black bg
  /// Simple solution => white BG!
  ///  darkmode lightMode depending
  override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
  
  public var menuItems: [(title: String, icon: String, closure: (String)->())] = [] {
    didSet {
      var newItems = menuItems
      newItems += (title: "Zoom 1:1", icon: "1.magnifyingglass", closure: { [weak self] _ in
        if let ziv = self?.currentView as? ZoomedImageView  {
          ziv.scrollView.setZoomScale(1.0, animated: true)
        }
      })
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
    self.collectionView?.backgroundColor = UIColor(white: 1.0, alpha: 0.95)//TODO::DARKMODE!
    self.pageControlMaxDotsCount = Device.singleton == .iPad ? 25 : 9
    self.pageControl?.layer.shadowColor = UIColor.lightGray.cgColor
    self.pageControl?.layer.shadowRadius = 3.0
    self.pageControl?.layer.shadowOffset = CGSize(width: 0, height: 0)
    self.pageControl?.layer.shadowOpacity = 1.0
    self.pageControl?.pageIndicatorTintColor = UIColor.white
    self.pageControl?.currentPageIndicatorTintColor = UIColor.magenta//Const.SetColor.CIColor.color
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
  }
}
