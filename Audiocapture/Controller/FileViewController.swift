//
//  FileViewController.swift
//  Audiocapture
//
//  Created by Maja Taseska on 13/08/2018.
//  Copyright © 2018 Maja Taseska. All rights reserved.
//

import UIKit

protocol SetProperties {
    func userChangedProperties (filename: String, distance: String)
}

class FileViewController: UIViewController {
    
    // Declare the delegate variable here
    var delegate: SetProperties?
    
    // Required to be able to edit the properties from main View
    var filename: String?
    var distance: String?
    var onTable: String?
    
    var labMicloc: String?
    var labPolpat: String?
    var labStart: String?
    var labEnd: String?
    var labOntable: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        textFilename.text = filename
        textDistance.text = distance
        labelMicloc.text = labMicloc
        labelEndtime.text = labEnd
        labelStarttime.text = labStart
        labelPolarpattern.text = labPolpat
        labelOntable.text = labOntable
        
        if labelStarttime.text != "" {

            let mytime = labelStarttime.text as! String
            let mytimeend = labelEndtime.text as! String
            
            // date
            var startid = mytime.index((mytime.startIndex), offsetBy:2)
            var endid = mytime.index((mytime.startIndex), offsetBy:10)
            var substring1 = mytime[startid..<endid]
            let date = String(substring1)
            
            // time start
            startid = mytime.index((mytime.startIndex), offsetBy:11)
            endid = mytime.index((mytime.startIndex), offsetBy:19)
            substring1 = mytime[startid..<endid]
            let time = String(substring1)
            
            // time end
            startid = mytimeend.index((mytime.startIndex), offsetBy:11)
            endid = mytime.index((mytime.startIndex), offsetBy:19)
            substring1 = mytime[startid..<endid]
            let timeend = String(substring1)
        
            
            labelStarttime.text = time + " " + date
            labelEndtime.text = timeend + " " + date
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonSave(_ sender: UIButton) {
        
        let filename = textFilename.text!
        let distance = textDistance.text!
        
        
        // If the delegate is set, call the methods that will set the variables in the main ViewController
        delegate?.userChangedProperties(filename: filename, distance: distance)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    @IBOutlet weak var textFilename: UITextField!
    @IBOutlet weak var textDistance: UITextField!
    
    
    @IBOutlet weak var labelMicloc: UILabel!
    @IBOutlet weak var labelPolarpattern: UILabel!
    @IBOutlet weak var labelOntable: UILabel!
    @IBOutlet weak var labelStarttime: UILabel!
    @IBOutlet weak var labelEndtime: UILabel!
    //@IBOutlet weak var labelMicloc: UILabel!
    //@IBOutlet weak var labelPolarpattern: UILabel!
    //@IBOutlet weak var labelStarttime: UILabel!
    //@IBOutlet weak var labelOntable: UILabel!
    //@IBOutlet weak var labelEndtime: UILabel!
    
}
