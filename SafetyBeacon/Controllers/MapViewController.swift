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
        
        title = "Map"
        view.backgroundColor = .white
        setupSubviews()
        setupConstraints()
        
        // Declare the marker `hello` and set its coordinates, title, and subtitle.
//        let hello = MGLPointAnnotation()
//        hello.coordinate = CLLocationCoordinate2D(latitude: 40.7326808, longitude: -73.9843407)
//        hello.title = "Hello world!"
//        hello.subtitle = "Welcome to my marker"
//
//        // Add marker `hello` to the map.
//        mapView.addAnnotation(hello)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let location = LocationManager.shared.currentLocation else { return }
        mapView.setCenter(location, zoomLevel: 12, animated: true)
    }
    
    open func setupSubviews() {
        
        view.addSubview(mapView)
    }
    
    open func setupConstraints() {
        
        mapView.constrainToSuperview()
    }
    
    // MARK: - User Actions
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
