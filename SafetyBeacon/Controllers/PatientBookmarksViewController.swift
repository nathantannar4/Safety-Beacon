//
//  PatientBookmarksViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Jason Tsang
//          - jrtsang@sfu.ca
//

import AddressBookUI
import CoreLocation
import NTComponents
import Parse
import UIKit
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

class PatientBookmarksViewController: UITableViewController {
    
    // MARK: - Properties
    var bookmarks = [PFObject]()
    var directionsRoute: Route?
    
    // MARK: - View Life Cycle
    
    // Initial load confirmation
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        view.backgroundColor = Color.Default.Background.ViewController
        tableView.tableFooterView = UIView()
        refreshBookmarks()
    }
    
    // Updating bookmarks from database
    @objc
    func refreshBookmarks() {
        // Check that Caretaker is accessing this menu, not Patient
        guard let currentUser = User.current(), currentUser.isPatient else { return }
        
        let query = PFQuery(className: "Bookmarks")
        query.whereKey("patient", equalTo: currentUser.object)
        query.findObjectsInBackground { (objects, error) in
            self.tableView.refreshControl?.endRefreshing()
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.bookmarks = objects
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    // Sections within Bookmarks View
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Only one section
        return 1
    }
    
    // Section titles
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = NTTableViewHeaderFooterView()
        if section == 0 {
            header.textLabel.text = "Select Destination:"
        }
        return header
    }
    
    // Section rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks.count
    }
    
    // Table styling
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section <= 1 ? 44 : UITableViewAutomaticDimension
    }
    
    // Populating row content
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        // List existing bookmarks
        cell.textLabel?.text = bookmarks[indexPath.row]["name"] as? String
        cell.detailTextLabel?.text = bookmarks[indexPath.row]["address"] as? String
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    // Row selectable actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = PatientLocationViewController()
        location.title = bookmarks[indexPath.row]["name"] as? String
        let address = bookmarks[indexPath.row]["address"] as? String
        var concatenatedAddressArr = address?.components(separatedBy: ", ")
        let originalStreet = concatenatedAddressArr![0] as String
        
        self.getCoordinates(address: address!, completion: { (coordinate) in
            guard let coordinate = coordinate else {
                NTPing(type: .isDanger, title: "Invalid Address").show(duration: 5)
                return
            }
            let navigation = NTNavigationController(rootViewController: location)
            
            self.present(navigation, animated: true, completion: {
                let locationMarker = MGLPointAnnotation()
                locationMarker.coordinate = coordinate
                locationMarker.title = originalStreet
                if let currentLocation = LocationManager.shared.currentLocation {
                    // Return distance in Km
                    locationMarker.subtitle = "\(String(format: "%.02f", Double(currentLocation.distance(to: coordinate)/1000))) Km Away"
                }
                location.mapView.addAnnotation(locationMarker)
                location.mapView.setCenter(coordinate, zoomLevel: 13, animated: true)
                
                // Use mapbox to trace the path to home from current location
                guard let currentLocation = LocationManager.shared.currentLocation else { return }
                let origin = Waypoint(coordinate: currentLocation, name: "Current Location")
                let destination = Waypoint(coordinate: coordinate, name: location.title)

                let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .walking)

                _ = Directions.shared.calculate(options) { (waypoints, routes, error) in
                    guard let route = routes?.first else { return }
                    self.directionsRoute = route

                    guard route.coordinateCount > 0 else { return }
                    // Convert the route’s coordinates into a polyline.
                    var routeCoordinates = route.coordinates!
                    let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)

                    // If there's already a route line on the map, reset its shape to the new route
                    if let source = location.mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
                        source.shape = polyline
                    } else {
                        let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
                        let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)

                        location.mapView.style?.addSource(source)
                        location.mapView.style?.addLayer(lineStyle)
                    }
                    // Connect start button to action
                    location.startButton.addTarget(self, action: #selector(self.presentNavigation), for: .touchUpInside)
                }
            })
        })
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Processing Functions
    
    // Get the view controller currently displayed
    func topMostController() -> UIViewController {
        var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    // Present the navigation view controller
    @objc
    func presentNavigation() {
        let viewController = NavigationViewController(for: self.directionsRoute!)
        topMostController().present(viewController, animated: true, completion: nil)
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
