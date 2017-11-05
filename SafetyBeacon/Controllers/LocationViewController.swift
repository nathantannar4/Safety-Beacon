//
//  LocationViewController.swift
//  SafetyBeacon
//
//  Created by Jason Tsang on 2017-11-04.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents

class LocationViewController: MapViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Delete?.scale(to: 30), style: .plain, target: self, action: #selector(closeView))
    }
    
    @objc
    func closeView() {
        dismiss(animated: true, completion: nil)
    }
}
