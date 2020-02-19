//
//  Globals.swift
//
//  Created by Norbert Thies on 20.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//
//  This file implements various global functions.
//

import Foundation

/// delays execution of a closure for a number of seconds
public func delay(seconds: Double, completion:@escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { completion() }
}

/// perform closure on main thread
public func onMain(closure: @escaping ()->()) {
  DispatchQueue.main.async(execute: closure)
}

/// returns the type name of an object as String
public func typeName<T>(_ obj: T) -> String { return "\(type(of:obj))" }

/// Returns a path to a unique temporary file
public func tmppath() -> String {
  let dir = FileManager.default.temporaryDirectory
  let uuid = UUID().uuidString
  return "\(dir.path)/\(uuid).tmp"
}
