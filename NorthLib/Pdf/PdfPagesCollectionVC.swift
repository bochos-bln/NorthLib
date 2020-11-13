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
class PdfPagesCollectionVC : ImageCollectionVC, CanRotate{
  
  /// Light status bar because of black background TBD at Zoom in the white Newspaper is in bg on zoom out the black bg
  /// Simple solution => white BG!
  ///  darkmode lightMode depending
  override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
  
  var data : PdfModel? {
    didSet{
//      self.collectionView.reload()
      guard let model = data else { return }
      self.index = model.index
      super.count = model.count
      self.collectionView.reloadData()
    }
  }
  
  deinit {
    print("SUCCESSFULL DEINIT PdfPagesCollectionVC")
  }
  
  init(data:PdfModel) {
    self.data = data
    super.init()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.collectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.95)//TODO::DARKMODE!
    self.pageControlMaxDotsCount = Device.singleton == .iPad ? 25 : 9
    self.pageControl?.layer.shadowColor = UIColor.lightGray.cgColor
    self.pageControl?.layer.shadowRadius = 3.0
    self.pageControl?.layer.shadowOffset = CGSize(width: 0, height: 0)
    self.pageControl?.layer.shadowOpacity = 1.0
    self.pageControl?.pageIndicatorTintColor = UIColor.white
    self.pageControl?.currentPageIndicatorTintColor = UIColor.magenta//Const.SetColor.CIColor.color
  }
  
  override func didReceiveMemoryWarning() {
    print("☠️☠️☠️\nRECIVE MEMORY WARNING\n☠️☠️☠️☠️\nPdfPagesCollectionVC->didReceiveMemoryWarning\n   ")
  }

  override func setupViewProvider(){
    viewProvider { [weak self] (index, oview) in
      guard let self = self else { return UIView() }
      let dataItem = self.data?.item(atIndex: index)
      if let ziv = oview as? ZoomedImageView {
        ziv.optionalImage = dataItem
        dataItem?.renderFullscreenImageIfNeeded()
        return ziv
      }
      else {
        let ziv = ZoomedImageView(optionalImage: dataItem)
        ziv.onTap { [weak self] (oimg, x, y) in
          guard let self = self else { return }
          self.zoomedImageViewTapped(oimg, x, y)
        }
//        ziv.onHighResImgNeeded(closure: self?.onHighResImgNeededClosure)????????
        dataItem?.renderFullscreenImageIfNeeded()
        return ziv
      }
    }
  }
}
