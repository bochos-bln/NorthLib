//
//  PdfOverviewCollectionVC.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// Provides tile Overview either of various PDF Files or of various Pages of one PDF File
//may work just with IMages and delegate handles what hapen on tap
class PdfOverviewCollectionVC : UICollectionViewController, CanRotate{
  
  // MARK: - Properties
  private let reuseIdentifier = "pdfCell"
  private let itemsPerRow:CGFloat = 4
  private let spacing:CGFloat = 12.0
  
  lazy var generellItemSize : CGSize = {
    let width = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    let totalRowSpacing = (2 * self.spacing) + ((itemsPerRow - 1) * spacing)
    let cellWidth = (width - totalRowSpacing)/itemsPerRow
    guard let defaultItemSize = pdfModel?.defaultItemSize else { return CGSize(width: cellWidth, height: cellWidth)}
    let ratio = defaultItemSize.width / defaultItemSize.height
    return CGSize(width: cellWidth, height: cellWidth/ratio)
  }()
  
  var pdfModel: PdfModel?
  var clickCallback: ((CGRect, PdfModel?)->())?
  
  init(pdfModel: PdfModel) {//Wrong can also be pdfpage
    self.pdfModel = pdfModel
    let layout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: spacing,
                                       left: spacing,
                                       bottom: spacing,
                                       right: spacing)
    layout.minimumLineSpacing = spacing
    layout.minimumInteritemSpacing = spacing
    super.init(collectionViewLayout: layout)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .yellow
    collectionView!.showsVerticalScrollIndicator = false
    collectionView!.showsHorizontalScrollIndicator = false
    
    // Register cell classes
    collectionView!.register(PdfOverviewCvcCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    
  }
  
  // MARK: UICollectionViewDataSource
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return pdfModel?.count ?? 0
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    guard let cell = _cell as? PdfOverviewCvcCell else { return _cell }
    if let pdfModel = self.pdfModel {
      cell.imageView.image = pdfModel.thumbnail(atIndex: indexPath.row, finishedClosure: { (img) in
        onMain { cell.imageView.image = img  }
      })
      cell.label.text = pdfModel.item(atIndex: indexPath.row)?.pageTitle
    }

    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //Did not work if cell has label with Outline description!
    let attributes = collectionView.layoutAttributesForItem(at: indexPath)
    var sourceFrame = CGRect.zero
    if let attr = attributes {
      sourceFrame = self.collectionView.convert(attr.frame, to: self.collectionView.superview?.superview)
    }
    pdfModel?.index = indexPath.row
    clickCallback?(sourceFrame, pdfModel)
  }
  
  
  /// Returns Cell Frame for given Index
  /// - Parameters:
  ///   - index: index of requested Frame
  ///   - fixFullFrame: if cell is out of view this returns a full cell size
  /// - Returns: frame for requested cell at index Path
  public func frameAtIndex(index:Int, fixFullFrame:Bool = false) -> CGRect {
    let attributes
      = collectionView.layoutAttributesForItem(at: IndexPath(row: index,
                                                             section: 0))
    var sourceFrame = CGRect.zero
    if let attr = attributes {
      sourceFrame = self.collectionView.convert(attr.frame, to: self.collectionView.superview?.superview)
      sourceFrame.size = self.generellItemSize
    }
    return sourceFrame
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PdfOverviewCollectionVC: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return self.generellItemSize
  }
}
