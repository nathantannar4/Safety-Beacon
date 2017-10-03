//
//  MapViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    // MARK: - Properties
    
    lazy var mapView: MKMapView = { [weak self] in
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.showsUserLocation = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = true
        return mapView
    }()
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocationManager.shared.beginTracking()
        
        view.backgroundColor = .white
        setupSubviews()
        setupConstraints()
    }
    
    private func setupSubviews() {
        
        view.addSubview(mapView)
    }
    
    private func setupConstraints() {
        
        mapView.constrainToSuperview()
    }
    
    // MARK: - User Actions
}

extension MapViewController: MKMapViewDelegate {
    
    
}
