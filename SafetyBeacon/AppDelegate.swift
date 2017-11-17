//
//  AppDelegate.swift
//  SafetyTracker
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
//

import UIKit
import Parse
import UserNotifications
import NTComponents
import Fabric
import Crashlytics

var appController = NTDrawerController()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var updateTimer: Timer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Color.Default.setPrimary(to: .logoOffwhite)
        Color.Default.setSecondary(to: .logoBlue)
        Color.Default.setTertiary(to: .logoYellow)
        Color.Default.Tint.View = .logoGreen
        
        Font.Default.Title = Font.Roboto.Medium.withSize(15)
        Font.Default.Subtitle = Font.Roboto.Regular
        Font.Default.Body = Font.Roboto.Regular.withSize(13)
        Font.Default.Caption = Font.Roboto.Medium.withSize(12)
        Font.Default.Subhead = Font.Roboto.Regular.withSize(14)
        Font.Default.Headline = Font.Roboto.Medium.withSize(15)
        Font.Default.Callout = Font.Roboto.Regular.withSize(13)
        Font.Default.Footnote = Font.Roboto.Light.withSize(12)
        
        // Establish a connection to the backend
        let config = ParseClientConfiguration(block: { (mutableClientConfig) -> Void in
            mutableClientConfig.applicationId = self.XParseApplicationID
            mutableClientConfig.clientKey = self.XParseMasterKey
            mutableClientConfig.server = self.XParseServerURL
        })
        Parse.enableLocalDatastore()
        Parse.initialize(with: config)
        #if DEBUG
            Parse.setLogLevel(.debug)
            Log.setTraceLevel(to: .debug)
        #endif
        
        // Fabric Setup
        Fabric.with([Crashlytics.self, Answers.self])
        
        // Register for Push Notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, _) in
            Log.write(.status, "Push Notifications are " + (granted ? "granted" : "NOT granted"))
        }
        application.registerForRemoteNotifications()
        
        LocationManager.shared.beginTracking()
        window = UIWindow(frame: UIScreen.main.bounds)
        if User.current() != nil {
            LoginViewController.loginSuccessful()
        } else {
            appController.setViewController(LoginViewController(), forSide: .center)
        }
        window?.rootViewController = appController
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        updateTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(debugfunc), userInfo: nil, repeats: true)
        print ("App delegate didenterbackground")
        registerBackgroundTask()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //need to reset timer and end background process
        print ("didbecomeActive")
        updateTimer?.invalidate()
        updateTimer = nil
        // end background task
        if backgroundTask != UIBackgroundTaskInvalid {
            endBackgroundTask()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    
    @objc func debugfunc() {
        switch UIApplication.shared.applicationState {
        case .active:
            print ("debugfunc: Active")
        case .background:
            print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
        case .inactive:
            break
        }
    }
    
}
