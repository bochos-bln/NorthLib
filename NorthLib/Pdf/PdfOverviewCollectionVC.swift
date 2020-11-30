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
public class PdfOverviewCollectionVC : UICollectionViewController, CanRotate{
  
  /// Define the menu to display on long touch of a MomentView
  public var menuItems: [(title: String, icon: String, closure: (String)->())] = [] {
    didSet{
      menu?.menu = menuItems
    }
  }
  public var cellLabelFont:UIFont? = UIFont.systemFont(ofSize: 8)
  
  // MARK: - Properties
  private let reuseIdentifier = "pdfCell"
  private let itemsPerRow:Int
  private let spacing:CGFloat
  lazy var menu:ContextMenu? = ContextMenu(view: collectionView)
  
  lazy var generellItemSize : CGSize = {
    let width = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    let totalRowSpacing = PdfDisplayOptions.Overview.totalRowSpacing
    let cellWidth = (width - totalRowSpacing)/CGFloat(itemsPerRow)
    guard let defaultItemSize = pdfModel?.defaultItemSize else { return CGSize(width: cellWidth, height: cellWidth)}
    let ratio = defaultItemSize.width / defaultItemSize.height
    return CGSize(width: cellWidth, height: cellWidth/ratio)
  }()
  
  var pdfModel: PdfModel?
  var clickCallback: ((CGRect, PdfModel?)->())?
  
  init(pdfModel: PdfModel) {//Wrong can also be pdfpage
    self.pdfModel = pdfModel
    self.spacing = PdfDisplayOptions.Overview.spacing
    let layout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: self.spacing,
                                       left: self.spacing,
                                       bottom: self.spacing,
                                       right: self.spacing)
    layout.minimumLineSpacing = self.spacing
    layout.minimumInteritemSpacing = self.spacing
    self.itemsPerRow = PdfDisplayOptions.Overview.itemsPerRow
    super.init(collectionViewLayout: layout)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    collectionView?.showsVerticalScrollIndicator = false
    collectionView?.showsHorizontalScrollIndicator = false
    // Register cell classes
    collectionView?.register(PdfOverviewCvcCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    if let cv = self.collectionView, let cvsv = cv.superview {
      pin(cv.bottom, to: cvsv.bottomGuide())
      pin(cv.top, to: cvsv.topGuide())
      pin(cv.left, to: cvsv.leftGuide())
      pin(cv.right, to: cvsv.rightGuide())
    }
  }
  
  // MARK: UICollectionViewDataSource
  public override func numberOfSections(in collectionView: UICollectionView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }
  
  public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return pdfModel?.count ?? 0
  }
  
  public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    guard let cell = _cell as? PdfOverviewCvcCell else { return _cell }
    cell.label?.font = self.cellLabelFont
    if let pdfModel = self.pdfModel {
      cell.imageView?.image = pdfModel.thumbnail(atIndex: indexPath.row, finishedClosure: { (img) in
        onMain { cell.imageView?.image = img  }
      })
      cell.label?.text = pdfModel.item(atIndex: indexPath.row)?.pageTitle
//      cell.menu?.menu = self.menuItems //would be a leak!
    }
    return cell
  }
  
  public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return self.generellItemSize
  }
}
