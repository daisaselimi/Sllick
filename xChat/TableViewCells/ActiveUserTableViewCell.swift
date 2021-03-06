//
//  ActiveUserTableViewCell.swift
//  Sllick
//
//  Created by Isa  Selimi on 10.4.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import UIKit

class ActiveUserTableViewCell: UITableViewCell {
    
    @IBOutlet var fullNameTextField: UILabel!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var activityIndicatorView: UIView!
    @IBOutlet var activityColorView: UIView!

    var indexPath: IndexPath!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
    }

    func generateCellWith(fUser: FUser, indexPath: IndexPath, isOnline: Bool = false) {
        activityIndicatorView.layer.cornerRadius = activityIndicatorView.frame.width / 2
        activityColorView.layer.cornerRadius = activityColorView.frame.width / 2
        avatarImageView.maskCircle()
        self.indexPath = indexPath
        activityIndicatorView.isHidden = !isOnline
        fullNameTextField.text = fUser.fullname
        if fUser.avatar != "" {
            imageFromData(pictureData: fUser.avatar) { image in
                if avatarImageView != nil {
                    self.avatarImageView.image = image
                }
            }
        } else {
            avatarImageView.image = UIImage(named: "avatarph")
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
