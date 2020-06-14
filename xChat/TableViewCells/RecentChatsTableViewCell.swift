//
//  RecentChatsTableViewCell.swift
//  Sllick
//
//  Created by Isa  Selimi on 22.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit

protocol RecentChatsTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class RecentChatsTableViewCell: UITableViewCell {
    
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var lastMessageLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var messageCounterLabel: UILabel!
    @IBOutlet var messageCounterBackgroundView: UIView!
    @IBOutlet var onlineIndicatorView: UIView!
    @IBOutlet var activeView: UIView!
    var profileIsEmpty: Bool = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
//
//        self.avatarImageView.image = nil // or set a placeholder image
//        nameLabel.text = ""
//        lastMessageLabel.text = ""
//        dateLabel.text = ""
//        messageCounterLabel.text = ""
    }
    
    var img: UIImage?
    
    var delegate: RecentChatsTableViewCellDelegate?
    var indexPath: IndexPath!
    
    let tapGesture = UITapGestureRecognizer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageCounterBackgroundView.layer.cornerRadius = messageCounterBackgroundView.frame.width / 2
        onlineIndicatorView.layer.cornerRadius = onlineIndicatorView.frame.width / 2
        activeView.layer.cornerRadius = activeView.frame.width / 2
        selectionStyle = .none
        tapGesture.addTarget(self, action: #selector(avatarTapped))
        avatarImageView.addGestureRecognizer(tapGesture)
        avatarImageView.isUserInteractionEnabled = true
        lastMessageLabel.textColor = .secondaryLabel
        dateLabel.textColor = .tertiaryLabel
        messageCounterBackgroundView.backgroundColor = #colorLiteral(red: 0.0001922522367, green: 1, blue: 0.1971572093, alpha: 1)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc func avatarTapped() {
        delegate?.didTapAvatarImage(indexPath: indexPath)
    }
    
    // MARL: Generate cell
    
    func generateCell(isGroup: Bool, recentChat: NSDictionary, indexPath: IndexPath, isOnline: Bool, tabBarController: UITabBarController) {
        self.indexPath = indexPath
        
        nameLabel.text = recentChat[kWITHUSERFULLNAME] as? String
        onlineIndicatorView.isHidden = !isOnline
        
        var decryptedText = ""
        DispatchQueue.global().async {
            Encryption.decryptText(chatRoomId: recentChat[kCHATROOMID] as! String, encryptedMessage: recentChat[kLASTMESSAGE] as! String) { decryptedTxt in
                
                decryptedText = decryptedTxt
                var messageContent = ""
                if recentChat[kLASTMESSAGETYPE] as! String == "group_created" {
                    DispatchQueue.main.async {
                        self.lastMessageLabel.text = "No new messages"
                        self.lastMessageLabel.font = self.lastMessageLabel.font.italic
                    }
                    return
                } else if recentChat[kLASTMESSAGETYPE] as! String == "removed_message" {
                    DispatchQueue.main.async {
                        self.lastMessageLabel.text = "You removed a message"
                        self.lastMessageLabel.font = self.lastMessageLabel.font.italic
                    }
                    return
                }
                if self.currentUserRecent(recent: recentChat[kSENDERID] as! String) {
                    messageContent = "You"
                } else if isGroup || self.containsMedia(message: recentChat[kLASTMESSAGETYPE] as! String) {
                    messageContent = recentChat[kSENDERNAME] as! String
                }
                
                if recentChat[kLASTMESSAGETYPE] as! String == kPICTURE || recentChat[kLASTMESSAGETYPE] as! String == kVIDEO {
                    messageContent += " sent a \(decryptedText)"
                } else if recentChat[kLASTMESSAGETYPE] as! String == kAUDIO {
                    messageContent += " sent an audio message"
                } else {
                    messageContent += (isGroup || self.currentUserRecent(recent: recentChat[kSENDERID] as! String) ? ": " : "") + decryptedText
                }
                DispatchQueue.main.async {
                    self.lastMessageLabel.text = messageContent
                }
            }
        }
        
        messageCounterLabel.text = recentChat[kCOUNTER] as? String
        
        if let avatarString = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarString as! String) { image in
                
                if image != nil {
                    self.avatarImageView.image = image
                } else if !isGroup {
                    self.avatarImageView.image = UIImage(named: "avatarph")
                    
                } else {
                    self.avatarImageView.image = UIImage(named: "groupph")
                    profileIsEmpty = true
                }
                self.img = avatarImageView.image
                self.avatarImageView.maskCircle()
            }
        }
        
        if recentChat[kCOUNTER] as! Int != 0 {
            messageCounterBackgroundView.isHidden = false
            lastMessageLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold)
            lastMessageLabel.textColor = .label
            dateLabel.textColor = .secondaryLabel
        } else {
            messageCounterBackgroundView.isHidden = true
            messageCounterLabel.isHidden = true
            lastMessageLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
            lastMessageLabel.textColor = .secondaryLabel
            dateLabel.textColor = .tertiaryLabel
        }
        
        var date: Date!
        if let created = recentChat[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "MMM-dd-yyyy"  // change to your required format
//            dateFormatter.timeZone = TimeZone.current
//
//            // date with time portion in your specified timezone
//            print(dateFormatter.string(from: date))
        } else {
            date = Date()
        }
        
        dateLabel.text = "・" + timeElapsed(date: date)
    }
    
    func containsMedia(message: String) -> Bool {
        return message == kPICTURE || message == kVIDEO || message == kAUDIO || message == kLOCATION
    }
    
    func currentUserRecent(recent: String) -> Bool {
        return recent == FUser.currentId()
    }
}
