//
//  EmotionAnalyze.swift
//  visualizeemotion
//
//  Created by HungNV on 7/9/20.
//  Copyright © 2020 HungNV. All rights reserved.
//

import Foundation

class EmotionAnalyze {
    
    // dictionary to count number of data appearance
    private var dict = [[Float32: Int]](repeating: [:], count: 5)
    // array to store data
    private var array = [[Float32]](repeating: [], count: 5)
    
    func adopt(data: [Float32]) {
//        log(label: "[d Input]", data)
        guard dict.count > 4, array.count > 4 else {return}
        // round from 0.01 to 0.1
        let temp = data.map {Float32(round(10 * $0) / 10)}
        // append data
        for i in 0...4 {
            // append data to stored
            array[i].append(data[i])
            // increase data count
            dict[i][temp[i]] = (dict[i][temp[i]] ?? 0) + 1
        }
    }
    
    func getMostAppearAverage() -> [Float32] {
        // prepare returned array
        var averageArray = array.map{$0.last ?? 0}
        guard dict.count > 4, array.count > 4 else {return [0,0,0,0,0]}
        for i in 0...4 {
            // if found the most appear value
            if let mostAppear = dict[i].max(by: { $0.1 < $1.1 })?.key {
                // start filter near by value and sum them
                let reduce = array[i].reduce((Float32(0), 0)) { (result, element) -> (Float32, Int) in
                    if max(mostAppear - 0.05, 0) <= element && element < min(mostAppear + 0.05, 1) {
                        return (result.0 + element, result.1 + 1)
                    }
                    return (result.0, result.1)
                }
                // calculate the average of most appear values
                if reduce.1 > 0 {
                    averageArray[i] = reduce.0 / Float32(reduce.1)
                }
            }
        }
//        log(label: "[d output]", "\(array[0].count)---\(averageArray)")
        // clear data
        clear()
        return averageArray
    }
    
    func clear() {
        dict = [[Float32: Int]](repeating: [:], count: 5)
        array = [[Float32]](repeating: [], count: 5)
    }
}
