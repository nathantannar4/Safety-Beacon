//
//  SafeZonesViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 10/2/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse

class SafeZonesViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(frame: CGRect(x: 16, y: 200, width: 100, height: 100))
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(saveSafeZone), for: .touchUpInside)
        view.addSubview(button)
    }
    
    
    // MARK: - User Actions
    
    @objc
    func saveSafeZone() {
        
        guard let currentUser = User.current(), currentUser.isCaretaker, let patient = currentUser.patient else { return }
        
        let zone = PFObject(className: "SafeZones")
        zone["long"] = LocationManager.shared.currentLocation?.longitude
        zone["lat"] = LocationManager.shared.currentLocation?.latitude
        zone["name"] = "SafeZoneForTesting"
        zone["patient"] = patient
        zone["radius"] = 50.555
        zone.saveInBackground { (success, error) in
            guard success else {
                // handle error
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                return
            }
            NTPing(type: .isSuccess, title: "Saved Safe Zone").show(duration: 3)
        }
    }
}


