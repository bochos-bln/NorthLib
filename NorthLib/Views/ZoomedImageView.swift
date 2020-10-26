//
//    
//  NorthLib
//
//  Created by Ringo Müller on 27.05.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

// MARK: - OptionalImage (Protocol)
/// An Image with a smaller "Waiting Image"
public protocol OptionalImage {
  /// The main image to display
  var image: UIImage? { get set }
  /// An alternate image to display when the main image is not yet available
  var waitingImage: UIImage? { get set }
  /// Returns true if 'image' is available
  var isAvailable: Bool { get }
  /// Defines a closure to call when the main image becomes available
  func whenAvailable(closure: (()->())?)
}

extension OptionalImage {
  public var isAvailable: Bool { return image != nil }
}

// MARK: - ZoomedPdfImageSpec : OptionalImage (Protocol)
public protocol ZoomedPdfImageSpec : OptionalImage, DoesLog {
//  var pdfFilename: String { get }
  var pdfPage: PdfPage { get }
  var pageDescription: String { get }
  var canRequestHighResImg: Bool { get }
  var maxRenderingZoomScale: CGFloat { get }
  var nextRenderingZoomScale: CGFloat { get }
  var zoomLimit: CGFloat { get }
  func renderImageWithScale(scale: CGFloat) -> UIImage?
}

extension ZoomedPdfImageSpec{
  public var canRequestHighResImg: Bool {
    get {
      return nextRenderingZoomScale <= maxRenderingZoomScale
    }
  }
  
  
  //Its not a zoom Limit => TBD NAME IT!
  public var zoomLimit:CGFloat{
    get{
      return 2.0//x:  7.559 5s: 2.8670
      //ip 5s => 2x >1.5
      //ip x => 3x 1.1
      return 10/(UIScreen.main.scale*UIScreen.main.scale)//x: 4.199737264436737 5s:3.5
      return 3.3/UIScreen.main.scale //X:ZoomScale: 4.157739891792369 5s:2.365
      //IP5s >>>> TRY TO RENDER IMAGE WITH SCALE: 1.5768613515538468 2.0 RATIO
      return 1.1//TRY TO RENDER IMAGE WITH SCALE: 4.15773989179237  //3.0RATIO
      return 1.2//> TRY TO RENDER IMAGE WITH SCALE: 4.535716245591675
      return 1.3333333 //1.333 => 5.03
    }
  }
  
  public var nextRenderingZoomScale: CGFloat {
    get {
      guard let img = image else {
        ///if there is no image yet, generate the Image within minimum needed scale
        return 1.0
      }
//      let ns = 2*img.size.width/UIScreen.main.nativeBounds.width
//      let ns = 2.381101333333333*UIScreen.main.scale*img.size.width/UIScreen.main.nativeBounds.width
      let ns = zoomLimit*UIScreen.main.scale*img.size.width/pdfPage.frame.size.width
      
      print("$nzs Calculate next:\n  image width: \(img.size.width) (current image width)/ \(UIScreen.main.nativeBounds.width)(main bounds width) => Ratio \(img.size.width/UIScreen.main.nativeBounds.width)\n 2*mainscreenScale \(UIScreen.main.scale)*ratio =>")
      
      print("$nzs NextRendering ZoomScale: \(ns) = \(zoomLimit)*\(UIScreen.main.scale)*\(img.size.width)/\(pdfPage.frame.size.width)")
      
      print("$nzs initial zoom scale based on PDF Page: \(round(10.0*UIScreen.main.nativeBounds.width/pdfPage.frame.size.width)/10) \(UIScreen.main.nativeBounds.width)/\(pdfPage.frame.size.width))")
      print("$nzs current zoom scale based on PDF Page: \(round(10.0*img.size.width/pdfPage.frame.size.width)/10) \(img.size.width)/\(pdfPage.frame.size.width))")
      print("$nzs current zoom scale based on screen: \(round(10.0*img.size.width/UIScreen.main.nativeBounds.width)/10) \(img.size.width)/\(UIScreen.main.nativeBounds.width))")
      
      return ns
        
    }
  }
  
