//
//  UserTableViewCell.swift
//  Sllick
//
//  Created by Isa  Selimi on 18.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class UserTableViewCell: UITableViewCell {
    
    var delegate: UserTableViewCellDelegate?
    @IBOutlet var avatarImage: UIImageView!
    
    @IBOutlet var fullNameLabel: UITextField!
    
    var indexPath: IndexPath!
    let tapGestureRecognizer = UITapGestureRecognizer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tapGestureRecognizer.addTarget(self, action: #selector(avatarTapped))
        avatarImage.maskCircle()
        avatarImage.isUserInteractionEnabled = true
        avatarImage.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func generateCellWith(fUser: FUser, indexPath: IndexPath, isOnline: Bool = false) {
        self.indexPath = indexPath
        fullNameLabel.text = fUser.fullname
        if fUser.avatar != "" {
            imageFromData(pictureData: fUser.avatar) { image in
                if avatarImage != nil {
                    self.avatarImage.image = image
                }
            }
        } else {
            avatarImage.image = UIImage(named: "avatarph")
        }
    }
    
    @objc func avatarTapped() {
        delegate!.didTapAvatarImage(indexPath: indexPath)
    }
}
