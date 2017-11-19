//
//  PatientMapViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
//      Philip Leblanc
//          - paleblan@sfu.ca
//

import Parse
import UIKit
import NTComponents
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

class PatientMapViewController: MapViewController {
    
    // MARK: - Properties
    lazy var takeMeHomeButton: NTButton = { [weak self] in
        let button = NTButton()
        button.backgroundColor = .logoBlue
        button.titleColor = .white
        button.trackTouchLocation = false
        button.ripplePercent = 1
        button.setTitleColor(UIColor.white.withAlpha(0.3), for: .highlighted)
        button.setTitle("Home", for: .normal)
        button.titleFont = Font.Default.Title.withSize(22)
        button.addTarget(self, action: #selector(presentNavigation), for: .touchUpInside)
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.cgColor
        button.setDefaultShadow()
        return button
    }()
    
    var directionsRoute: Route?
    var bookmarks = [PFObject]()
    
    // Get bookmarks from database
    @objc
    func getHomeBookmark() {
        // Check that Caretaker is accessing this menu, not Patient
        guard let currentUser = User.current(), currentUser.isPatient else { return }
        
        let query = PFQuery(className: "Bookmarks")
        query.whereKey("patient", equalTo: currentUser.object)
        query.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.bookmarks = objects
            
            // TODO: Search for bookmark "Home"
            let home = self.bookmarks[0]["address"] as? String
            self.calculateRouteHome(Home: home!)
        }
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        self.getHomeBookmark()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let location = LocationManager.shared.currentLocation else { return }
        mapView.setCenter(location, zoomLevel: 13, animated: true)
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        view.addSubview(takeMeHomeButton)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        takeMeHomeButton.addConstraints(nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 32, rightConstant: 32, widthConstant: 80, heightConstant: 80)
    }
    
    // MARK: - User Actions
    @objc
    func calculateRouteHome(Home: String) {
        
        self.getCoordinates(address: Home, completion: { (coordinate) in
            guard let coordinate = coordinate else {
                NTPing(type: .isDanger, title: "Invalid Address").show(duration: 5)
                return
            }
            //use mapbox to trace the path to home from current location
            guard let currentLocation = LocationManager.shared.currentLocation else { return }
            let origin = Waypoint(coordinate: currentLocation, name: "Current Location")
            let destination = Waypoint(coordinate: coordinate, name: "Home")
            
            let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .walking)
            
            let annotation = MGLPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Home"
            if let currentLocation = LocationManager.shared.currentLocation {
                // Return distance in Km
                annotation.subtitle = "\(String(format: "%.02f", Double(currentLocation.distance(to: coordinate)/1000))) Km Away"
            }
            self.mapView.addAnnotation(annotation)

            _ = Directions.shared.calculate(options) { (waypoints, routes, error) in
                guard let route = routes?.first else { return }
                self.directionsRoute = route
                self.drawRoute(route: self.directionsRoute!)
            }
        })
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
    
    // Present the navigation view controller
    @objc
    func presentNavigation() {
        let viewController = NavigationViewController(for: directionsRoute!)
        self.present(viewController, animated: true, completion: nil)
    }
    
    // Get coordinates from address
    func getCoordinates(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        CLGeocoder().geocodeAddressString(address, completionHandler: { (placemarks, error) in
            if error != nil {
                Log.write(.error, error.debugDescription)
                return
            }
            if placemarks?.count != nil {
                let placemark = placemarks?[0]
                let location = placemark?.location
                let coordinate = location?.coordinate
                completion(coordinate)
            } else {
                completion(nil)
            }
        })
    }
}
