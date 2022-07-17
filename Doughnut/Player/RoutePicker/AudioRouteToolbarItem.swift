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
import CoreAudio

final class AudioRouteToolBarItem: NSToolbarItem, NSPopoverDelegate {

  enum Mode {
    case connectedDevice
    case airPlay
  }

  var popover: NSPopover?

  init() {
    super.init(itemIdentifier: NSToolbarItem.Identifier.doughnutAirPlay)

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

    view = button
  }

  @objc func toolbarItemAction(_ sender: Any?) {
    guard let view = view else {
      return
    }
    let devices = (AudioDevice.getAllDevices() ?? []).filter { $0.hasOutputChannels }
    let selectedOutputDevice = AudioDevice.getSelectedDevice(isOutput: true)
    let menu = NSMenu()
    for device in devices {
      let menuItem = NSMenuItem(
        title: device.deviceName ?? "Unknown Device",
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
    deviceToSelect.setAsDefaultDevice(isOutput: true)
  }

}
