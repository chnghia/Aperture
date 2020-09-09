import Vision

class FaceDetectRequestResultModel {

    var faces: [FaceResultModel] = []
    var numberOfFace: Int = 0
    
    init(requestResults: [VNCoreMLFeatureValueObservation]) {
        // get observation by name
        let outputBox = requestResults.first(where: {$0.featureName == "output_box"})
        let outputScore = requestResults.first(where: {$0.featureName == "output_score"})
        let outputN = requestResults.first(where: {$0.featureName == "output_n"})
        // get data array
        let outputBoxData = self.getDataArray(from: outputBox, count: 200)
        let outputScoreData = self.getDataArray(from: outputScore, count: 50)
        let outputNData = self.getDataArray(from: outputN, count: 1)
        // init properties
        numberOfFace = Int(outputNData.first ?? 0)
        for indexFace in 0..<numberOfFace {
            let i = indexFace * 4
            let face = FaceResultModel(detectFace: [outputBoxData[i], outputBoxData[i+1], outputBoxData[i+2], outputBoxData[i+3]], confidence: outputScoreData[indexFace])
            faces.append(face)
        }
    }
    
    /// Get Data array from VNCoreMLFeatureValueObservation
    /// - Parameters:
    ///   - observation: VNCoreMLFeatureValueObservation
    ///   - count: number of elements
    private func getDataArray(from observation: VNCoreMLFeatureValueObservation?, count: Int) -> [Double] {
        guard let multiArray = observation?.featureValue.multiArrayValue else {return []}
        let featurePointer = UnsafePointer<Double>(OpaquePointer(multiArray.dataPointer))
        let resultArray = Array(UnsafeBufferPointer(start: featurePointer, count: count))
        return resultArray
    }
}

class FaceResultModel {
    var detectRect: [Double] = []
    var confidence: Double = 0
    
    init(detectFace: [Double], confidence: Double) {
        self.detectRect = detectFace
        self.confidence = confidence
    }
}
