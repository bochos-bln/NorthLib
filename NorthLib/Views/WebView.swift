//
//  WebView.swift
//
//  Created by Norbert Thies on 01.08.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit
import WebKit

/// A JSCall-Object describes a native call from JavaScript to Swift
open class JSCall: DoesLog {
  
  /// name of the NativeBridge object
  public var bridgeObject = ""
  /// name of the method called
  public var method = ""
  /// callback ID
  public var callback: Int?
  /// array of arguments
  public var args: [Any]?
  /// WebView object receiving the call
  public weak var webView: WebView?
  
  /// A new JSCall object is created using a WKScriptMessage
  public init( _ msg: WKScriptMessage ) throws {
    if let dict = msg.body as? Dictionary<String,Any> {
      bridgeObject = msg.name
      if let m = dict["method"] as? String {
        method = m
        callback = dict["callback"] as? Int
        args = dict["args"] as? [Any]
      }
      else { throw exception( "JSCall without name of method" ) }
    }
    else { throw exception( "JSCall without proper message body" ) }
  }
  
  // TODO: implement callback to return value to JS callback function
  
} // class JSCall

/// A JSBridgeObject describes a JavaScript object containing
/// methods that are passed to native functions
open class JSBridgeObject: DoesLog {
  
  /// Dictionary of JS function names to native closures
  public var functions: [String:(JSCall)->()] = [:]
  
  /// calls a native closure
  public func call( _ jscall: JSCall ) {
    if let f = functions[jscall.method] {
      debug( "From JS: '\(jscall.bridgeObject).\(jscall.method)' called" )
      f(jscall)
    }
    else {
      error( "From JS: undefined function '\(jscall.bridgeObject).\(jscall.method)' called" )
    }
  }
  
} // class JSBridgeObject

open class WebView: WKWebView, WKScriptMessageHandler, UIScrollViewDelegate {

  /// JS NativeBridge objects
  public var bridgeObjects: [String:JSBridgeObject] = [:]
  
  // The closure to call when content scrolled more than _scrollRatio
  private var _whenScrolled: ((CGFloat)->())?
  private var _scrollRatio: CGFloat = 0
  
  /// Define closure to call when link is pressed
  public func whenScrolled( minRatio: CGFloat, _ closure: @escaping (CGFloat)->() ) {
    _scrollRatio = minRatio
    _whenScrolled = closure
  }
  
  // content y offset at start of dragging
  private var startDragging: CGFloat?
  
  /// jsexec executes the passed string as JavaScript expression using
  /// evaluateJavaScript, if a closure is given, it is only called when
  /// there is no error.
  public func jsexec( _ expr: String, closure: ((Any?)->Void)? ) {
    self.evaluateJavaScript( expr ) {
      [weak self] (retval, error) in
      if let err = error {
        self?.error( "JavaScript error: " + err.localizedDescription )
      }
      else {
        if let callback = closure {
          callback( retval )
        }
      }
    }
  }
  
  /// calls a native closure
  public func call( _ jscall: JSCall ) {
    if let bo = bridgeObjects[jscall.bridgeObject] {
      bo.call(jscall)
    }
    else {
      error( "From JS: undefined bridge object '\(jscall.bridgeObject) used" )
    }
  }
  
  @discardableResult
  public func load(_ url: URL) -> WKNavigation? {
    let request = URLRequest(url: url)
    return load(request)
  }
  
  @discardableResult
  public func load(_ str: String) -> WKNavigation? {
    if let url = URL(string: str) {
      return load(url)
    }
    else { return nil }
  }
  
  public func setup() {
  }
  
  override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
    super.init(frame: frame, configuration: configuration)
    setup()
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  // MARK: - WKScriptMessageHandler protocol
  public func userContentController(_ userContentController: WKUserContentController,
                             didReceive message: WKScriptMessage) {
    if let jsCall = try? JSCall( message ) {
      call( jsCall)
    }
  }

  // MARK: - UIScrollViewDelegate protocol
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//      if let sd = startDragging {
//        if scrollView.isDragging {
//          let scrolled = sd-scrollView.contentOffset.y
//          let ratio = scrolled / scrollView.bounds.size.height
//          //debug("scrolled: \(scrolled), ratio = \(ratio)")
//        }
//      }
//  }
//
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    startDragging = scrollView.contentOffset.y
  }

  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if let sd = startDragging {
      let scrolled = sd-scrollView.contentOffset.y
      let ratio = scrolled / scrollView.bounds.size.height
      if let closure = _whenScrolled, abs(ratio) >= _scrollRatio {
        debug("scrolled: \(scrolled), ratio = \(ratio)")
        closure(ratio)
      }
    }
    startDragging = nil
  }
  
} // class WebView
