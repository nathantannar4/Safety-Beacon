//
//  MapViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents
import Mapbox
import MapboxDirections
import MapboxCoreNavigation

class MapViewController: UIViewController {
    
    // MARK: - Properties
    
    lazy var mapView: MGLMapView = { [weak self] in
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        let mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView.delegate = self
        mapView.showsUserLocation = true
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
    
    open func setupSubviews() {
        view.addSubview(mapView)
    }
    
    open func setupConstraints() {
        mapView.constrainToSuperview()
    }
    
}

extension MapViewController: MGLMapViewDelegate {
    
    // Use the default marker. See also: our view annotation or custom marker examples.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
}