  public func renderImageWithNextScale(check: (()->(Bool))?) -> UIImage? {
    let next = self.nextRenderingZoomScale
    if next > maxRenderingZoomScale {
        log("Stop Rendering reached Limit of: \(maxRenderingZoomScale) next would be: \(next)")
      return nil
      
    }
    return self.renderImageWithScale(scale: next)
  }
  
  public func renderImageWithNextScale( callback : @escaping (UIImage?)->(), check: (()->(Bool))?){
    let next = self.nextRenderingZoomScale
    if next > maxRenderingZoomScale {
      log("Stop Rendering reached Limit of: \(maxRenderingZoomScale) next would be: \(next)")
      callback(nil)
      return
    }
    DispatchQueue(label: "PdfTest.render.detail.image.queue").async {
      callback(self.renderImageWithScale(scale: next))
    }
  }
}

// MARK: - OptionalImageItem : OptionalImage
/// Reference Implementation
open class OptionalImageItem: OptionalImage{
  
  deinit {
    print("deinit OptionalImageItem")
  }
  
  private var availableClosure: (()->())?
  fileprivate var onUpdatingClosureClosure: (()->())? = nil
  fileprivate var zoomFactorForRequestingHigherResImage : CGFloat = 1.1
  fileprivate var _image: UIImage?
  public var image: UIImage?{
    get { return _image }
    set {
      _image = newValue
      availableClosure?()
    }
  }
  public var waitingImage: UIImage?
  public required init(waitingImage: UIImage? = nil) {
    self.waitingImage = waitingImage
  }
}

// MARK: - OptionalImageItem: Closures
extension OptionalImageItem{
  public func whenAvailable(closure: (()->())?) {
    availableClosure = closure
  }
}
// MARK: -
// MARK: - ZoomedImageView
open class ZoomedImageView: UIView, ZoomedImageViewSpec {
  var imageViewBottomConstraint: NSLayoutConstraint?
  var imageViewLeadingConstraint: NSLayoutConstraint?
  var imageViewTopConstraint: NSLayoutConstraint?
  var imageViewTrailingConstraint: NSLayoutConstraint?
  var layoutInitialized = false
  
  deinit {
    print("deinit ZoomedImageView")
  }
  
  open override func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview == nil {
      orientationClosure = nil
      optionalImage = nil
    }
  }
  
  private var onHighResImgNeededClosure: ((OptionalImage,
  @escaping (Bool) -> ()) -> ())?
  private var onHighResImgNeededZoomFactor: CGFloat = 1.1
  private var highResImgRequested = false
  private var orientationClosure:OrientationClosure? = OrientationClosure()
  private var singleTapRecognizer : UITapGestureRecognizer?
  private let doubleTapRecognizer = UITapGestureRecognizer()
  private var zoomEnabled :Bool = true {
    didSet{
      self.scrollView.pinchGestureRecognizer?.isEnabled = zoomEnabled
    }
  }
  private var onTapClosure: ((_ image: OptionalImage,
    _ x: Double,
    _ y: Double)->())? = nil {
    didSet{
      if let tap = singleTapRecognizer {
        tap.removeTarget(self, action: #selector(handleSingleTap))
        singleTapRecognizer = nil
      }
      
      if onTapClosure != nil {
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleSingleTap))
        tap.numberOfTapsRequired = 1
        self.imageView.addGestureRecognizer(tap)
        self.imageView.isUserInteractionEnabled = true
        tap.require(toFail: doubleTapRecognizer)
        singleTapRecognizer = tap
      }
    }
  }
  
  public private(set) var scrollView: UIScrollView = UIScrollView()
  public private(set) var imageView: UIImageView = UIImageView()
  public private(set) var xButton: Button<CircledXView> = Button<CircledXView>()
  public private(set) var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
  public private(set) lazy var menu = ContextMenu(view: imageView, smoothPreviewForImage: true)
  public var optionalImage: OptionalImage?{
    willSet {
      if let itm = optionalImage as? OptionalImageItem {
        itm.onUpdatingClosureClosure = nil
      }
    }
    didSet {
      updateImage()
    }
  }
  
  // MARK: Life Cycle
  public required init(optionalImage: OptionalImage) {
    self.optionalImage = optionalImage
    super.init(frame: CGRect.zero)
    setup()
  }
  
  override public init(frame: CGRect) {
    fatalError("init(frame:) has not been implemented");
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented");
  }
  
  fileprivate func zoomOutAndCenter() {
    layoutInitialized = false
    self.setNeedsLayout()
    self.layoutIfNeeded()
  }
  
  // MARK: layoutSubviews
  open override func layoutSubviews() {
    super.layoutSubviews()
    if !layoutInitialized, self.bounds.size != .zero{
      layoutInitialized = true
      self.updateMinimumZoomScale()
      if self.scrollView.zoomScale != self.scrollView.minimumZoomScale {
        //zoom out if needed
        //triggers scrollViewDidZoom => updateConstraintsForSize
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
      }
      else {
        //center!
        self.updateConstraintsForSize(self.bounds.size)
      }
    }
  }
}

