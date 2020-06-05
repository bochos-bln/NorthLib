//
//  Specifications.swift
//
//  Created by Norbert Thies on 25.05.20.
//  Copyright © 2020 Norbert Thies, Ringo Müller. All rights reserved.
//

import UIKit

/// An Image with a smaller "Waiting Image"
public protocol OptionalImage {
  /// The main image to display
  var image: UIImage? { get set }
  /// An alternate image to display when the main image is not yet available
  var waitingImage: UIImage? { get set }
  /// Returns true if 'image' is available
  var isAvailable: Bool { get }
  /// Defines a closure to call when the main image becomes available
  func whenAvailable(closure: @escaping ()->())
  
  /// Define closure to call when the user is zooming beyond the resolution
  /// of the image. 'zoomFactor' defines the maximum zoom after which a higher
  /// resolution image is requested.
  func onHigherImageResolutionNeeded(zoomFactor: CGFloat,
                                     closure: @escaping ()->UIImage?)
  
  /// Defines a closure to call when the user has tapped into the image.
  /// The coordinates passed to the closure are relative content size
  /// coordinates: 0 <= x,y <= 1
  func onTap(closure: @escaping (_ x: Double, _ y: Double)->())
}

extension OptionalImage {
  public var isAvailable: Bool { return image != nil }
}

/**
 A ZoomedImageView presents an Image in an ImageView that is scrollable
 and zoomable.
 
 It consists of an ImageView managed by a ScrollView and an additional x-shaped
 button which may be used to terminate the ImageView. The button is only visible
 when a closure is defined that is called when the button has been pressed.
 
 The ImageView displays an OptionalImage. If the main image is available, zooming
 and scrolling of that image is enabled. Initially the image is sized and
 positioned so that it is completely visible but couldn't be enlarged without
 cropping a part of the image. If the main image is not available, the waiting image
 is displayed without being zoomable or scrollable and a spinner is shown in
 the centre of the view.
 
 If the main image is displayed a double tap either enlarges the image so that
 its resolution matches the resolution of the screen or (if already enlarged)
 it is shrinked to its initial size and position.
 */
public protocol ZoomedImageViewSpec where Self: UIView {
  /// The scrollview managing the ImageView
  var scrollView: UIScrollView { get }
  /// The Imageview displaying either the main or the waiting image
  var imageView: UIImageView { get }
  /// The image to display
  var optionalImage: OptionalImage { get set }
  /// The X-Button (may be used to close the ZoomedImageView)
  var xButton: Button<CircledXView> { get }
  // Spinner indicating activity if !OptionalImage.isAvailable
  var spinner: UIActivityIndicatorView { get }
  /// The context menu to display
  var menu: ContextMenu { get }
  
  /// Initialize with optional image, displays the main image if available.
  /// Otherwise the waiting image is displayed and via 'whenAvailable' a closure
  /// is defined to replace the waiting image with the main image (when it is available)
  init(optionalImage: OptionalImage)
  
  /// Define closure to call when the X-Button is pressed
  func onX(closure: @escaping ()->())
}

public extension ZoomedImageViewSpec {
  
  /// This closure is called when the X-Button has been pressed
  func onX(closure: @escaping ()->()) {
    xButton.isHidden = false
    xButton.onPress {_ in closure() }
  }
  
  /// Setup the xButton
  func setupXButton() {
    xButton.pinHeight(35)
    xButton.pinWidth(35)
    xButton.color = .black
    xButton.buttonView.isCircle = true
    xButton.buttonView.circleColor = UIColor.rgb(0xdddddd)
    xButton.buttonView.color = UIColor.rgb(0x707070)
    xButton.buttonView.innerCircleFactor = 0.5
    self.addSubview(xButton)
    pin(xButton.right, to: self.rightGuide(), dist: -15)
    pin(xButton.top, to: self.topGuide(), dist: 15)
    xButton.isHidden = true
  }
  
