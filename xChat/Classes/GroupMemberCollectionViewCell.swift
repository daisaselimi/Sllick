//
//  GroupMemberCollectionViewCell.swift
//  Sllick
//
//  Created by Isa  Selimi on 9.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit

protocol GroupMemberCollectionViewCellDelegate {
    func didClickDeleteButton(indexPath: IndexPath)
    func didLongPressAvatarImage(indexPath: IndexPath)
    func didTapAvatarImage(indexPath: IndexPath)
}
 
extension GroupMemberCollectionViewCellDelegate {
    
}

class GroupMemberCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var indexPath: IndexPath!
    var delegate: GroupMemberCollectionViewCellDelegate?
    
    @IBOutlet weak var deleteButtonOutlet: UIButton!
    var longPressGestureRecognizer = UILongPressGestureRecognizer()
    var tapGestureRecognizer = UITapGestureRecognizer()
    
    override func prepareForReuse() {
        self.deleteButtonOutlet?.isHidden = true
    }
    
    override func awakeFromNib() {
        
        longPressGestureRecognizer.addTarget(self, action: #selector(self.avatarImageLongPressed))
        tapGestureRecognizer.addTarget(self, action: #selector(self.avatarImageTapped))
        avatarImage.addGestureRecognizer(tapGestureRecognizer)
        avatarImage.addGestureRecognizer(longPressGestureRecognizer)
        avatarImage.isUserInteractionEnabled = true
        self.deleteButtonOutlet?.isHidden = true
    }
    func generateCell(user: FUser, indexPath: IndexPath) {
        self.indexPath = indexPath
        label.text = user.firstname
        
        if user.avatar != "" {
            
            imageFromData(pictureData: user.avatar) { (avatarImage) in
                
                if avatarImage != nil {
                    self.avatarImage.image = avatarImage
                    self.avatarImage.maskCircle()
                }
            }
        } else {
            self.avatarImage.image = UIImage(named: "avatarph")
            self.avatarImage.maskCircle()
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        delegate!.didClickDeleteButton(indexPath: indexPath)
    }
    
    @objc func avatarImageTapped() {
        delegate!.didTapAvatarImage(indexPath: indexPath)
    }
    
    @objc func avatarImageLongPressed() {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {

            delegate!.didLongPressAvatarImage(indexPath: indexPath)
        }
    }
    
    
    
}
