/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 - 2022 Chris Dyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import AppKit
import AVKit

import SimplyCoreAudio

final class RoutePickerView: AVRoutePickerView {

  override var intrinsicContentSize: NSSize {
    return CGSize(width: 32, height: 32)
  }

}

final class AudioRouteToolBarItem: NSToolbarItem, NSPopoverDelegate {

  enum Mode {
    case audioDevice
    case airPlay
  }

  var popover: NSPopover?

  private let simplyCoreAudio = SimplyCoreAudio()

  private var audioDeviceButton: NSButton!
  private var routePickerView: RoutePickerView!

  private var mode: Mode = .airPlay {
    didSet {
      updateButtonForMode()
    }
  }

  init() {
    super.init(itemIdentifier: NSToolbarItem.Identifier.doughnutAirPlay)

    NotificationCenter.default.addObserver(self, selector: #selector(playerChanged(_:)), name: .playerChanged, object: nil)

    initAudioDeviceButton()
    initRoutePickerView()

    updateButtonForMode()
  }

  @objc func playerChanged(_ notification: Notification) {
    if case .airPlay = mode, let player = notification.userInfo?["avPlayer"] as? AVPlayer {
      routePickerView.player = player
    }
  }

  private func initAudioDeviceButton() {
    let image: NSImage!

    if #available(macOS 11.0, *) {
      image = NSImage(
        systemSymbolName: "airplayaudio",
        accessibilityDescription: nil
      )!
    } else {
      image = NSImage()
    }

    let button: NSButton!
    button = NSButton(
      title: "",
      image: image,
      target: self,
      action: #selector(toolbarItemAction(_:))
    )
    button.stringValue = ""
    button.bezelStyle = .texturedRounded
    button.contentTintColor = .controlTextColor
  }

  private func initRoutePickerView() {
    routePickerView = RoutePickerView(frame: .zero)
    routePickerView.setRoutePickerButtonColor(.controlAccentColor, for: .active)
    for view in routePickerView.subviews {
      if let button = view as? NSButton {
        button.bezelStyle = .texturedRounded
      }
    }
  }

  private func updateButtonForMode() {
    switch mode {
    case .audioDevice:
      view = audioDeviceButton
      routePickerView.player = nil
    case .airPlay:
      view = routePickerView
    }
  }

  @objc func toolbarItemAction(_ sender: Any?) {
    guard let view = view else {
      return
    }

    let outputDevices = simplyCoreAudio.allOutputDevices
    let selectedOutputDevice = simplyCoreAudio.defaultOutputDevice

    let menu = NSMenu()
    for device in outputDevices {
      let menuItem = NSMenuItem(
        title: device.name,
        action: #selector(onSelectDevice(_:)),
        keyEquivalent: ""
      )
      menuItem.target = self
      menuItem.state = device == selectedOutputDevice ? .on : .off
      menuItem.representedObject = device
      menu.addItem(menuItem)
    }
    let point = NSPoint(
      x: view.frame.minX + 6,
      y: view.frame.minY - 4
    )
    menu.popUp(positioning: nil, at: point, in: view.superview)
  }

  @objc func onSelectDevice(_ sender: Any?) {
    guard
      let menuItem = sender as? NSMenuItem,
      let deviceToSelect = menuItem.representedObject as? AudioDevice
    else {
      return
    }
    deviceToSelect.isDefaultOutputDevice = true
  }

}
