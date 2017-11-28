//
//  MapViewController.swift
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

import UIKit
import NTComponents
import Mapbox

class MapViewController: UIViewController {
    
    // MARK: - Properties
    
    lazy var mapView: MGLMapView = { [weak self] in
        let mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.streetsStyleURL())
        mapView.delegate = self
        mapView.showsUserLocation = true
        return mapView
    }()
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Start tracking the user
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

// Places markers on the map for each location
extension MapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        guard annotation is MGLPointAnnotation else { return nil }
        
        // Use the point annotation’s longitude value (as a string) as the reuse identifier for its view.
        let reuseIdentifier = "\(annotation.coordinate.longitude)"
        
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = MGLAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            annotationView!.layer.cornerRadius = 12
            annotationView!.layer.borderColor = UIColor.white.cgColor
            annotationView!.layer.borderWidth = 2
            annotationView?.setDefaultShadow()
            annotationView!.backgroundColor = .logoRed
        }
        
        return annotationView
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // Color and opacity of Safe Zone radius
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 0.5
    }
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return .white
    }
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return UIColor(red: 59/255, green: 178/255, blue: 208/255, alpha: 1)
    }
}
