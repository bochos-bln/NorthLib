//
//  ViewExtensions.swift
//
//  Created by Norbert Thies on 2019-02-28
//  Copyright © 2019 Norbert Thies. All rights reserved.
//
//  This file implements some UIView extensions
//

import UIKit

public struct LayoutAnchorX {
  public var anchor: NSLayoutXAxisAnchor
  public var view: UIView
  init(_ view: UIView, _ anchor: NSLayoutXAxisAnchor) 
    { self.view = view; self.anchor = anchor }
}

public struct LayoutAnchorY {
  public var anchor: NSLayoutYAxisAnchor
  public var view: UIView
  init(_ view: UIView, _ anchor: NSLayoutYAxisAnchor) 
    { self.view = view; self.anchor = anchor }
}

public struct LayoutDimension {
  public var anchor: NSLayoutDimension
  public var view: UIView
  init(_ view: UIView, _ anchor: NSLayoutDimension) 
    { self.view = view; self.anchor = anchor }
}

// Some Auto-Layout related extensions
public extension UIView {
  
  /// Bottom anchor
  var bottom: LayoutAnchorY { return LayoutAnchorY(self, bottomAnchor) }
  /// Top anchor
  var top: LayoutAnchorY { return LayoutAnchorY(self, topAnchor) }
  /// Vertical center anchor
  var centerY: LayoutAnchorY { return LayoutAnchorY(self, centerYAnchor) }
  /// Left Anchor
  var left: LayoutAnchorX { return LayoutAnchorX(self, leftAnchor) }
  /// Right Anchor
  var right: LayoutAnchorX { return LayoutAnchorX(self, rightAnchor) }
  /// Horizontal center anchor
  var centerX: LayoutAnchorX { return LayoutAnchorX(self, centerXAnchor) }
  /// Width anchor
  var width: LayoutDimension { return LayoutDimension(self, widthAnchor) }
  /// Height anchor
  var height: LayoutDimension { return LayoutDimension(self, heightAnchor) }

  /// Bottom margin anchor
  func bottomGuide(isMargin: Bool = false) -> LayoutAnchorY { 
    let guide = isMargin ? layoutMarginsGuide : safeAreaLayoutGuide
    return LayoutAnchorY(self, guide.bottomAnchor)
  }
  /// Top margin anchor
  func topGuide(isMargin: Bool = false) -> LayoutAnchorY { 
    let guide = isMargin ? layoutMarginsGuide : safeAreaLayoutGuide
    return LayoutAnchorY(self, guide.topAnchor)
  }
  /// Left margin Anchor
  func leftGuide(isMargin: Bool = false) -> LayoutAnchorX { 
    let guide = isMargin ? layoutMarginsGuide : safeAreaLayoutGuide
    return LayoutAnchorX(self, guide.leftAnchor)
  }
  /// Right margin Anchor
  func rightGuide(isMargin: Bool = false) -> LayoutAnchorX { 
    let guide = isMargin ? layoutMarginsGuide : safeAreaLayoutGuide
    return LayoutAnchorX(self, guide.rightAnchor)
  }
  
  /// Pin width of view
  @discardableResult
  func pinWidth(_ width: CGFloat) -> NSLayoutConstraint {
    translatesAutoresizingMaskIntoConstraints = false
    let constraint = widthAnchor.constraint(equalToConstant: width)
    constraint.isActive = true
    return constraint
  }
  @discardableResult
  func pinWidth(_ width: Int) -> NSLayoutConstraint { return pinWidth(CGFloat(width)) }
  
  /// Pin height of view
  @discardableResult
  func pinHeight(_ height: CGFloat) -> NSLayoutConstraint {
    translatesAutoresizingMaskIntoConstraints = false
    let constraint = heightAnchor.constraint(equalToConstant: height)
    constraint.isActive = true
    return constraint
  }
  @discardableResult
  func pinHeight(height: Int) -> NSLayoutConstraint { return pinHeight(CGFloat(height)) }
  
  static func animate(seconds: Double, delay: Double = 0, closure: @escaping ()->()) {
    UIView.animate(withDuration: seconds, delay: delay, options: .curveEaseOut, 
                   animations: closure, completion: nil)  
  }
  
} // extension UIView

/// Pin vertical anchor of one view to vertical anchor of another view
@discardableResult
public func pin(_ la: LayoutAnchorY, to: LayoutAnchorY, 
  dist: CGFloat = 0) -> NSLayoutConstraint {
  la.view.translatesAutoresizingMaskIntoConstraints = false
  let constraint = la.anchor.constraint(equalTo: to.anchor, constant: dist)
  constraint.isActive = true
  return constraint
}

/// Pin horizontal anchor of one view to horizontal anchor of another view
@discardableResult
public func pin(_ la: LayoutAnchorX, to: LayoutAnchorX, 
  dist: CGFloat = 0) -> NSLayoutConstraint {
  la.view.translatesAutoresizingMaskIntoConstraints = false
  let constraint = la.anchor.constraint(equalTo: to.anchor, constant: dist)
  constraint.isActive = true
  return constraint
}

/// Pin width/height to width/height of another view
@discardableResult
public func pin(_ la: LayoutDimension, to: LayoutDimension, 
  dist: CGFloat = 0) -> NSLayoutConstraint {
  la.view.translatesAutoresizingMaskIntoConstraints = false
  let constraint = la.anchor.constraint(equalTo: to.anchor, constant: dist)
  constraint.isActive = true
  return constraint
}

/// Pin all edges of one view to the edges of another view
@discardableResult
public func pin(_ view: UIView, to: UIView, dist: CGFloat = 0) -> (top: NSLayoutConstraint, 
  bottom: NSLayoutConstraint, left: NSLayoutConstraint, right: NSLayoutConstraint) {
  let top = pin(view.top, to: to.top, dist: dist)
  let bottom = pin(view.bottom, to: to.bottom, dist: -dist)
  let left = pin(view.left, to: to.left, dist: dist)
  let right = pin(view.right, to: to.right, dist: -dist)
  return (top, bottom, left, right)
}
