import Foundation
import AVFoundation
import Aperture

func showUsage() {
  print(
    """
    Usage:
      aperture <options>
      aperture list-screens
      aperture list-audio-devices
    """
  )
}

switch CLI.arguments.first {
case "list-screens":
  print(Aperture.Devices.screen(), to: .standardError)
  exit(0)
case "list-audio-devices":
  // Uses stderr because of unrelated stuff being outputted on stdout
  print(Aperture.Devices.audio(), to: .standardError)
  exit(0)
case .none:
  showUsage()
  exit(1)
default:
  // print(toCLI.arguments.first!, to: .standardError)
  // try record()
	exit(1)
}