//
//  PatientLocationViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Jason Tsang
//          - jrtsang@sfu.ca
//

import UIKit
import NTComponents
import Mapbox

class PatientLocationViewController: MapViewController {
    
    // Start navigation button
    lazy var startButton: NTButton = { [weak self] in
        let button = NTButton()
        button.backgroundColor = .logoGreen
        button.titleColor = .white
        button.trackTouchLocation = false
        button.ripplePercent = 1
        button.setTitleColor(UIColor.white.withAlpha(0.3), for: .highlighted)
        button.setTitle("Start", for: .normal)
        button.titleFont = Font.Default.Title.withSize(22)
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.cgColor
        button.setDefaultShadow()
        return button
        }()
    
    // AR Mode button that switches to Augmented Reality Mode
    lazy var arModeButton: NTButton = { [weak self] in
        let button = NTButton()
        button.backgroundColor = .logoRed
        button.titleColor = .white
        button.trackTouchLocation = false
        button.ripplePercent = 1
        button.setTitleColor(UIColor.white.withAlpha(0.3), for: .highlighted)
        button.setTitle("AR Mode", for: .normal)
        button.titleFont = Font.Default.Title.withSize(16)
        button.addTarget(self, action: #selector(presentARNavigation), for: .touchUpInside)
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.logoRed.darker(by: 10).cgColor
        button.setDefaultShadow()
        return button
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Delete?.scale(to: 30), style: .plain, target: self, action: #selector(closeView))
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        view.addSubview(startButton)
        view.addSubview(arModeButton)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        // Location of start button on screen
        startButton.addConstraints(nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 32, rightConstant: 32, widthConstant: 80, heightConstant: 80)
        // Location of AR button on screen
        arModeButton.addConstraints(nil, left: nil, bottom: startButton.topAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 16, rightConstant: 32, widthConstant: 80, heightConstant: 80)
    }
    
    // Present the augmented reality view controller
    @objc
    func presentARNavigation() {
        
        // THere should only be one coordinate, the bookmark
        guard let coordinate = mapView.annotations?.first?.coordinate else {
            return
        }
        
        let arController = ARViewController().addDismissalBarButtonItem()
        let viewController = UINavigationController(rootViewController: arController)
        viewController.navigationBar.isTranslucent = false
        present(viewController, animated: true, completion: {
            // Start directions to the bookmark
            arController.guide(to: coordinate)
        })
    }

    @objc
    func closeView() {
        dismiss(animated: true, completion: nil)
    }
    
}