// MARK: - Setup
extension ZoomedImageView{
  func setup() {
    setupScrollView()
    setupXButton()
    setupSpinner()
    setupDoubleTapGestureRecognizer()
    updateImage()
    orientationClosure?.onOrientationChange(closure: {
      let sv = self.scrollView //local name for shorten usage
      let wasMinZoom = sv.zoomScale == sv.minimumZoomScale
      self.updateMinimumZoomScale()
      if wasMinZoom || sv.zoomScale < sv.minimumZoomScale {
        sv.zoomScale = sv.minimumZoomScale
      }
    })
  }
  
  // MARK: updateImage
  func updateImage() {
    if let oi = optionalImage, oi.isAvailable, let detailImage = oi.image {
      setImage(detailImage)
      zoomEnabled = true
      spinner.stopAnimating()
      self.zoomOutAndCenter()
    }
    else {
      //show waitingImage if detailImage is not available yet
      if let img = optionalImage?.waitingImage {
        setImage(img)
        self.scrollView.zoomScale = 1
        zoomEnabled = false
      } else {
        //Due re-use its needed to unset probably existing old image
        imageView.image = nil
      }
      spinner.startAnimating()
      optionalImage?.whenAvailable {
        if let img = self.optionalImage?.image {
          self.setImage(img)
          self.layoutIfNeeded()
          self.zoomEnabled = true
          self.spinner.stopAnimating()
          //due all previewImages are not allowed to zoom,
          //exchanged image should be shown fully
          self.optionalImage?.whenAvailable(closure: nil)
          //Center
          self.zoomOutAndCenter()
        }
      }
    }
  }
  

  
  // MARK: setupScrollView
  func setupScrollView() {
    imageView.contentMode = .scaleAspectFit
    scrollView.delegate = self
    scrollView.maximumZoomScale = 1.1
    scrollView.zoomScale = 1.0
    ///prevent pinch/zoom smaller than min while pinch
    scrollView.bouncesZoom = true
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.addSubview(imageView)
    addSubview(scrollView)
    NorthLib.pin(scrollView, to: self)
    (imageViewTopConstraint, imageViewBottomConstraint, imageViewLeadingConstraint, imageViewTrailingConstraint) =
      NorthLib.pin(imageView, to: scrollView)
  }
}

// MARK: - Handler
extension ZoomedImageView{
  public func onHighResImgNeeded(zoomFactor: CGFloat = 1.01,
                                 closure: ((OptionalImage,
    @escaping (Bool)-> ()) -> ())?) {
    self.onHighResImgNeededClosure = closure
    self.scrollView.maximumZoomScale = closure == nil ? 1.0 : 2.0
    self.onHighResImgNeededZoomFactor = zoomFactor
  }
}

