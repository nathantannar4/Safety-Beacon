//
//  AccountSetupViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
//

import UIKit
import Parse
import NTComponents
import Mapbox

class AccountSetupViewController: UIViewController {
    
    // MARK: - Properties
    
    lazy var mapView: MGLMapView = { [weak self] in
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        let mapView = MGLMapView(frame: .zero, styleURL: url)
        mapView.showsUserLocation = true
        mapView.isUserInteractionEnabled = false
        return mapView
    }()
    
    var headerLabel: NTLabel = {
        let label = NTLabel()
        label.textAlignment = .center
        label.text = "Let's Get Started!"
        label.font = Font.Default.Title.withSize(26)
        label.backgroundColor = .white
        label.setDefaultShadow()
        return label
    }()
    
    lazy var caretakerButton: NTButton = { [weak self] in
        let button = NTButton()
        button.backgroundColor = .logoRed
        button.title = "I am a Caretaker"
        button.titleFont = Font.Default.Headline
        button.layer.cornerRadius = 30
        button.setDefaultShadow()
        button.addTarget(self, action: #selector(caretakerSelected), for: .touchUpInside)
        return button
    }()
    
    lazy var patientButton: NTButton = { [weak self] in
        let button = NTButton()
        button.backgroundColor = .logoBlue
        button.titleColor = .white
        button.title = "I am a Patient"
        button.titleFont = Font.Default.Headline
        button.layer.cornerRadius = 30
        button.setDefaultShadow()
        button.addTarget(self, action: #selector(patientSelected), for: .touchUpInside)
        return button
        }()
    
    lazy var helpButton: UIButton = { [weak self] in
        let button = UIButton()
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.tintColor = .white
        button.backgroundColor = .logoYellow
        button.layer.cornerRadius = 25
        button.setDefaultShadow()
        button.setImage(UIImage(named: "ic_question_mark")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(helpSelected), for: .touchUpInside)
        return button
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupSubviews()
        setupConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let location = LocationManager.shared.currentLocation else { return }
        mapView.setCenter(location, zoomLevel: 12, animated: true)
    }
    
    open func setupSubviews() {
        view.addSubview(mapView)
        view.addSubview(headerLabel)
        view.addSubview(caretakerButton)
        view.addSubview(patientButton)
        view.addSubview(helpButton)
    }
    
    open func setupConstraints() {
        mapView.addConstraints(view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, topConstant: 0, heightConstant: 225)
        headerLabel.addConstraints(mapView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, topConstant: -36, heightConstant: 44)
        caretakerButton.addConstraints(headerLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, topConstant: 80, leftConstant: 32, rightConstant: 32, heightConstant: 60)
        patientButton.addConstraints(caretakerButton.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, topConstant: 20, leftConstant: 32, rightConstant: 32, heightConstant: 60)
        helpButton.addConstraints(bottom: view.bottomAnchor, right: view.rightAnchor, bottomConstant: 32, rightConstant: 32, widthConstant: 50, heightConstant: 50)
    }
    
    // MARK: - User Actions
    
    @objc
    func caretakerSelected() {
        
        let alert = UIAlertController(title: "Link to Patient", message: "Please enter your patients unique ID  ", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            
            guard let id = alert.textFields?.first?.text else { return }
            let progressHUD = ProgressHUD()
            progressHUD.show(on: self, withTitle: "Working...", duration: nil)
            let query = PFUser.query()
            query?.whereKey(PF_USER_OBJECTID, equalTo: id)
            query?.getFirstObjectInBackground(block: { (object, error) in
                progressHUD.dismiss()
                guard let patient = object as? PFUser else {
                    NTPing(type: .isDanger, title: "Invalid ID, that user does not exist").show(duration: 3)
                    Log.write(.warning, error.debugDescription)
                    return
                }
                progressHUD.titleLabel.text = "Getting User Data"
                User.current()?.object[PF_USER_PATIENT] = patient
                User.current()?.object.saveInBackground(block: { (success, error) in
                    guard success else {
                        NTPing(type: .isDanger, title: "Sorry, an error occurred").show(duration: 3)
                        Log.write(.error, error.debugDescription)
                        return
                    }
                    progressHUD.dismiss()
                    NTPing(type: .isSuccess, title: "Successful Link").show(duration: 3)
                    LoginViewController.loginSuccessful()
                })
            })
            
        }))
        alert.addTextField {
            $0.placeholder = "Unique ID"
            $0.tintColor = .logoBlue
        }
        alert.view.tintColor = .logoBlue
        present(alert, animated: true, completion: nil)
    }
    
    @objc
    func patientSelected() {
        
        guard let user = User.current(), let id = user.id else { return }
        let progressHUD = ProgressHUD()
        progressHUD.show(on: self, withTitle: "Your unique ID is \(id)", duration: 10)
        let query = PFUser.query()
        query?.whereKey(PF_USER_PATIENT, equalTo: user.object)
        query?.getFirstObjectInBackground(block: { (object, error) in
            guard let caretaker = object as? PFUser else {
                Log.write(.warning, error.debugDescription)
                return
            }
            progressHUD.titleLabel.text = "Getting User Data"
            User.current()?.object[PF_USER_CARETAKER] = caretaker
            User.current()?.object.saveInBackground(block: { (success, error) in
                guard success else {
                    NTPing(type: .isDanger, title: "Sorry, an error occurred").show(duration: 5)
                    Log.write(.error, error.debugDescription)
                    return
                }
                progressHUD.dismiss()
                NTPing(type: .isSuccess, title: "Successful Link").show(duration: 3)
                LoginViewController.loginSuccessful()
            })
        })
    }
    
    @objc
    func helpSelected() {
        
        let alert = UIAlertController(title: "Help", message: "The caretaker is the user that manages a patient. They define the patients bookmarked locations and have access to their location history. In addition the caretaker can define areas as “Safe Zones” which when the patient exits the caretaker will recieve an alert.\n\nThe patient has an easy to use navigation interface that can guide them to their destination using augmented reality.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.view.tintColor = .logoBlue
        present(alert, animated: true, completion: nil)
    }
}
