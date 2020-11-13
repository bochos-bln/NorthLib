//
//  PdfOverviewCvcCell.swift
//  NorthLib
//
//  Created by Ringo.Mueller on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

class PdfOverviewCvcCell : UICollectionViewCell {
  
  let imageView = UIImageView()
  let label = UILabel()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.contentView.addSubview(imageView)
    self.contentView.addSubview(label)
    imageView.contentMode = .scaleAspectFit
//    self.backgroundColor = .yellow
    pin(imageView, to: contentView)
    label.numberOfLines = 2
//    label.font = Const.Fonts.contentFont(size: 8)
    pin(label, to: contentView, exclude: .top)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
