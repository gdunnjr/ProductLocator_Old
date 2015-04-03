//
//  FilterTableViewCell.swift
//  ProductLocator
//
//  Created by Gerald Dunn on 3/27/15.
//  Copyright (c) 2015 Gerald Dunn. All rights reserved.
//

import UIKit

class FilterTableViewCell: UITableViewCell {

    @IBOutlet var brandLabel: UILabel!
    @IBOutlet var brandImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
