//
//  ViewController.swift
//  Audiocapture
//
//  Created by Maja Taseska on 13/08/2018.
//  Copyright © 2018 Maja Taseska. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, SetProperties {
    
    var flag_isRecording: Bool = false
    var flag_setupReady = false
    
    var fileUrl: URL!
    
    var audioSession = AVAudioSession.sharedInstance()
    var audioEngine = AVAudioEngine()
    var audioPlayer: AVAudioPlayer!
    var audioBuffer = AVAudioPCMBuffer()
    var outputFile = AVAudioFile()

    // Setting defaults for the audio session configuration
    var supportedPolarPatterns: [String] = []
    var selectedMicrophone: String =  ""

    // A file manager
    let fileManager = FileManager.default
    
    var newRecord = Recording()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the audio session: bottom microphone (always omnidirectional)
        initAudioSession()
        configAudioSessionMicrophoneSelection(preferredMic: AVAudioSessionOrientationBottom)
        configAudioSessionMicrophonePolarPattern(preferredPolarPattern: AVAudioSessionPolarPatternOmnidirectional)
        
        audioEngine.stop()
        audioEngine = AVAudioEngine()
        
        
        // Disable buttons that require a recording
        obuttonStartStop.isEnabled = false
        obuttonStartStop.isHighlighted = true
        
        obuttonListen.isUserInteractionEnabled = false
        obuttonEdit.isUserInteractionEnabled = false
        obuttonUpload.isUserInteractionEnabled = false
        obuttonDelete.isUserInteractionEnabled = false
       
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    //* MARK: Functions related to the AVAudioSession configuration
    //--------------------------------------------------------------
    func initAudioSession() {
        
        // Request permission to use microphone
        AVAudioSession.sharedInstance().requestRecordPermission{(hasPermission) in
            if hasPermission{
                print("Microphone usage permitted by the user")
            }
        }
        
        // Setup base configuration (mode and category)
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
        } catch {
            displayAlert(title: "Error", message: "Failed to set AVAudioSession category to play and record")
        }
        
        do {
            try audioSession.setActive(true)
        } catch {
            displayAlert(title: "Error", message: "Failed to activate the AVAudioSession")
        }
        
        do {
            try audioSession.setMode(AVAudioSessionModeMeasurement)
        } catch {
            displayAlert(title: "Error", message: "Failed to set the AVAudioSession in measurement mode")
        }
        
        print("Success: Category and Mode of AVAudioSession initialized!\n")
        
    }
    

    // -------
    
    func configAudioSessionMicrophoneSelection(preferredMic: String) {
       
        guard let inputs = audioSession.availableInputs else {return}
        guard let builtInMic = inputs.first(where: { $0.portType == AVAudioSessionPortBuiltInMic}) else {return}
        
        guard let dataSource = builtInMic.dataSources?.first(where: {$0.orientation == preferredMic }) else {
            print("The preferred microphone is not available")
            return
        }
        
        // Reset the polar pattern to omnidirectional
        do {
            try dataSource.setPreferredPolarPattern(AVAudioSessionPolarPatternOmnidirectional)
        } catch let error as NSError {
            print("Unable to preferred polar pattern: \(error.localizedDescription)")
        }
        
        // Set the preferred data source
        do {
            try builtInMic.setPreferredDataSource(dataSource)
        } catch let error as NSError {
            print("Unable to set preferred microphone: \(error.localizedDescription)")
        }
        
        // Set the built-in mic as the preferred input
        do {
            try audioSession.setPreferredInput(builtInMic)
        } catch let error as NSError {
            print("Unable to set preferred input port: \(error.localizedDescription)")
        }
        
        
        // Print Active Configuration
        audioSession.currentRoute.inputs.forEach { portDesc in
            //print("\nPort: \(portDesc.portType)")
            print("\nChanged microphone location!")
            if let ds = portDesc.selectedDataSource {
                print("Name: \(ds.dataSourceName)")
                print("Selected polar pattern: \(ds.selectedPolarPattern ?? "none")")
                //print("Supported polar patterns: \(ds.supportedPolarPatterns ?? ["[none]"]))")
                supportedPolarPatterns = ds.supportedPolarPatterns ?? ["[none]"]
            }
        }
        
     
        newRecord.microphoneLocation = preferredMic
        updateUIwhenPreferredMicChanged(preferredMic: preferredMic, supportedPolarPatterns: supportedPolarPatterns)
    }
    
    //-------
    
    func configAudioSessionMicrophonePolarPattern(preferredPolarPattern: String){
        
        // Get available inputs
        guard let inputs = audioSession.availableInputs else { return }
        
        // Find built-in mic
        guard let builtInMic = inputs.first(where: {
            $0.portType == AVAudioSessionPortBuiltInMic
        }) else { return }
        
        // Find the data source at the specified orientation
        guard let dataSource = builtInMic.dataSources?.first (where: {
            $0.orientation == selectedMicrophone
        }) else { return }
        
        // Set data source's polar pattern
        do {
            try dataSource.setPreferredPolarPattern(preferredPolarPattern)
        } catch let error as NSError {
            print("Unable to preferred polar pattern: \(error.localizedDescription)")
        }
        
        // Print active configuration
        print("\nChanged microphone polar pattern!")
        audioSession.currentRoute.inputs.forEach { portDesc in
            if let ds = portDesc.selectedDataSource {
                print("Name: \(ds.dataSourceName)")
                print("Selected polar pattern: \(ds.selectedPolarPattern ?? "none")")
            }
        }
        
        newRecord.microphoneType = preferredPolarPattern
        updateUIwhenPolarPatternChanged(preferredPolarPattern: preferredPolarPattern)
        
    }
    
    
    // -------
    func updateUIwhenPreferredMicChanged(preferredMic: String, supportedPolarPatterns: [String]){
        
        // Reset button states
        obuttonCardioid.isUserInteractionEnabled = true
        obuttonSubcardioid.isUserInteractionEnabled = true
        
        obuttonOmni.isSelected = true
        obuttonCardioid.isSelected = false
        obuttonSubcardioid.isSelected = false
        
        obuttonOmni.isHighlighted = false
        obuttonCardioid.isHighlighted = false
        obuttonSubcardioid.isHighlighted = false
        
        
        if preferredMic == "Bottom" {
            
            obuttonBottom.isSelected = true
            obuttonFront.isSelected = false
            obuttonBack.isSelected = false
        
            
        } else if preferredMic == "Front" {
            
            obuttonBottom.isSelected = false
            obuttonFront.isSelected = true
            obuttonBack.isSelected = false
            
        } else if preferredMic == "Back" {
            
            obuttonBottom.isSelected = false
            obuttonFront.isSelected = false
            obuttonBack.isSelected = true
            
        }
        
        if supportedPolarPatterns.contains("Cardioid") == false {
            obuttonCardioid.isUserInteractionEnabled = false
            obuttonCardioid.isHighlighted = true
        }
        
        if supportedPolarPatterns.contains("Subcardioid") == false {
            obuttonSubcardioid.isUserInteractionEnabled = false
            obuttonSubcardioid.isHighlighted = true
        }
        
    }
    
    
    //----
    func updateUIwhenPolarPatternChanged(preferredPolarPattern: String) {
        
        if preferredPolarPattern == "Omnidirectional" {
            
            obuttonOmni.isSelected = true
            obuttonCardioid.isSelected = false
            obuttonSubcardioid.isSelected = false
            
        } else if preferredPolarPattern == "Cardioid" {
            
            obuttonOmni.isSelected = false
            obuttonCardioid.isSelected = true
            obuttonSubcardioid.isSelected = false
            
        } else if preferredPolarPattern == "Subcardioid" {
            
            obuttonOmni.isSelected = false
            obuttonCardioid.isSelected = false
            obuttonSubcardioid.isSelected = true
            
        }
    
    }
    
    //* MARK: Passing data among screens
    //----------------------------------
    
    
    func userChangedProperties(filename: String, distance: String, table: String) {
        
        // Update the attributes of the current Record object
        newRecord.distance = distance
        newRecord.filename = filename
        if table == "t" {
            newRecord.onTable = true
        } else {
            newRecord.onTable = false
        }
        
        // Update the label of the filename in the ViewController
        labelFilename.text = "file: \(filename).caf"
        
        // Configure the new file for recording
//        fileUrl = getDirectory().appendingPathComponent("\(newRecord.filename).caf")
//        do {
//            try outputFile = AVAudioFile(forWriting: fileUrl, settings: audioEngine.inputNode.outputFormat(forBus: 0).settings)
//            print("Audio file succesfully created")
//
//        } catch {
//            print("Failed to create file for writing")
//        }

        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToQuestionnaire" {
            
            let destinationVC = segue.destination as! FileViewController
            destinationVC.delegate = self
            
            destinationVC.filename = ""
            destinationVC.distance = ""
            destinationVC.onTable =  ""
            
        } else if segue.identifier == "editMetadata" {
        
            let destinationVC = segue.destination as! FileViewController
            destinationVC.delegate = self
        
            destinationVC.filename = newRecord.filename
            destinationVC.distance = newRecord.distance
        
            if newRecord.onTable {
                destinationVC.onTable = "t"
            } else {
                destinationVC.onTable = "h"
            }
            
        }
    }
    
    
    
    //* MARK: Utility functions
    //------------------------------
    
    // Function that displays an alert if something goes wrong
    func displayAlert(title:String, message:String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction( title: "dismiss", style: .default, handler:nil))
        present(alert, animated:true, completion: nil)
    }
    

    // Get directory
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    
    // Delete a file from a directory
    func deleteFile(filename: String) {
        let fileUrlToDelete = getDirectory().appendingPathComponent(filename)
        do {
            try fileManager.removeItem(at: fileUrlToDelete)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
    }
    
    

    //* MARK: IBActions and IBOutlets
    //-------------------------------
    @IBAction func buttonSetupNewRec(_ sender: UIButton) {
        
        // Later, the properties inside the record need to be passed from the second ViewController.
        // Then used for initializing the session, etc etc.
        
        //newRecord = Recording()
        
        // Change the flag and enable the record button again
        flag_setupReady = true
        print("here")
        
        obuttonStartStop.isEnabled = true
        obuttonStartStop.isHighlighted = false
        
        //Actually, all the data should be filled in into this other screen
        performSegue(withIdentifier: "goToQuestionnaire", sender: self)

    }
    
 
    @IBAction func buttonStartStop(_ sender: UIButton) {
        
        if flag_isRecording == false {
            
            // Check if an audio player is playing and reset it if yes
            if audioPlayer != nil {
                if audioPlayer.isPlaying {
                    audioPlayer.stop()
                    audioPlayer = nil
                }
            }
            
 
            // Configure the new file for recording and delete if there is an existing one
            
            fileUrl = getDirectory().appendingPathComponent("\(newRecord.filename).caf")
            do {
                try outputFile = AVAudioFile(forWriting: fileUrl, settings: audioEngine.inputNode.outputFormat(forBus: 0).settings)
                print("Audio file succesfully created")
                
            } catch {
                print("Failed to create file for writing")
            }
                
            
            // Set the start timestamp
            newRecord.setTimestamp(forTimeAt: .start)
            
            // Start the recording
            newRecord.start(audioEngine: audioEngine, outputFile: outputFile)
            
            // Update flags and UI
            flag_isRecording = true
            obuttonStartStop.setTitleColor(UIColor.red, for: .normal)
            obuttonStartStop.setTitle("Stop", for: .normal)
            
            
            
        } else {
            
            // Set the end timestamp
            newRecord.setTimestamp(forTimeAt: .end)
            
            // Stop the recording
            newRecord.stop(audioEngine: audioEngine)
            
            
            // Update flags and UI
            flag_isRecording = false
            obuttonStartStop.setTitle("Record", for: .normal)
            obuttonStartStop.setTitleColor(UIColor.white, for: .normal)
            obuttonListen.isUserInteractionEnabled = true
            obuttonEdit.isUserInteractionEnabled = true
            obuttonUpload.isUserInteractionEnabled = true
            obuttonDelete.isUserInteractionEnabled = true
          
            
            print("\nRecording started at \(newRecord.startTimestamp)")
            print("Recording ended at \(newRecord.endTimestamp)")
            print("Microphone location: \(newRecord.microphoneLocation)")
            print("Microphone type: \(newRecord.microphoneType)")
            print("On table: \(newRecord.onTable)")
            print("Distance from TV: \(newRecord.distance)")
        }
    }
    
    
    
    @IBAction func buttonListen(_ sender: UIButton) {
        
        let fileUrlToPlay = getDirectory().appendingPathComponent("\(newRecord.filename).caf")
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: fileUrlToPlay)
            audioPlayer.prepareToPlay()
            audioPlayer.play()

        } catch {

            displayAlert(title: "Failed", message: "Audio can not be played.")

        }
    }
    
    
    
    @IBAction func buttonDelete(_ sender: UIButton) {
        
        deleteFile(filename: "\(newRecord.filename).caf")
        displayAlert(title: "File deleted", message: "\(newRecord.filename).caf has been removed")
        labelFilename.text = ""
        
//        let fileUrlToDelete = getDirectory().appendingPathComponent("\(newRecord.filename).caf")
//        do {
//            try fileManager.removeItem(at: fileUrlToDelete)
//            displayAlert(title: "File deleted", message: "\(newRecord.filename).caf has been removed")
//            labelFilename.text = ""
//        }
//        catch let error as NSError {
//            print("Ooops! Something went wrong: \(error)")
//        }
    }
    
    
    @IBAction func buttonMetadata(_ sender: UIButton) {
        
        print(newRecord.filename)
        performSegue(withIdentifier: "editMetadata", sender: self)
        
    }
    
    
    
    
    @IBAction func buttonBottom(_ sender: UIButton) {
        configAudioSessionMicrophoneSelection(preferredMic: AVAudioSessionOrientationBottom)
        selectedMicrophone = AVAudioSessionOrientationBottom
    }
    
    
    @IBAction func buttonBack(_ sender: UIButton) {
        configAudioSessionMicrophoneSelection(preferredMic: AVAudioSessionOrientationBack)
        selectedMicrophone = AVAudioSessionOrientationBack
    
    }
    
    @IBAction func buttonFront(_ sender: UIButton) {
        configAudioSessionMicrophoneSelection(preferredMic: AVAudioSessionOrientationFront)
        selectedMicrophone = AVAudioSessionOrientationFront
    }
    
    
    @IBAction func buttonOmni(_ sender: UIButton) {
        configAudioSessionMicrophonePolarPattern(preferredPolarPattern: AVAudioSessionPolarPatternOmnidirectional)
    }
    
    @IBAction func buttonCardioid(_ sender: UIButton) {
        configAudioSessionMicrophonePolarPattern(preferredPolarPattern: AVAudioSessionPolarPatternCardioid)
    }
    
    @IBAction func buttonSubcardioid(_ sender: UIButton) {
        configAudioSessionMicrophonePolarPattern(preferredPolarPattern: AVAudioSessionPolarPatternSubcardioid)
    }
    
    
    
    
    @IBOutlet weak var obuttonStartStop: UIButton!
    
    @IBOutlet weak var obuttonBottom: UIButton!
    @IBOutlet weak var obuttonBack: UIButton!
    @IBOutlet weak var obuttonFront: UIButton!
    @IBOutlet weak var obuttonOmni: UIButton!
    @IBOutlet weak var obuttonCardioid: UIButton!
    @IBOutlet weak var obuttonSubcardioid: UIButton!
    
    @IBOutlet weak var labelFilename: UILabel!
    
    
    @IBOutlet weak var obuttonListen: UIButton!
    @IBOutlet weak var obuttonEdit: UIButton!
    @IBOutlet weak var obuttonUpload: UIButton!
    @IBOutlet weak var obuttonDelete: UIButton!
    
}

