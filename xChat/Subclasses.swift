//
//  Subclasses.swift
//  SwiftExample
//
//  Created by XI on 8/29/16.
//  Copyright © 2016 MacMeDan. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class MessageViewIncoming: JSQMessagesCollectionViewCellIncoming {
    
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var timeLabelForMediaMessages: JSQMessagesLabel!
    @IBOutlet var leadingBubbleImageViewConstraint: NSLayoutConstraint!

    @IBOutlet var timeLabelLeadingConstraint: NSLayoutConstraint!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override class func nib() -> UINib {
        return UINib(nibName: "MessageViewIncoming", bundle: Bundle.main)
    }

    override class func cellReuseIdentifier() -> String {
        return "MessageViewIncoming"
    }

    override class func mediaCellReuseIdentifier() -> String {
        return "MessageViewIncoming_JSQMedia"
    }
}

class MessageViewOutgoing: JSQMessagesCollectionViewCellOutgoing {
    
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var timeLabelForMediaMessages: UILabel!
    @IBOutlet var trailingConstraint: NSLayoutConstraint!
    @IBOutlet var trailingAvatarConstraint: NSLayoutConstraint!
    @IBOutlet var trailingTimeLabelConstraint: NSLayoutConstraint!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override class func nib() -> UINib {
        return UINib(nibName: "MessageViewOutgoing", bundle: Bundle.main)
    }

    override class func cellReuseIdentifier() -> String {
        return "MessageViewOutgoing"
    }

    override class func mediaCellReuseIdentifier() -> String {
        return "MessageViewOutgoing_JSQMedia"
    }
}
