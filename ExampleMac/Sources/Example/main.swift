import Foundation
import AVFoundation
import Aperture
import Vision
import CoreImage

var coreFaceEmotionMLModel: VNCoreMLModel?
var coreModel: VNCoreMLModel?

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

func checkEmotion(for image: CIImage) {
    print("start check emotion")
    do {
        if let model: VNCoreMLModel = coreFaceEmotionMLModel {
            let request = VNCoreMLRequest(model: model, completionHandler: { request, error in
                guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else { fatalError("Unexpected result type from VNCoreMLRequest.") }
                guard let multiArray = observations[0].featureValue.multiArrayValue else { fatalError("Can't get best result.") }
                let featurePointerFloat = UnsafePointer<Float32>(OpaquePointer(multiArray.dataPointer))
                let resultArray = Array(UnsafeBufferPointer(start: featurePointerFloat, count: 5))
                let result = resultArray.map{ round(100 * $0) / 100 }
                print(result)
                // DispatchQueue.main.async {
                //     self.emotionAnalyze.adopt(data: result)
                //     self.updateResult()
                // }
            })
            let handler = VNImageRequestHandler(ciImage: image, options: [:])
            try handler.perform([request])
        }
    } catch {
        print("error coreFaceEmotionMLModel handle")
    }
}

func detectFaceByModel(request: VNRequest, sourceImage: CIImage, error: Error?) {
    guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
        return
    }
    
    let result = FaceDetectRequestResultModel(requestResults: observations)
    print("detectFaceByModel: number of faces ")
    print(result.faces.count)
    // let hasManyFaces = DEBUG_DRAW_BOX_PRINT_LOG ? true : (result.faces.count > 1)
    // if has detected face
    // 1544 × 925
    var originSize: (w: CGFloat, h: CGFloat)? = (CGFloat(1544), CGFloat(925))
    // let originSize = 1544 × 925
    if let detectedFace = result.faces.first, detectedFace.confidence > 0.8, let originSize = originSize {
        print("[detectedFace]", "detected face bounding box face rect: \(detectedFace.detectRect)")
        // convert face rect in image
        let adjustedWidth = CGFloat(detectedFace.detectRect[2]) / 640 * originSize.w
        let adjustedHeight = CGFloat(detectedFace.detectRect[3]) / 640 * originSize.h
        
        let adjustedX = (CGFloat(detectedFace.detectRect[0]) / 640 * originSize.w) - (adjustedWidth/2)
        let adjustedY = (CGFloat(detectedFace.detectRect[1]) / 640 * originSize.h) - (adjustedHeight/2)
        let adjustedXMirrored = originSize.w - (CGFloat(detectedFace.detectRect[0]) / 640 * originSize.w) - (adjustedWidth/2)
        let adjustedYMirrored = originSize.h - (CGFloat(detectedFace.detectRect[1]) / 640 * originSize.h) - (adjustedHeight/2)
        
        let faceRect = CGRect(x: adjustedX, y: adjustedY, width: adjustedWidth, height: adjustedHeight)

        /// Start - Change orientation when support landscape left/right
        let side = min(adjustedWidth, adjustedHeight)
        var midX: CGFloat = 0.0
        var midY: CGFloat = 0.0
        midX = adjustedX + adjustedWidth / 2
        midY = adjustedY + adjustedHeight / 2
        let faceSquareX = min(max(0, midX - side / 2), originSize.w - side)
        let faceSquareY = min(max(0, midY - side / 2), originSize.h - side)
        var fixCropFrame: CGRect = CGRect.zero
        fixCropFrame = CGRect(x: faceSquareY, y: faceSquareX, width: side, height: side)
        print("[fixCropFrame]", "detected face bounding box face rect: \(fixCropFrame)")
        let croppedFace = sourceImage.cropped(to: fixCropFrame)
        print("[croppedFace]", "detected face bounding box face rect: \(croppedFace)")
        checkEmotion(for: croppedFace)
    }
}

func resizeImg(sourceImage: CIImage?) -> CIImage? {
  let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!

  // Desired output size
  let targetSize = NSSize(width:640, height:640)

  // Compute scale and corrective aspect ratio
  let scale = targetSize.height / (sourceImage?.extent.height)!
  let aspectRatio = targetSize.width/((sourceImage?.extent.width)! * scale)

  // Apply resizing
  resizeFilter.setValue(sourceImage, forKey: kCIInputImageKey)
  resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
  resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
  return resizeFilter.outputImage
}

func showModel() {
  print("showModel")
  var faceSequenceHandler = VNSequenceRequestHandler()
  print("define showModel")

  let context = CIContext()
  let inputURL = URL(string: "file:///Users/nghia/workspace/vfa_proj/screen-recorder-oss/Aperture/ExampleMac/screen_frame.png")!
  let sourceImage = CIImage(contentsOf: inputURL)
  let outputImage = resizeImg(sourceImage: sourceImage)!

  do {
      coreModel = try VNCoreMLModel(for: model_plus_quantization().model)
      coreFaceEmotionMLModel = try VNCoreMLModel(for: emotion_ver2().model)
  } catch {
      print("error here")
  }

  // guard let faceBuffer = inputImage.pixelBuffer(width: 640, height: 640) else { return }
  do {
      if let model: VNCoreMLModel = coreModel {
          let detectFaceRequest = VNCoreMLRequest(model: model) { (request, error) in
              print("detectFaceRequest result")
              detectFaceByModel(request: request, sourceImage: sourceImage!, error: error)
              // self.checkEmotionQueue.async {
              //     self.detectFaceByModel(request: request, image: visionImage, error: error, srcBuffer: srcBuffer)
              // }
          }
          //log(label: "[d capture]", "start detect image ")
          try faceSequenceHandler.perform([detectFaceRequest], on: outputImage)
      }
  }
  catch {
      print("error coreModel handle")
  }
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
case "show-model":
  try showModel()
  exit(0)
case .none:
  showUsage()
  exit(1)
default:
  // print(toCLI.arguments.first!, to: .standardError)
  // try record()
	exit(1)
}
