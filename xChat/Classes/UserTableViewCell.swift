//
//  UserTableViewCell.swift
//  xChat
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
    @IBOutlet weak var avatarImage: UIImageView!
    
    
    @IBOutlet weak var fullNameLabel: UITextField!
    
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
    
    func generateCellWith(fUser: FUser, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.fullNameLabel.text = fUser.fullname
        
        if(fUser.avatar != "") {
            imageFromData(pictureData: fUser.avatar) { (image) in
                if avatarImage != nil {
                    self.avatarImage.image = image
                }
            }
        } else {
            self.avatarImage.image = UIImage(named: "avatarph")
        }
    }
    
    @objc func avatarTapped() {
        delegate!.didTapAvatarImage(indexPath: indexPath)
    }
    
}
