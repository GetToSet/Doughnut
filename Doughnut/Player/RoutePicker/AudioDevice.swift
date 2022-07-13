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

import CoreAudio
import Foundation
import OSLog

// Based on https://stackoverflow.com/a/58618034/793916

final class AudioDevice {

  let audioDeviceID: AudioDeviceID

  static let log = OSLog.main(category: "AudioDevice")

  private(set) var hasOutputChannels: Bool = false
  private(set) var deviceName: String?

  init(deviceID: AudioDeviceID) {
    self.audioDeviceID = deviceID
    do {
      try updateHasOutput()
      try updateDeviceName()
    } catch {
      os_log(.error, log: Self.log, "AudioDevice.init failed with error: %{public}@", error.localizedDescription)
    }
  }

  private func updateHasOutput() throws {
    var address = AudioObjectPropertyAddress(
      mSelector: AudioObjectPropertySelector(kAudioDevicePropertyStreamConfiguration),
      mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
      mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
    )

    var propertySize: UInt32 = 0
    try Self.handleCoreAudio(
      AudioObjectGetPropertyDataSize(
        audioDeviceID,
        &address,
        UInt32(MemoryLayout<AudioObjectPropertyAddress>.size),
        nil,
        &propertySize
      )
    )

    let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(propertySize))

    defer {
      bufferList.deallocate()
    }

    try Self.handleCoreAudio(
      AudioObjectGetPropertyData(audioDeviceID, &address, 0, nil, &propertySize, bufferList)
    )

    let buffers = UnsafeMutableAudioBufferListPointer(bufferList)

    hasOutputChannels = buffers.contains { $0.mNumberChannels > 0 }
  }

  private func updateDeviceName() throws {
    var address = AudioObjectPropertyAddress(
      mSelector: AudioObjectPropertySelector(kAudioObjectPropertyName),
      mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
      mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
    )

    var name: CFString? = nil
    var propertySize = UInt32(MemoryLayout<CFString?>.size)

    try Self.handleCoreAudio(
      AudioObjectGetPropertyData(audioDeviceID, &address, 0, nil, &propertySize, &name)
    )

    deviceName = name as String?
  }

  @discardableResult
  func setAsDefaultDevice(isOutput: Bool) -> Bool {
    do {
      let selector = isOutput
        ? kAudioHardwarePropertyDefaultOutputDevice
        : kAudioHardwarePropertyDefaultInputDevice

      var deviceIdPropertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(selector),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
      )

      var deviceID = audioDeviceID
      let propertySize = UInt32(MemoryLayout.size(ofValue: audioDeviceID))
      try Self.handleCoreAudio(
        AudioObjectSetPropertyData(
          AudioObjectID(kAudioObjectSystemObject),
          &deviceIdPropertyAddress,
          0,
          nil,
          propertySize,
          &deviceID
        )
      )
      return true
    } catch {
      os_log(.error, log: Self.log, "setAsDefaultDevice failed with error: %{public}@", error.localizedDescription)
      return false
    }
  }

  // MARK - Static Methods

  static func getAllDevices() -> [AudioDevice]? {
    do {
      var address = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
      )

      var propertySize: UInt32 = 0
      try Self.handleCoreAudio(
        AudioObjectGetPropertyDataSize(
          AudioObjectID(kAudioObjectSystemObject),
          &address,
          0,
          nil,
          &propertySize
        )
      )

      let deviceNum = Int(propertySize / UInt32(MemoryLayout<AudioDeviceID>.size))
      var deviceIDs = Array<AudioDeviceID>(repeating: AudioDeviceID(), count: deviceNum)

      try Self.handleCoreAudio(
        AudioObjectGetPropertyData(
          AudioObjectID(kAudioObjectSystemObject),
          &address,
          0,
          nil,
          &propertySize,
          &deviceIDs
        )
      )

      return (0..<deviceNum).compactMap { i in
        AudioDevice(deviceID: deviceIDs[i])
      }
    } catch {
      os_log(.error, log: log, "getAllDevices failed with error: %{public}@", error.localizedDescription)
      return nil
    }
  }

  static func getSelectedDevice(isOutput: Bool) -> AudioDevice? {
    do {
      let selector = isOutput ? kAudioHardwarePropertyDefaultOutputDevice
                              : kAudioHardwarePropertyDefaultInputDevice

      var address = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(selector),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
      )

      var id = AudioObjectID(kAudioObjectSystemObject)
      var propertySize = UInt32(MemoryLayout.size(ofValue: id))

      try Self.handleCoreAudio(
        AudioObjectGetPropertyData(
          id,
          &address,
          0,
          nil,
          &propertySize,
          &id
        )
      )
      return AudioDevice(deviceID: id)
    } catch {
      os_log(.error, log: log, "getSelectedDevice failed with error: %{public}%", error.localizedDescription)
      return nil
    }
  }

  private static func handleCoreAudio(_ errorCode: OSStatus) throws {
    if errorCode != kAudioHardwareNoError {
      throw NSError(
        domain: NSOSStatusErrorDomain,
        code: Int(errorCode),
        userInfo: [NSLocalizedDescriptionKey: "CoreAudioError: \(errorCode)"]
      )
    }
  }

}

extension AudioDevice: Equatable {

  static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
    return lhs.audioDeviceID == rhs.audioDeviceID
  }

}
