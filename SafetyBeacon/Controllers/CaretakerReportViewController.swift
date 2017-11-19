//
//  CaretakerReportViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents

class CaretakerReportViewController: NTTableViewController {
    
    // MARK: - Properties
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Report"
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  NTTimelineTableViewCell(style: .detailed)
        cell.isInitial = indexPath.row == 0
        cell.isFinal = indexPath.row + 1 == self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        
        cell.timeLabel.text = "\(indexPath.row + 8):30"
        cell.titleLabel.text = Lorem.words(nbWords: 3).capitalized
        cell.descriptionTextView.text = Lorem.paragraph()
//        cell.thumbnailImageView.image = #imageLiteral(resourceName: "Nathan")
        
        //        Becomes available if initialized with NTTimelineTableViewCell(style: .detailed)
        cell.durationLabel.text = "60 Min"
        cell.locationLabel.text = Lorem.words(nbWords: 2).capitalized
        //        cell.durationIconView.setFAIconWithName(icon: FAType.FAAdressCard, textColor: .black)
        
        if indexPath.row == 3 {
            cell.timeline.trailingColor = Color.Default.Tint.View
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.row == 4 {
            cell.timeline.leadingColor = Color.Default.Tint.View
        }
        return cell
    }
    
    // MARK: - User Actions
}
