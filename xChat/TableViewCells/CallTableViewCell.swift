//
//  CallTableViewCell.swift
//  Sllick
//
//  Created by Isa  Selimi on 18.3.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import UIKit

class CallTableViewCell: UITableViewCell {
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func generateCellWith(call: CallClass) {
        dateLabel.text = formatCallTime(date: call.callDate)

        statusLabel.text = ""

        if call.callerId == FUser.currentId() {
            statusLabel.text = "Outgoing"
            fullNameLabel.text = call.withUserFullName
            avatarImageView.image = UIImage(systemName: "phone.fill.arrow.up.right")
            avatarImageView.tintColor = UIColor.label
        }
        else {
            statusLabel.text = "Incoming"
            fullNameLabel.text = call.callerFullName
            avatarImageView.image = UIImage(systemName: "phone.fill.arrow.down.left")
            avatarImageView.tintColor = UIColor.label
        }
    }
}