// MARK: - Menu Handler
extension ZoomedImageView{
  public func addMenuItem(title: String,
                          icon: String,
                          closure: @escaping (String) -> ()) {
    menu.addMenuItem(title: title, icon: icon, closure: closure)
  }
}

// MARK: - Tap Recognizer
extension ZoomedImageView{
  public func onTap(closure: ((OptionalImage, Double, Double) -> ())?) {
    self.onTapClosure = closure
  }
  
  // Set up the gesture recognizers for single and doubleTap
  func setupDoubleTapGestureRecognizer() {
    ///double Tap
    doubleTapRecognizer.addTarget(self,
                                  action: #selector(handleDoubleTap))
    doubleTapRecognizer.numberOfTapsRequired = 2
    scrollView.addGestureRecognizer(doubleTapRecognizer)
    doubleTapRecognizer.isEnabled = zoomEnabled
  }
  
  // MARK: Single Tap
  @objc func handleSingleTap(sender: UITapGestureRecognizer){
    let loc = sender.location(in: imageView)
    let size = imageView.frame.size
    guard let closure = onTapClosure else { return }
    guard let oi = self.optionalImage else { return }
    
    if true {//THIS WOULD BE THE RIGHT ZOOM SCALE SO RENDER... gives the wrong one!
      print("DEBUG ZOOM SCALES within handleSingleTap before:\( self.scrollView.zoomScale) \(self.scrollView.contentSize) \(self.imageView.image?.size)")
      self.scrollView.setZoomScale(1.0/UIScreen.main.scale, animated: true)
      
      return
    }
    
    closure(oi,
            Double(loc.x / (size.width / scrollView.zoomScale )),
            Double(loc.y / (size.height / scrollView.zoomScale )))
  }
  
  // MARK: Double Tap
  @objc func handleDoubleTap(sender : Any) {
    guard let tapR = sender as? UITapGestureRecognizer else {
      return
    }
    if zoomEnabled == false {
      self.setNeedsLayout()
      self.layoutIfNeeded()
      return
    }
    ///Zoom Out if current zoom is maximum zoom
    if scrollView.zoomScale == scrollView.maximumZoomScale
      || scrollView.zoomScale >= 2 {
      scrollView.setZoomScale(scrollView.minimumZoomScale,
                              animated: true)
    }
    ///Otherwise Zoom In to tap loacation
    else {
      let maxZoom = scrollView.maximumZoomScale
      print("Max Zoom: \(maxZoom) if bigger than 2 limit")
      
      let zoomLimit = (optionalImage as? ZoomedPdfImageSpec)?.zoomLimit ?? 2.0
      if maxZoom > zoomLimit { scrollView.maximumZoomScale = zoomLimit  }
      let tapLocation = tapR.location(in: tapR.view)
      let newCenter = imageView.convert(tapLocation, from: scrollView)
      let zoomRect
        = CGRect(origin: newCenter, size: CGSize(width: 1, height: 1))
      scrollView.zoom(to: zoomRect,
                      animated: true)
      scrollView.isScrollEnabled = true
      if maxZoom > zoomLimit { scrollView.maximumZoomScale = maxZoom  }
    }
  }
  

}

// MARK: - Helper
extension ZoomedImageView{
  
  // MARK: setImage
  fileprivate func setImage(_ image: UIImage) {
    imageView.image = image
    imageView.frame = CGRect(x: imageView.frame.origin.x,
                             y: imageView.frame.origin.y,
                             width: image.size.width,
                             height: image.size.height)
    updateMinimumZoomScale()
  }
  
