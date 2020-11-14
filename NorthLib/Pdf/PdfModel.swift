//
//  PdfModel.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 15.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import PDFKit


// MARK: PdfArrayModel
protocol PdfModel {
  var count : Int { get }
  var index : Int { get set }
  var defaultItemSize : CGSize? { get }
  func item(atIndex: Int) -> ZoomedPdfImageSpec
}

protocol PDFOutlineStructure {
  /// Due usage in UICollection View and probably structured PDF (otherwise sections = 1) use this structure later
  var referenceForStructure : UICollectionViewDataSource? {get}
  var numberOfSections : Int { get }
  func numberOfItemsInSection(_ section: Int) -> Int
  func pageForItemAt(indexPath: IndexPath) -> PDFPage
}

// MARK: PdfArrayModel
extension PdfModel{
}

// MARK: PdfDocModel
class PdfModelItem : PdfModel/*, PDFOutlineStructure*/ {
  var defaultItemSize: CGSize?
  var index: Int = 0
  var count: Int
  var url:URL?
  
  func item(atIndex: Int) -> ZoomedPdfImageSpec {
    /**TODO SAVE FOR THUMBNAIL*/
    let itm = ZoomedPdfImage(url: url, index: atIndex)
//    itm.pdfUrl = url
    return itm
  }
  
  static let previewDeviceWithScale : CGFloat = 0.25//4 in a row
  

  
  var images : [ZoomedPdfImage] = []
  
  var pageMeta : [Int:String] = [:]
  
  init(url:URL?) {
    guard let url = url else {
      self.defaultItemSize = nil
      self.count = 0
      self.url = nil
      return
    }
    let pdfDocument = PDFDocument(url: url)
    self.url = url
    self.count = pdfDocument?.pageCount ?? 0
    self.defaultItemSize = pdfDocument?.page(at: 0)?.frame?.size
    /*
    print("Parsing PDF By Outline Root PDF has \(pdfDocument.outlineRoot?.numberOfChildren ?? 0) Sections")
    if let outline = pdfDocument.outlineRoot {
      for sectionIdx in 0...outline.numberOfChildren-1{
        if let sectionOutline = outline.child(at: sectionIdx) {
          print("Parsing PDF By Outline Section \(sectionOutline) has \(sectionOutline.numberOfChildren) Pages")
          for pageIdx in 0...sectionOutline.numberOfChildren-1 {
            if let pageOutline = sectionOutline.child(at: pageIdx) {
              if let page = pageOutline.destination?.page {
                let idx = pdfDocument.index(for: page)
//                pageMeta[idx] = (sectionOutline.label, pageOutline.label)
                pageMeta[idx] = "\(sectionOutline.label ?? "-")\n\(pageOutline.label ?? "-")"
              }
            }
          }
        }
      }
    }

    //TODO CREATE ZOOMEDPDF IMAGES!
    for pagenumber in 0...pdfDocument.pageCount-1{
      if let page = pdfDocument.page(at: pagenumber) {
        var pageDescription : String = ""
//        if let meta = pageMeta[pagenumber], let section = meta.0, let pagetitele = meta.1 {
        if let meta = pageMeta[pagenumber] {
          pageDescription = meta
        } else {
          pageDescription = "Page : \(pagenumber)"
        }

        let zoomedPdfImage = ZoomedPdfImage(pdfPage: page, pageDescription: pageDescription)
        self.images.append(zoomedPdfImage)
      }
    }
 */
  }
  
  deinit {
    print("********  PdfDocModel deinit  ********")
  }
}


// MARK: PdfModelHelper
class PdfModelHelper{
  
  static func demoDocUrl() -> URL? {
    guard var pdfUrls
      = Bundle.main.urls(forResourcesWithExtension: "pdf",
                         subdirectory: "DemoPdf") else { return nil }
    pdfUrls.sort { $0.absoluteString.compare(
      $1.absoluteString, options: .caseInsensitive) == .orderedDescending
    }
    return pdfUrls.first
  }
}



/**
 A Queue for Render 1:1 Images to limit paralell renderings
 - parallel renderings slow down the single render time from e.g. 0.6s to 5s if 10 parallel renderings
 - use this with an option that stops the execution if not needed anymore
    e.g. on enter execution block check&return
 */
class ImageRendererQueue {
  static let shared = ImageRendererQueue()
  let semaphore = DispatchSemaphore(value: 2)//How many 1:! Renderings parallel?
  let queue = DispatchQueue.init(label: "imageRendererQueue",
                                 qos: .userInteractive,
                                 attributes: .concurrent,
                                 autoreleaseFrequency: .workItem,
                                 target: nil)
  /// perform closure on own thread
  fileprivate static func enqueue(closure: @escaping ()->()) {
    shared.queue.async {
      shared.semaphore.wait()
      print("&& SEMAPHORE STARTED")
      closure()
      print("&& SEMAPHORE ENDED")
      shared.semaphore.signal()
    }
  }
}
