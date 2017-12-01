//
//  LocationManager.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
//      Youjung Kim
//          - youjungk@sfu.ca
//      Jason Tsang
//          - jrtsang@sfu.ca
//

import CoreLocation
import Parse
import NTComponents

class LocationManager: NSObject, CLLocationManagerDelegate, UIApplicationDelegate {
    
    static var shared = LocationManager()

    fileprivate var counter = 0
    
    // MARK: - Properties
    
    var currentLocation: CLLocationCoordinate2D? {
        guard let location = coreLocationManager.location else {
            Log.write(.warning, "Failed to get the users current location. Was auth given?")
            return nil
        }
        return CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
    }
    
    // MARK: - Private Properties
    
    private lazy var coreLocationManager: CLLocationManager = { [weak self] in
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest // Highest accuracy
        manager.distanceFilter = 10 // Minimum distance device moves in meters to generate an update
        manager.pausesLocationUpdatesAutomatically = true // Automatically pause to save power
        return manager
    }()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupBatteryMonitor()
        setupSafeZones()
    }
    
    /// Adds observers to monitor the devices battery level
    private func setupBatteryMonitor() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: .UIDeviceBatteryLevelDidChange, object: nil)
    }
    
    // MARK: - Functions
    
    /// Sends notifications to the caretaker under during critical battery levels
    @objc
    func batteryLevelDidChange() {
        let currentLevel = UIDevice.current.batteryLevel // 1.0 = 100%, 0.2 = 20%
        if currentLevel == 0.2 {
            // Send notification to caretaker
            guard let caretakerID = User.current()?.caretaker?.objectId else { return }
            PushNotication.sendPushNotificationMessage(caretakerID, text: "Battery level at \(currentLevel*100)%")
        } else if currentLevel <= 0.1 {
            // Send notification to caretaker and update location
            guard let caretakerID = User.current()?.caretaker?.objectId else { return }
            PushNotication.sendPushNotificationMessage(caretakerID, text: "Battery level at \(currentLevel*100)%")
            saveCurrentLocation()
        }
    }
    
    /// Promts the user for location accesss authorization
    func requestAlwaysAuthorization() {
        coreLocationManager.requestAlwaysAuthorization()
    }
    
    /// Saves the current users location to the server for processing
    ///
    /// - Returns: If the push was successful
    @objc func saveCurrentLocation() {
        
        guard let user = User.current(), user.isPatient, let location = currentLocation else { return }
        let location_history = PFObject(className: "History")
        location_history["long"] = location.longitude
        location_history["lat"] = location.latitude
        location_history["patient"] = user.object
        location_history.saveInBackground(block: {(success, error) in
            guard success else {
                NTPing(type: .isSuccess, title: "Unable to save location to the database").show(duration: 5)
                Log.write(.error, error.debugDescription)
                return
            }
        })
    }
    
    // MARK: - Private Functions
    
    /// Begins updating the users location in the background async
    func beginTracking() {
        DispatchQueue.main.async {
            self.coreLocationManager.startUpdatingLocation()
            self.coreLocationManager.startMonitoringVisits()
        }
    }
    
    /// Ends updating the users location in the background async
    func endTracking() {
        DispatchQueue.main.async {
            self.coreLocationManager.stopUpdatingLocation()
            self.coreLocationManager.stopMonitoringVisits()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        Log.write(.status, "locationManagerDidResumeLocationUpdates")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        Log.write(.status, "locationManagerDidPauseLocationUpdates")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.write(.error, "locationManagerDidFailWithError: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        // DEBUG - Lists all the monitored regions to console
        print("The monitored regions are: \(manager.monitoredRegions)")
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        Log.write(.status, "locationManagerDidVisit: \(visit)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Log.write(.status, "locationManagerDidEnterRegion: \(region)")
        // Send push notification if patient enters monitored region
        // Push notifications only accessible to paid developer membership (push notification certificate for App ID)
        // Checked validaility by writing message to console running SafetyZonesTests
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Log.write(.status, "locationManagerDidExitRegion: \(region)")
        // Send push notification if patient exits monitored region
        // Push notifications only accessible to paid developer membership (push notification certificate for App ID)
        // Checked validaility by writing message to console running SafetyZonesTests
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Log.write(.status, "\(counter)locationManagerDidUpdateLocations: \(locations)")
        // Every 5 minutes (300 seconds) sync the users location
        if UIApplication.shared.applicationState == .active {
            if counter % 300 == 0 {
                saveCurrentLocation()
                counter = 1
            }
            
        }
        // if the application is .inactive or .background
        else {
            if (counter % 300 == 0){
                saveCurrentLocation()
                counter = 1
            }
        }
        counter += 1
        
		//For testing purposes
        switch UIApplication.shared.applicationState {
        case .active:
            print ("active")
        case .background:
            print("App is backgrounded.")
            print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
        case .inactive:
            break
        }
        
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Log.write(.status, "locationManagerDidChangeAuthorizationStatus: \(status)")
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            // Location services are authorised, track the user.
            beginTracking()
        case .denied, .restricted:
            // Location services not authorised, stop tracking the user.
            endTracking()
        default:
            // Location services pending authorisation.
            // Alert requesting access is visible at this point.
            break
        }
    }
    
    // MARK: - Patient Safe Zones Processing Functions
    
    // Setup Safe Zones from database
    @objc
    func setupSafeZones() {
        // Check that Patient is accessing this menu, not Caretaker
        guard let currentUser = User.current(), currentUser.isPatient else { return }
        
        // Remove all previously cached Safe Zones regions to monitor
        for object in coreLocationManager.monitoredRegions {
            coreLocationManager.stopMonitoring(for: object)
        }
        
        let query = PFQuery(className: "SafeZones")
        query.whereKey("patient", equalTo: currentUser.object)
        query.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            // Iterate through all the Safe Zones
            for zone in objects {
                let address = zone["address"] as! String
                let radius = zone["radius"] as! Double
                let identifier = zone["name"] as! String
                self.getCoordinates(address: address, completion: { (coordinate) in
                    guard let coordinate = coordinate else {
                        NTPing(type: .isDanger, title: "Invalid Address").show(duration: 5)
                        return
                    }
                    // Add to monitored regions
                    self.addMonitoring(coordinate: coordinate, radius: radius, identifier: identifier)
                })
            }
        }
    }
    
    // Add Safe Zones to monitored regions automatically managed by iOS
    func addMonitoring(coordinate: CLLocationCoordinate2D, radius: Double, identifier: String) {
        // Set parameters
        let radius: CLLocationDistance = CLLocationDistance(radius)
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier)
        // Notify on both exit and enter
        region.notifyOnEntry = true
        region.notifyOnExit = true
        // Add and refresh list
        coreLocationManager.startMonitoring(for: region)
        coreLocationManager.startUpdatingLocation()
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

