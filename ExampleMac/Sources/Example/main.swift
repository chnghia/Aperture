import Foundation
import AVFoundation
import Aperture

func record() throws {
  // let options: Options = try CLI.arguments.first!.jsonDecoded()
  let destination = URL(string: "file:///Users/nghia/workspace/vfa_proj/screen-recorder-oss/Aperture/ExampleMac/recording.mp4")!

  let recorder = try ApertureFrame(
    destination: destination
    // framesPerSecond: 30,
    // cropRect: nil,
    // showCursor: true,
    // highlightClicks: false,
    // screenId: .main,
    // audioDevice: nil,
    // videoCodec: "h264"
  )

  recorder.onStart = {
    print("R")
  }

  recorder.onFinish = {
    print($0, to: .standardError)
    exit(0)
  }

  // recorder.onError = {
  //   print($0, to: .standardError)
  //   exit(1)
  // }

  CLI.onExit = {
    recorder.stop()
    // Do not call `exit()` here as the video is not always done
    // saving at this point and will be corrupted randomly
  }

  recorder.start()

  setbuf(__stdoutp, nil)
  RunLoop.main.run()
}

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
case "record":
  try record()
case .none:
  showUsage()
  exit(1)
default:
  // print(toCLI.arguments.first!, to: .standardError)
  // try record()
	exit(1)
}