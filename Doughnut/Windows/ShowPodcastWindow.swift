//
//  ShowPodcastViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/12/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa
import AVFoundation

class ShowPodcastWindowController: NSWindowController {
  override func windowDidLoad() {
    window?.isMovableByWindowBackground = true
    window?.titleVisibility = .hidden
    window?.styleMask.insert([ .resizable ])
    
    window?.standardWindowButton(.closeButton)?.isHidden = true
    window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window?.standardWindowButton(.toolbarButton)?.isHidden = true
    window?.standardWindowButton(.zoomButton)?.isHidden = true
  }
}

class ShowPodcastWindow: NSWindow {
  override var canBecomeKey: Bool {
    get {
      return true
    }
  }
}

class ShowPodcastViewController: NSViewController {
  @IBOutlet weak var artworkView: NSImageView!
  @IBOutlet weak var titleLabelView: NSTextField!
  @IBOutlet weak var authorLabelView: NSTextField!
  
  @IBOutlet weak var tabBarView: NSSegmentedControl!
  @IBOutlet weak var tabView: NSTabView!
  
  // Details Tab
  @IBOutlet weak var titleInputView: NSTextField!
  @IBOutlet weak var authorInputView: NSTextField!
  @IBOutlet weak var linkInputView: NSTextField!
  @IBOutlet weak var copyrightInputView: NSTextField!
  
  @IBAction func titleInputEvent(_ sender: NSTextField) {
    titleLabelView.stringValue = sender.stringValue
  }
  
  // Artwork Tab
  var modifiedImage = false
  @IBOutlet weak var artworkLargeView: NSImageView!
  
  // Description Tab
  var modifiedDescription = false
  @IBOutlet weak var descriptionInputView: NSTextField!
  
  // Options Tab
  
  
  
  override func viewDidLoad() {
    tabBarView.selectedSegment = 0
    tabView.selectTabViewItem(at: 0)
    
    artworkView.wantsLayer = true
    artworkView.layer?.borderWidth = 1.0
    artworkView.layer?.borderColor = NSColor.lightGray.cgColor
    artworkView.layer?.cornerRadius = 3.0
    artworkView.layer?.masksToBounds = true
  }
  
  var podcast: Podcast? {
    didSet {
      if let artwork = podcast?.image {
        artworkView.image = artwork
      }
      
      titleLabelView.stringValue = podcast?.title ?? ""
      authorLabelView.stringValue = podcast?.author ?? ""
      
      // Details View
      titleInputView.stringValue = podcast?.title ?? ""
      authorInputView.stringValue = podcast?.author ?? ""
      linkInputView.stringValue = podcast?.link ?? ""
      copyrightInputView.stringValue = podcast?.copyright ?? ""
      
      // Artwork View
      if let artwork = podcast?.image {
        artworkLargeView.image = artwork
      }
      
      // Description View
      descriptionInputView.stringValue = podcast?.description ?? ""
    }
  }
  
  @IBAction func switchTab(_ sender: NSSegmentedCell) {
    let clickedSegment = sender.selectedSegment
    tabView.selectTabViewItem(at: clickedSegment)
  }
  
  @IBAction func cancel(_ sender: Any) {
    self.view.window?.close()
  }
  
  @IBAction func savePodcast(_ sender: Any) {
    guard let podcast = podcast else { return }
    
    
    
    if modifiedImage {
      podcast.image = artworkLargeView.image
    }
    
    if modifiedDescription {
      podcast.description = descriptionInputView.stringValue
    }
    
    Library.global.save(podcast: podcast)
    
    self.view.window?.close()
  }
  
  @IBAction func addArtwork(_ sender: Any) {
    guard let podcast = podcast else { return }
    
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    
    panel.runModal()
    
    if let url = panel.url {
      if url.pathExtension == "jpg" || url.pathExtension == "png" {
        artworkLargeView.image = NSImage(contentsOfFile: url.path)
      } else {
        let asset = AVAsset(url: url)
        
        for item in asset.commonMetadata {
          if let key = item.commonKey, let value = item.value {
            if key.rawValue == "artwork" {
              artworkLargeView.image = NSImage(data: value as! Data)
            }
          }
        }
      }
      
      artworkView.image = artworkLargeView.image
      modifiedImage = true
    }
  }
  
}