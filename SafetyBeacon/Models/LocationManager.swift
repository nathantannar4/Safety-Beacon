//
//  LocationManager.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
//      Kim Youjung
//          - youjungk@sfu.ca
//

import CoreLocation
import Parse
import NTComponents

class LocationManager: NSObject, CLLocationManagerDelegate, UIApplicationDelegate {
    
    static var shared = LocationManager()
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var updateTimer: Timer?

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
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Functions
    
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
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        Log.write(.status, "locationManagerDidVisit: \(visit)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Log.write(.status, "locationManagerDidEnterRegion: \(region)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Log.write(.status, "locationManagerDidExitRegion: \(region)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Log.write(.status, "\(counter)locationManagerDidUpdateLocations: \(locations)")
        
        // Every 5 minutes (300 seconds) sync the users location
        if UIApplication.shared.applicationState == .active {
//            if backgroundTask != UIBackgroundTaskInvalid {
//                //endBackgroundTask()
//            }
            if counter % 300 == 0 {
                saveCurrentLocation()
                counter = 1
            }
            
        } else {
            //registerBackgroundTask()
            print ("application is backgrounded, most recent location: , \(locations)")
            if (counter % 300 == 0){
                saveCurrentLocation()
                counter = 1
            }
        }
        counter += 1
        
//        switch UIApplication.shared.applicationState {
//        case .active:
//            print ("active")
//        case .background:
//            print("App is backgrounded.")
//            print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
//        case .inactive:
//            break
//        }
        
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("GETS HERE1")
        updateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(saveCurrentLocation), userInfo: nil, repeats: true)
        registerBackgroundTask()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        updateTimer?.invalidate()
        updateTimer = nil
        // end background task
        if backgroundTask != UIBackgroundTaskInvalid {
            endBackgroundTask()
        }
    }
    //    func locationManagerInitialize(_application: UIApplication){//, didChangeState state: UIApplicationState){
//        switch UIApplication.shared.applicationState {
//        case .active:
//            print("GETS HERE1")
//            updateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(saveCurrentLocation), userInfo: nil, repeats: true)
//            registerBackgroundTask()
//        case .background:
//            print("GETS HERE2")
//            updateTimer?.invalidate()
//            updateTimer = nil
//            // end background task
//            if backgroundTask != UIBackgroundTaskInvalid {
//            endBackgroundTask()
//            }
//        case .inactive:
//            print("inactive")
//        }
//    }

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
    
    func registerBackgroundTask() {
        print ("background task registered..............")
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }

    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }

}


