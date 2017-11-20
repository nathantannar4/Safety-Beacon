//
//  CaretakerHistoryViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//          - ntannar@sfu.ca
//      Kim Youjung
//          - youjungk@sfu.ca
//

import UIKit
import Parse
import NTComponents
import Mapbox
import DateTimePicker

class CaretakerHistoryViewController: MapViewController {
    
    // MARK: - Properties
    
    // THESE ARE ALL VIEW INITIALIZATIONS, we do not use storyboards so this is how its done
    
    var filterView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.setDefaultShadow()
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        return view
    }()
    
    lazy var fromButton: NTButton = { [weak self] in
        let button = NTButton()
        button.ripplePercent = 1
        button.trackTouchLocation = false
        button.title = "From: " + Date().addMonth(-1).string(dateStyle: .short, timeStyle: .none)
        button.setDefaultShadow()
        button.layer.cornerRadius = 22
        button.tag = 0
        button.addTarget(self, action: #selector(editFilter), for: .touchUpInside)
        button.backgroundColor = .logoRed
        return button
    }()
    
    lazy var toButton: NTButton = { [weak self] in
        let button = NTButton()
        button.ripplePercent = 1
        button.trackTouchLocation = false
        button.title = "To: " + Date().string(dateStyle: .short, timeStyle: .none)
        button.setDefaultShadow()
        button.layer.cornerRadius = 22
        button.tag = 1
        button.addTarget(self, action: #selector(editFilter), for: .touchUpInside)
        button.backgroundColor = .logoYellow
        return button
    }()
    
    // END
    
    var lowerDate = Date().addMonth(-1) // lower date filter
    var upperDate = Date()              // upper date filter
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "History"
        setupFilterView()
        refreshLocations()
    }
    
    // Adds the filter view and sets up the auto layout constraints
    fileprivate func setupFilterView() {
        view.addSubview(filterView)
        filterView.addSubview(fromButton)
        filterView.addSubview(toButton)
        
        filterView.addConstraints(left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, heightConstant: 60)
        
        fromButton.addConstraints(filterView.topAnchor, left: filterView.leftAnchor, bottom: filterView.bottomAnchor, right: toButton.leftAnchor, topConstant: 8, leftConstant: 16, bottomConstant: 8, rightConstant: 16)
        
        toButton.addConstraints(filterView.topAnchor, left: fromButton.rightAnchor, bottom: filterView.bottomAnchor, right: filterView.rightAnchor, topConstant: 8, leftConstant: 16, bottomConstant: 8, rightConstant: 16)
        
        fromButton.anchorWidthToItem(toButton)
    }
    
    // Gets all the bookmarks for the patient and places a marker on the map for each one
    func refreshLocations() {
        
        guard let patient = User.current()?.patient else { return }
        
        let query = PFQuery(className: "History")
        query.whereKey("patient", equalTo: patient) // bookmarks for patient
        query.whereKey("createdAt", lessThan: upperDate) // filter
        query.whereKey("createdAt", greaterThan: lowerDate) // filter
        query.findObjectsInBackground(block: {(objects, error) in
            guard let objects = objects else {
                return
            }
            self.mapView.annotations?.forEach { self.mapView.removeAnnotation($0) }
            for location in objects {
                guard let long = location["long"] as? Double, let lat = location["lat"] as? Double, let createdAt = location.createdAt else {
                    Log.write(.warning, "Unable to retrieve the location information")
                    return
                }
                let annotation = MGLPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(lat, long)
                annotation.title = createdAt.string(dateStyle: .medium, timeStyle: .short)
                self.mapView.addAnnotation(annotation)
            }
        })
    }
    
    // MARK: - User Actions
    
    @objc
    func editFilter(_ sender: NTButton) {
        
        // Displays a date picker to adjust the lower or upper date filter
        let selected = sender.tag == 0 ? lowerDate : upperDate
        let picker = DateTimePicker.show(selected: selected)
        picker.selectedDate = selected
        picker.is12HourFormat = true
        picker.includeMonth = true
        picker.highlightColor = sender.tag == 0 ? .logoRed : .logoYellow
        picker.completionHandler = { newDate in
            if sender.tag == 0 {
                self.lowerDate = newDate
                self.fromButton.title = "From: " + newDate.string(dateStyle: .short, timeStyle: .none)
            } else {
                self.upperDate = newDate
                self.toButton.title = "To: " + newDate.string(dateStyle: .short, timeStyle: .none)
            }
            self.refreshLocations()
        }
    }
}
