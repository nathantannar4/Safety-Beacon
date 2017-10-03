//
//  AppDelegate.swift
//  SafetyTracker
//
//  Created by Nathan Tannar on 9/20/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import Parse
import UserNotifications
import NTComponents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let green = UIColor(r: 133, g: 204, b: 173)
        let yellow = UIColor(r: 253, g: 226, b: 128)
        let blue = UIColor(r: 130, g: 200, b: 235)
        let red = UIColor(r: 252, g: 18, b: 30)
        Color.Default.setPrimary(to: blue)
        Color.Default.setSecondary(to: .white)
        Color.Default.setTertiary(to: yellow)
        Color.Default.Tint.View = green
        Color.Default.Text.Title = .white
        
        Font.Default.Title = Font.Roboto.Medium.withSize(15)
        Font.Default.Subtitle = Font.Roboto.Regular
        Font.Default.Body = Font.Roboto.Regular.withSize(13)
        Font.Default.Caption = Font.Roboto.Medium.withSize(12)
        Font.Default.Subhead = Font.Roboto.Regular.withSize(14)
        Font.Default.Headline = Font.Roboto.Medium.withSize(15)
        Font.Default.Callout = Font.Roboto.Medium.withSize(15)
        Font.Default.Footnote = Font.Roboto.Regular.withSize(12)
        
        UIApplication.shared.statusBarStyle = .lightContent
        
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
        
        // Register for Push Notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, _) in
            Log.write(.status, "Push Notifications are " + (granted ? "granted" : "NOT granted"))
        }
        application.registerForRemoteNotifications()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        if User.current() == nil {
            window?.rootViewController = LoginViewController()
        } else {
            window?.rootViewController = NTDrawerController(centerViewController: NTNavigationController(rootViewController: MapViewController()))
        }
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
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
