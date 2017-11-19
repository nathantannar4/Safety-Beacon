//
//  LocationViewController.swift
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

class LocationViewController: MapViewController {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Delete?.scale(to: 30), style: .plain, target: self, action: #selector(closeView))
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        view.addSubview(startButton)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        startButton.addConstraints(nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 32, rightConstant: 32, widthConstant: 80, heightConstant: 80)
    }

    @objc
    func closeView() {
        dismiss(animated: true, completion: nil)
    }
}