  // MARK: updateMinimumZoomScale
  fileprivate func updateMinimumZoomScale(){
    let widthScale = self.bounds.size.width / (imageView.image?.size.width ?? 1)
    let heightScale = self.bounds.size.height / (imageView.image?.size.height ?? 1)
    let minScale = min(widthScale, heightScale, 1)
    scrollView.minimumZoomScale = minScale
  }
  // MARK: updateConstraintsForSize
  fileprivate func updateConstraintsForSize(_ size: CGSize) {
    let yOffset = max(0, (size.height - imageView.frame.height) / 2)
    imageViewTopConstraint?.constant = yOffset
    imageViewBottomConstraint?.constant = yOffset
    
    let xOffset = max(0, (size.width - imageView.frame.width) / 2)
    imageViewLeadingConstraint?.constant = xOffset
    imageViewTrailingConstraint?.constant = xOffset
    
    let contentHeight = yOffset * 2 + self.imageView.frame.height
    self.layoutIfNeeded()
    self.scrollView.contentSize = CGSize(width: self.scrollView.contentSize.width, height: contentHeight)
  }
  
  
  // MARK: updateImagewithHighResImage
  func updateImagewithHighResImage(_ image: UIImage) {
    guard let oldImg = imageView.image else {
      self.setImage(image)
      return
    }
    let contentOffset = scrollView.contentOffset
    self.setImage(image)
    let newSc = oldImg.size.width * scrollView.zoomScale / image.size.width
    scrollView.zoomScale = newSc
    print("updateImagewithHighResImage: zoomscale: \(newSc)")
    scrollView.setContentOffset(contentOffset, animated: false)
    self.updateConstraintsForSize(self.bounds.size)
  }
}

// MARK: - UIScrollViewDelegate
extension ZoomedImageView: UIScrollViewDelegate{
  public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  public func scrollViewDidZoom(_ scrollView: UIScrollView) {
    //Center if needed
    updateConstraintsForSize(self.bounds.size)
    print("scrollViewDidZoom::: zooming current zoomscale: \(scrollView.zoomScale)")
    //request high res Image if possible
    if zoomEnabled == false { return }
    if self.onHighResImgNeededZoomFactor > scrollView.zoomScale { return }
    if self.highResImgRequested == true { return }
    if let zPdfImg = optionalImage as? ZoomedPdfImageSpec, zPdfImg.canRequestHighResImg == false { return }
    guard let requestHrImageClosure = onHighResImgNeededClosure else { return }
    guard let _optionalImage = optionalImage else { return }

    self.highResImgRequested = true
    print("scrollViewDidZoom::: zooming request high res img! Current svSize: \(scrollView.contentSize) imgSize:\(imageView.image?.size)")
    
    requestHrImageClosure(_optionalImage, { success in
      if success, let img = _optionalImage.image {
        //Problem: 0.3333 != oldImg.size.width * scrollView.zoomScale / image.size.width
        self.updateImagewithHighResImage(img)
        /****
         CASES:
         #1 there is an image wich is similar to current zoom scale
         
            #2 limited image e.g. request 32x got 15x due memory limitation
         
         */
      } else {
        //may disable next zoom request, but not here!?
        //where to set maxZoomScale to double tap maxZoom <=> full page zoomed out
      }
      self.highResImgRequested = false
    })
  }
}


/*****
 
 
 
 PDF Test : ImageCollectionVC
 - images: [OptionalImage] = [ZoomedPdfImage(pdfPage: page, pageDescription: "\(pdfFilename) Page : \(pagenumber)")]
 - self.onHighResImgNeeded { (oimg, callback) in
      ....
        pdf_img.renderImageWithNextScale()
 
 
 
 ImageCollectionVC : PageCollectionVC
 - images: [OptionalImage]
 //extension ImageCollectionVC{
 - public func onHighResImgNeeded(zoomFactor: CGFloat = 1.1, ... calls PDF Test
 
 - setupViewProvider
      - ziv ... ZoomedImageView
            ziv.onHighResImgNeeded
 
            optionalImage: OptionalImage?  => ZoomedPdfImage
 */
