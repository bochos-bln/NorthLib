//
//  PdfOverviewCvcCell.swift
//  NorthLib
//
//  Created by Ringo.Mueller on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

class PdfOverviewCvcCell : UICollectionViewCell {
  
  let imageView:UIImageView? = UIImageView()
  let label:UILabel? = UILabel()
  //Looks strange and is a LEAK!
  var menu:ContextMenu?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    menu = ContextMenu(view: self)
    let menuItems = [(title: "test", icon: "eye.slash", closure: { (_:String) in })]
    menu?.menu = menuItems
    
    if let imageView = imageView {
      imageView.contentMode = .scaleAspectFit
      self.contentView.addSubview(imageView)
      pin(imageView, to: contentView)
    }
    
    if let label = label {
      label.numberOfLines = 2
      self.contentView.addSubview(label)
      pin(label, to: contentView, exclude: .top)
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
