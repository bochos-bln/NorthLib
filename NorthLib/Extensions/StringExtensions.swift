//
//  StringExtensions.swift
//
//  Created by Norbert Thies on 20.07.16.
//  Copyright © 2016 Norbert Thies. All rights reserved.
//
//  This file implements various String extensions.
//

import UIKit

public extension String {
  
  /// The String as a C const char *
  var cstr: [CChar]? { return self.cString(using: .utf8) }
  
  /// First non white char sequence
  var trim: String {
    var tmp = str_trim(cstr)
    let ret = String(cString: tmp!)
    str_release(&tmp)
    return ret
  }

  /**
   Return UILabel that is just large enough to encompass the actual String
   
   `label` returns to given font (default: preferred for body text) a label
   containing the current object's string of characters so that the string
   just fits. The label returned consists of one row of characters unless
   newlines are enclosed in the string.
   
   - Parameters:
   - font: the text font to use in the label
   - Returns: A new UILabel containing the current String
   */
  func label(font: UIFont? = nil) -> UILabel {
    var fnt: UIFont
    if font == nil { fnt = UIFont.preferredFont(forTextStyle: .body) }
    else { fnt = font! }
    let label =  UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude,
                                       height: CGFloat.greatestFiniteMagnitude))
    label.numberOfLines = 0
    label.text = self
    label.font = fnt
    label.sizeToFit()
    return label
  }
  
  /**
   Returns the size in a given font
   
   `size` returns to given font (default: preferred for body text) a CGSize just
   big enough to fit the string of characters.
   
   - Parameters:
   - font: the text font used to calculate the size
   - Returns: the size of the smallest box encompassing the String
   */
  func size(font: UIFont? = nil) -> CGSize {
    return label(font:font).frame.size
  }
  
  /// allMatches returns an array of strings representing all matches
  /// of the passed regular expression in 'self'.
  func allMatches(regexp: String) -> [String] {
    do {
      let re = try NSRegularExpression(pattern: regexp)
      let res = re.matches(in: self, range: NSRange(self.startIndex..., in: self))
      return res.map {
        String(self[Range($0.range, in: self)!])
      }
    } catch { return [] }
  }
  
  /// groupMatches returns an array of strings representing matches of the passed 
  /// regular expression. 
  /// 
  /// Each match itself is an array
  /// of strings matching the groups used in the regular expression. The first
  /// element of the String array is always the completely matched regular expression.
  /// Ie. "<123> <456>".groupMatches(regexp: #"<(\d+)>"#) yields 
  /// [["<123>", "123"], ["<456>", "456"]].
  /// If a group contains subgroups then the match representing the enclosing 
  /// group preceeds the subgroup in the array. Ie "<123>".groupMatches(#"<(1(\d+))>"#)
  /// returns ["<123>", "123", "23"].
  func groupMatches(regexp: String) -> [[String]] {
    do {
      let re = try NSRegularExpression(pattern: regexp)
      let res = re.matches(in: self, range: NSRange(self.startIndex..., in: self))
      return res.map { match in
        return (0..<match.numberOfRanges).map {
          let rangeBounds = match.range(at: $0)
          guard let range = Range(rangeBounds, in: self) else { return "" }
          return String(self[range])
        }
      }
    } catch let error {
      Log.fatal(error)
      return []
    }
  }
  
  /// Append Character to String
  @discardableResult
  static func +=(lhs: inout String, rhs: Character) -> String {
    lhs.append(rhs)
    return lhs
  }
  
  /// Append CustomStringConvertible to String
  @discardableResult
  static func +=<Type: CustomStringConvertible>(lhs: inout String, rhs: Type) -> String {
    lhs.append(rhs.description)
    return lhs
  }
  
  /// Return repititive String
  /// Eg. "abc" * 3 returns "abcabcabc"
  static func *<Type: BinaryInteger>(lhs: String, rhs: Type) -> String {
    var ret = ""
    let n = Int(rhs)
    for _ in 0..<n { ret += lhs }
    return ret
  }
  static func *<Type: BinaryInteger>(lhs: Type, rhs: String) -> String {
    return rhs*lhs
  }
  
  /** Returns a String with is quoted, ie. surrounded by quotes. 
 
   In addition the following characters are translated:
     \                 :   \\
     "                 :   \"
     linefeed          :   \n
     carriage return   :   \r
     backspace         :   \b
     tab               :   \t
   */
  func quote() -> String {
    var s = "\""
    for ch in self {
      switch ch {
      case "\"" :  s += "\\\""
      case "\\" :  s += "\\\\"
      case "\n" :  s += "\\n"
      case "\r" :  s += "\\r"
      case "\t" :  s += "\\t"
      default: s += ch
      }
    }
    return s + "\""
  }
  
  /** Returns a String with is dequoted, ie. surrounding quotes are removed.
   
   In addition the following escaped characters are translated:
     \\ :  \
     \" :  "
     \n :  linefeed
     \r :  carriage return
     \t :  tab
   */
  func dequote() -> String {
    var s = ""
    var wasEscaped = false
    var isFirst = true
    for ch in self {
      if isFirst && ch == "\"" { isFirst = false; continue }
      if wasEscaped {
        switch ch {
        case "\"" :  s += "\""
        case "\\" :  s += "\\"
        case "n"  :  s += "\n"
        case "r"  :  s += "\r"
        case "t"  :  s += "\t"
        default: s += "\\"; s += ch
        }
        wasEscaped = false
      }
      else {
        if ch == "\\" { wasEscaped = true }
        else { s += ch }
      }
    }
    if s.last == "\"" { s.remove(at: s.index(before: s.endIndex)) }
    return s
  }
  
  /**
   Returns an indented String where each row of characters is indented 
   by the number of spaces given with 'by'.
   
   If the argument 'first' has been given, this String is inserted in front of 
   the first row which is not indented. All succeeding rows are indented as usual.
   Eg. "abc\ndef".indent(by: 2, first: "- ") will result in: "- abc\n  def".
   **/
  func indent(by indent: Int, first: String? = nil) -> String {
    guard indent > 0 else { return self }
    var wasNl = true
    var ret = ""
    if let str = first { ret = str; wasNl = false }
    for ch in self {
      if wasNl { ret += String(repeating: " ", count: indent); wasNl = false }
      ret += ch
      if ch.isNewline { wasNl = true }
    }
    return ret
  }
  
  /// Returns true if self is case insensitive equal to "true", false otherwise
  var bool: Bool { return self.lowercased() == "true" }
  
} // extension String

