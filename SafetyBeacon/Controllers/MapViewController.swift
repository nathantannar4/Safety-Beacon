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
//import MapboxNavigation

class MapViewController: UIViewController {
    
    // MARK: - Properties
    
    lazy var mapView: MGLMapView = { [weak self] in
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        let mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView.delegate = self
        mapView.showsUserLocation = true
        return mapView
    }()
    
    var directionsRoute: Route?
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        LocationManager.shared.beginTracking()
        
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
        
        let button = UIButton()
        view.addSubview(button)
        button.backgroundColor = .logoYellow
        button.setTitle("Go Home", for: .normal)
        button.addTarget(self, action: #selector(calculateRouteHome), for: .touchUpInside)
        button.layer.cornerRadius = 30
        button.addConstraints(nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 32, rightConstant: 32, widthConstant: 100, heightConstant: 60)
    }
    
    // MARK: - User Actions
    @objc
    func calculateRouteHome(sender: UIButton!) {
        let home = CLLocationCoordinate2D(latitude: 37.77, longitude: -122.43) // TODO: - use actual home address
        //use mapbox to trace the path to home from current location
        let origin = Waypoint(coordinate: (mapView.userLocation!.coordinate), name: "Current Location")
        let destination = Waypoint(coordinate: home, name: "Home")
        
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .walking)
        
        let annotation = MGLPointAnnotation()
        annotation.coordinate = home
        annotation.title = "Start navigation"
        mapView.addAnnotation(annotation)
        
        _ = Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first else { return }
            self.directionsRoute = route
            self.drawRoute(route: self.directionsRoute!)
        }
    }
    
    func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else { return }
        // Convert the route’s coordinates into a polyline.
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        // If there's already a route line on the map, reset its shape to the new route
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
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
