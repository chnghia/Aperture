import Foundation
import AVFoundation
import Aperture
import Vision
import CoreImage


var coreFaceEmotionMLModel: VNCoreMLModel?
var coreModel: VNCoreMLModel?
let outputcsvURL = URL(string: "file:///Users/nghia/workspace/github.com/chnghia/Aperture/ExampleMac/output.csv")!
var emotionAnalyze = EmotionAnalyze()
var validEmotion:[Float32] = [Float32]()
var startTimes: [Double] = []

func record() throws {
    // let options: Options = try CLI.arguments.first!.jsonDecoded()
    let destination = URL(string: "file:///Users/nghia/workspace/github.com/chnghia/Aperture/ExampleMac/recording.mp4")!
    
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
      Example <options>
      Example list-screens
      Example list-audio-devices
      Example record
      Example record-emotion
      Example show-models
    """
    )
}

func getEmotionDict(_ emotion: [Float32]) -> [String : Any] {
    var dict = [String : Any]()
    if emotion.count > 4 {
        dict = ["neutral": emotion[0]*100,
                "happy": emotion[1]*100,
                "sad": emotion[2]*100,
                "angry": emotion[3]*100,
                "surprised": emotion[4]*100,
                "updateAt": Date().toStringUTC(dateFormat: .yyyyMMddHHmmss)
        ]
    } else {
        dict = ["neutral": 0.0,
                "happy": 0.0,
                "sad": 0.0,
                "angry": 0.0,
                "surprised": 0.0,
                "updateAt": Date().toStringUTC(dateFormat: .yyyyMMddHHmmss)
        ]
    }
    return dict
}

func checkEmotion(for image: CIImage) {
    //    print("start check emotion")
    do {
        if let model: VNCoreMLModel = coreFaceEmotionMLModel {
            let request = VNCoreMLRequest(model: model, completionHandler: { request, error in
                guard let observations = request.results as? [VNCoreMLFeatureValueObservation]
                else { fatalError("Unexpected result type from VNCoreMLRequest.") }
                guard let multiArray = observations[0].featureValue.multiArrayValue
                else { fatalError("Can't get best result.") }
                
                let featurePointerFloat = UnsafePointer<Float32>(OpaquePointer(multiArray.dataPointer))
                let resultArray = Array(UnsafeBufferPointer(start: featurePointerFloat, count: 5))
                let result = resultArray.map { round(100 * $0) / 100 }
                
                let elapsed = NSDate().timeIntervalSince1970 - startTimes.remove(at: 0)
                
                print("execute time: \(elapsed) FPS: \(1/elapsed)", to: .standardOutput)
                
                emotionAnalyze.adopt(data: result)
                validEmotion = emotionAnalyze.getMostAppearAverage()
                let dict = getEmotionDict(validEmotion)
                print(dict, to: .standardOutput)
                var csvResult = "\(dict["neutral"] ?? 0),\(dict["happy"] ?? 0),\(dict["sad"] ?? 0),\(dict["angry"] ?? 0),\(dict["surprised"] ?? 0),\(dict["updateAt"]!)"
                print(csvResult, to: .standardOutput)
                // do {
                //     try csvResult.appendLineToURL(fileURL: outputcsvURL)
                // }
                // catch {
                //     print("Could not write to file")
                // }
                // DispatchQueue.main.async {
                //     self.emotionAnalyze.adopt(data: result)
                //     self.updateResult()
                // }
            })
            let targetSize = NSSize(width:60, height:60)
            let resizedImage = resizeImg(sourceImage: image, targetSize: targetSize)!
            let handler = VNImageRequestHandler(ciImage: resizedImage, options: [:])
            try handler.perform([request])
        }
    } catch {
        print("error coreFaceEmotionMLModel handle")
    }
}

func detectFaceByModel(request: VNRequest, sourceImage: CIImage, resizedImage: CIImage, originSize: (w: CGFloat, h: CGFloat)?, error: Error?) {
    guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
        print("error observations return")
        return
    }
    
    let result = FaceDetectRequestResultModel(requestResults: observations)
    //    print("detectFaceByModel: number of faces \(result.faces.count)")
    // let hasManyFaces = DEBUG_DRAW_BOX_PRINT_LOG ? true : (result.faces.count > 1)
    // if has detected face
    // 1544 × 925
    // var originSize: (w: CGFloat, h: CGFloat)? = (CGFloat(1544), CGFloat(925))
    // let originSize = 1544 × 925
    if let detectedFace = result.faces.first, detectedFace.confidence > 0.8, let originSize = originSize {
        //        print("[detectedFace]", "detected face bounding box face rect: \(detectedFace.detectRect) \(detectedFace.confidence)")
        
        //        let croppedResizedFace = resizedImage.cropped(to: detectedFace.detectRect)
        
        // convert face rect in image
        let adjustedWidth = CGFloat(detectedFace.detectRect[2]) / 640 * originSize.w
        let adjustedHeight = CGFloat(detectedFace.detectRect[3]) / 640 * originSize.h
        
        let adjustedX = (CGFloat(detectedFace.detectRect[0]) / 640 * originSize.w) - (adjustedWidth/2)
        let adjustedY = (CGFloat(detectedFace.detectRect[1]) / 640 * originSize.h) - (adjustedHeight/2)
        
        let faceRect = CGRect(x: adjustedX, y: adjustedY, width: adjustedWidth, height: adjustedHeight)
        
        let croppedFace = sourceImage.cropped(to: faceRect)
        // print("[croppedFace]", "detected face bounding box face rect: \(croppedFace)")
        // let context = CIContext(options: nil)
        // let colorSpace = croppedFace.colorSpace
        // let jpeg = context.jpegRepresentation(of: croppedFace, colorSpace: colorSpace!, options: [:])
        // let croppedURL = URL(string: "file:///Users/nghia/workspace/vfa_proj/screen-recorder-oss/Aperture/ExampleMac/screen_frame_cropped.jpg")!
        // do {
        //     try jpeg?.write(to: croppedURL)
        // } catch {
        //     print("error write to jpeg")
        // }
        checkEmotion(for: croppedFace)
    }
}

func resizeImg(sourceImage: CIImage?, targetSize: NSSize) -> CIImage? {
    let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!
    
    // Desired output size∑
    // let targetSize = NSSize(width:640, height:640)
    
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
    print("showModel", to: .standardError)
    var faceSequenceHandler = VNSequenceRequestHandler()
    
    let context = CIContext()
    let inputURL = URL(string: "file:///Users/nghia/workspace/github.com/chnghia/Aperture/ExampleMac/screen_frame.png")!
    let sourceImage = CIImage(contentsOf: inputURL)
    let targetSize = NSSize(width:640, height:640)
    let resizedImage = resizeImg(sourceImage: sourceImage, targetSize: targetSize)!
    // startTime =  NSDate().timeIntervalSince1970
    
    
    do {
        coreModel = try VNCoreMLModel(for: model_plus_quantization().model)
        coreFaceEmotionMLModel = try VNCoreMLModel(for: emotion_ver2().model)
    } catch {
        print("error here")
    }
    
    var originSize: (w: CGFloat, h: CGFloat)? = (sourceImage!.extent.width, sourceImage!.extent.height)
    //  print("originSize: \(originSize)")
    
    do {
        if let model: VNCoreMLModel = coreModel {
            let detectFaceRequest = VNCoreMLRequest(model: model) { (request, error) in
                detectFaceByModel(request: request, sourceImage: sourceImage!, resizedImage: resizedImage, originSize: originSize, error: error)
            }
            startTimes.append(NSDate().timeIntervalSince1970)
            try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
            startTimes.append(NSDate().timeIntervalSince1970)
            try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
            startTimes.append(NSDate().timeIntervalSince1970)
            try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
            startTimes.append(NSDate().timeIntervalSince1970)
            try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
            startTimes.append(NSDate().timeIntervalSince1970)
            try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
            startTimes.append(NSDate().timeIntervalSince1970)
            try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
            startTimes.append(NSDate().timeIntervalSince1970)
            try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
            startTimes.append(NSDate().timeIntervalSince1970)
            try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
        }
    }
    catch {
        print("error coreModel handle", to: .standardOutput)
    }
}


func recordEmotion() throws {
    print("recordEmotion", to: .standardOutput)
    
    let destination = URL(string: "file:///Users/nghia/workspace/github.com/chnghia/Aperture/ExampleMac/recording.mp4")!
    
    var csvString = "\("neutral"),\("happy"),\("sad"),\("angry"),\("surprised"),\("date")\n"
    do {
        try csvString.write(to: outputcsvURL, atomically: true, encoding: .utf8)
    } catch {
        print("error creating file", to: .standardOutput)
    }
    
    var faceSequenceHandler = VNSequenceRequestHandler()
    do {
        coreModel = try VNCoreMLModel(for: model_plus_quantization().model)
        coreFaceEmotionMLModel = try VNCoreMLModel(for: emotion_ver2().model)
    } catch {
        print("error here", to: .standardError)
    }
    
    
    let recorder = try ApertureFrame(
        destination: destination
    )
    print("ApertureFrame initial", to: .standardOutput)
    
    recorder.onStart = {
        print("R")
    }
    
    recorder.onFinish = {
        print($0, to: .standardError)
        exit(0)
    }
    
    recorder.onCapture = { (captureOutput, sampleBuffer) in
        guard let srcBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let originSize: (w: CGFloat, h: CGFloat) = (CGFloat(CVPixelBufferGetWidth(srcBuffer)), CGFloat(CVPixelBufferGetHeight(srcBuffer)))
        //    print("originSize: width=\(originSize.w), height=\(originSize.h)")
        let sourceImage = CIImage(cvPixelBuffer: srcBuffer)
        
        let context = CIContext(options: nil)
        let colorSpace = sourceImage.colorSpace
        let jpeg = context.jpegRepresentation(of: sourceImage, colorSpace: colorSpace!, options: [:])
        let sourceURL = URL(string: "file:///Users/nghia/workspace/github.com/chnghia/Aperture/ExampleMac/screen_frame_source.jpg")!
        do {
          try jpeg?.write(to: sourceURL)
        } catch {
          print("error write to jpeg")
        }
        
        let targetSize = NSSize(width:640, height:640)
        let resizedImage = resizeImg(sourceImage: sourceImage, targetSize: targetSize)!
        
        let jpegResized = context.jpegRepresentation(of: resizedImage, colorSpace: colorSpace!, options: [:])
        let resizedURL = URL(string: "file:///Users/nghia/workspace/github.com/chnghia/Aperture/ExampleMac/screen_frame_source_resized.jpg")!
        do {
          try jpegResized?.write(to: resizedURL)
        } catch {
          print("error write to jpeg")
        }
        
        do {
            if let model: VNCoreMLModel = coreModel {
                let detectFaceRequest = VNCoreMLRequest(model: model) { (request, error) in
                    detectFaceByModel(request: request, sourceImage: sourceImage, resizedImage: resizedImage, originSize: originSize, error: error)
                }
                //log(label: "[d capture]", "start detect image ")
                startTimes.append(NSDate().timeIntervalSince1970)
                try faceSequenceHandler.perform([detectFaceRequest], on: resizedImage)
            }
        }
        catch {
            print("error coreModel handle", to: .standardError)
        }
        
    }
    
    CLI.onExit = {
        recorder.stop()
        // Do not call `exit()` here as the video is not always done
        // saving at this point and will be corrupted randomly
    }
    
    recorder.start()
    
    setbuf(__stdoutp, nil)
    RunLoop.main.run()
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
case "record-emotion":
    try recordEmotion()
case "show-models":
    print("showModel", to: .standardOutput)
    showModel()
    exit(0)
case .none:
    showUsage()
    exit(1)
default:
    // print(toCLI.arguments.first!, to: .standardError)
    // try record()
    exit(1)
}
