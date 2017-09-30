//
//  Preference.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class Preference {
  static let kLibraryPath = "LibraryPath"
  
  static func libraryPath() -> URL? {
    #if TEST
      return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Doughtnut_test")
    #else
      if let path = UserDefaults.standard.string(forKey: kLibraryPath) {
        return URL(fileURLWithPath: path)
      } else {
        return nil
      }
    #endif
  }
  
  static func defaultLibraryPath() -> URL {
    #if TEST
      let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Doughtnut_test")
    #elseif DEBUG
      let path = Preference.userMusicPath().appendingPathComponent("Doughnut_dev")
    #else
      let path = Preference.userMusicPath().appendingPathComponent("Doughnut")
    #endif
    
    createLibraryIfNotExists(path)
    
    return path
  }
  
  static func createLibraryIfNotExists(_ url: URL) {
    var isDir = ObjCBool(true)
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) == false {
      do {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("Failed to create directory \(error)")
      }
    }
  }
  
  private static func userMusicPath() -> URL {
    if let path = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first {
      return path
    } else {
      return URL(string: NSHomeDirectory())!
    }
  }
}