//
//  FileDataModel.swift
//  Audiocapture
//
//  Created by Maja Taseska on 13/08/2018.
//  Copyright © 2018 Maja Taseska. All rights reserved.
//

import UIKit
import AVFoundation



class Recording {
    
    // ------- Class attributes (defined according to the API from Spott)
    
    // Attributes inferred from the APIs and the sensors
    var microphoneLocation: String = ""
    var microphoneType: String = ""
    var startTimestamp = ""
    var endTimestamp = ""
    
    // Attributes from the user questionnaire
    var distance: String = ""
    var filename = ""
    var onTable: Bool = false // if required we will make it programmatic
    var metadata = ""
    var roomType = ""
    
    //-------- Constructor: default
    init() {}
    
    //-------- Constructor: with parameters
    convenience init (param1:String, param2: String) {
        self.init()
        //set whatever properties you like to param1, param2, etc
    }
    
    
    //-------- METHOD: start recording
   
    func start(audioEngine: AVAudioEngine, outputFile: AVAudioFile) {
        // Install tap on input to record audio
        let aformat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: aformat, block:
            {(buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                do {
                    try outputFile.write(from: buffer)
                }
                catch {
                    print(NSString(string:"Write failed"))
                }
        })
        
        // Start the audio engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to initialize the audio engine")
        }
        
    }
    
    
    //-------- METHOD: stop recording
    func stop(audioEngine: AVAudioEngine) {
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
//        //Convert the audio file from .caf to mp4
//        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//
//        let outputUrl = paths[0].appendingPathComponent("\(self.filename).mp4")
//        let assetUrl = paths[0].appendingPathComponent("\(self.filename).caf")
//        
//        let asset = AVAsset.init(url: assetUrl)
//        let exportSession = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetHighestQuality)
//
//        exportSession?.outputFileType = AVFileType.mp4
//        exportSession?.outputURL = outputUrl
//        exportSession?.metadata = asset.metadata
//        exportSession?.exportAsynchronously(completionHandler: {
//            if (exportSession?.status == .completed)
//            {
//                print("AV export succeeded.")
//            }
//            else if (exportSession?.status == .cancelled)
//            {
//                print("AV export cancelled.")
//            }
//            else
//            {
//                print ("Error is \(String(describing: exportSession?.error))")
//
//            }
//        })
    }
        
    
    //-------- METHOD: set timestamp
    func setTimestamp(forTimeAt: timestamp){
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let timestamp_string  = formatter.string(from: now)

        if forTimeAt == .start {
            self.startTimestamp = timestamp_string
        } else if forTimeAt == .end {
            self.endTimestamp = timestamp_string
        }
    }
    
    //-------- Create a dictionary from the record objects (required for http requests)
    func createDictionary() -> [String:Any] {
        
        let dictionary = ["distance": Int(self.distance)!,
                          "endTimestamp": self.endTimestamp,
                          "filePath": "\(self.filename).caf",
                          "metaData": self.metadata,
                          "microphoneLocation": "\(self.microphoneLocation)",
                          "microphoneType": "\(self.microphoneType)",
                          "onTable": self.onTable,
                          "roomType": self.roomType,
                          "startTimestamp": self.endTimestamp] as [String : Any]
        
        return dictionary
        
    }
    
    
}