  /// Setup the spinner
  func setupSpinner() {
    if #available(iOS 13, *) {
      spinner.style = .large
      spinner.color = .white
    }
    else { spinner.style = .whiteLarge }
    spinner.hidesWhenStopped = true
    addSubview(spinner)
    pin(spinner.centerX, to: self.centerX)
    pin(spinner.centerY, to: self.centerY)
    self.bringSubviewToFront(spinner)
  }
    
} // ZoomedImageViewSpec

/**
 An ImageCollectionVC utilizes PageCollectionVC to show a collection of ZoomedImageViews.
 
 After being initialized the attribute 'images' is set to contain an array of
 ZoomedImageViews **EXPECTED OptionalImageItem!**. The attribute 'index' (from PageCollectionVC) is used to point
 to that image which is to display on the screen. Each zoomable image fills the complete
 space of ImageCollectionVCs view. Hence the size of every cell of the collection
 view is identical to the size of the collection view's self.view.
 ImageCollectionVC displays an xButton alike ZoomedImageView's xButton which by default
 (no 'onX' closure was specified) performs
    self.navigationController?.popViewController(animated: true)
       or
    self.presentingViewController.dismiss(...)
 if the X has been tapped.
 
 To indicate on which page a user is currently positioned a PageControl is displayed
 if there are more than one image. The ImageCollectionVC only updates the pageControl
 attributes:
   currentPage - to indicate which image is displayed
   numberOfPages - to specify how many dots are displayed in total
 In Case of too many Pages, the PageControll dots are cut of at the Edge of the CollectionView. IN that Case we can limit the max shown dots with: pageControlMaxDotsCount. Set pageControlMaxDotsCount = 0 would display all dots no matter if they can be shown.
 */
public protocol ImageCollectionVCSpec where Self: PageCollectionVC {
  
  /// The Images to display
  var images: [OptionalImage] { get set }

  /// The X-Button (may be used to close the ImageCollectionVC)
  var xButton: Button<CircledXView> { get }
  
  /// The PageControl used to display an indicator of how many images are available
  var pageControl: UIPageControl { get }
  
  /// Max count of dots in pageControl, set to 0 show all dots
  var pageControlMaxDotsCount: Int { get set}
  
  /// The color used for pageControl
  var pageControlColors: (current: UIColor?, other: UIColor?) { get set }
  
} // ImageCollectionVC

public extension ImageCollectionVCSpec {
  /// Setup the xButton
  func setupXButton() {
    xButton.pinHeight(35)
    xButton.pinWidth(35)
    xButton.color = .black
    xButton.buttonView.isCircle = true
    xButton.buttonView.circleColor = UIColor.rgb(0xdddddd)
    xButton.buttonView.color = UIColor.rgb(0x707070)
    xButton.buttonView.innerCircleFactor = 0.5
    self.view.addSubview(xButton)
    pin(xButton.right, to: self.view.rightGuide(), dist: -15)
    pin(xButton.top, to: self.view.topGuide(), dist: 15)
    xButton.isHidden = true
  }
  
  /// An example of setting up the PageControl
  func setupPageControl() {
    self.pageControl.hidesForSinglePage = true
    self.view.addSubview(self.pageControl)
    pin(self.pageControl.centerX, to: self.view.centerX)
    // Example values for dist to bottom and height
    pin(self.pageControl.bottom, to: self.view.bottomGuide(), dist: -15)
    /// Height Pin has no Effect @Test PinHeight 1
    //self.pageControl.pinHeight(1)
    /// PageControl example color, set here would overwrite external set
    //self.pageControlColors = (current: UIColor.rgb(0xcccccc),
    //                           other: UIColor.rgb(0xcccccc, alpha: 0.3))
  }
  
  /// Setting pageControl's colors:
  var pageControlColors: (current: UIColor?, other: UIColor?) {
    get {
      (current: pageControl.currentPageIndicatorTintColor,
       other: pageControl.pageIndicatorTintColor)
    }
    set {
      pageControl.currentPageIndicatorTintColor = newValue.current
      pageControl.pageIndicatorTintColor = newValue.other
    }
  }
  
} // ImageCollectionVC
