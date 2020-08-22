//
//  ChatViewController+UI Customization.swift
//  xChat
//
//  Created by Isa  Selimi on 14.8.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import Foundation
import JSQMessagesViewController

extension ChatViewController {
    
    func customizeInputToolbar() {
        var img = UIGraphicsImageRenderer(size: CGSize(width: 22, height: 25)).image {
            _ in
            UIImage(systemName: "mic.fill")?.draw(in: CGRect(x: 0, y: 0, width: 22, height: 25))
        }
        
        var imgl = UIGraphicsImageRenderer(size: CGSize(width: 22, height: 22)).image {
            _ in
            UIImage(systemName: "paperclip")?.draw(in: CGRect(x: 0, y: 0, width: 22, height: 22))
        }
        imgl = imgl.imageWithColor(color1: UIColor(named: "outgoingBubbleColor")!)
        inputToolbar.contentView.leftBarButtonItem.setImage(imgl, for: .normal)
        
        img = img.imageWithColor(color1: UIColor(named: "outgoingBubbleColor")!)
        inputToolbar.contentView.rightBarButtonItem.setImage(img, for: .normal)
        inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
        inputToolbar.contentView.textView.backgroundColor = .clear
        inputToolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        inputToolbar.contentView.textView.textColor = .label
        inputToolbar.contentView.textView.placeHolder = "Message..."
        inputToolbar.contentView.textView.layer.borderColor = UIColor.clear.cgColor
//        if UserDefaults.standard.object(forKey: kBACKGROUNDIMAGE) == nil {
//            inputToolbar.setBackgroundImage(UIImage(), forToolbarPosition: .bottom, barMetrics: .default)
//            inputToolbar.backgroundColor = .systemBackground
//            inputToolbar.isOpaque = true
//        }
        
    }
    
    func setUIForGroupChat() {
        imageFromData(pictureData: group![kAVATAR] as! String) { image in
            if image != nil && isPartOfGroup! {
                avatarButton.setImage(image!, for: .normal)
            } else if let isPartOfGrp = isPartOfGroup {
                if !isPartOfGrp {
                    avatarButton.setImage(initialImage, for: .normal)
                }
            } else {
                avatarButton.setImage(UIImage(named: "groupph"), for: .normal)
            }
        }
        
        titleLabel.text = (group![kNAME] as! String)
    }
    
    func customizeAvatarButton() {
        avatarButton.imageView?.contentMode = .scaleAspectFill
        avatarButton.layer.cornerRadius = 0.5 * avatarButton.bounds.size.width
        avatarButton.clipsToBounds = true
    }
    
    func setCustomTitle() {
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subTitleLabel)
        
        let img = UIImage(systemName: "ellipsis")
        
        let infoButton = UIBarButtonItem(image: img?.rotate(radians: .pi / 2), style: .plain, target: self, action: #selector(infoButtonPressed))
        
        navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        if isGroup! {
            avatarButton.addTarget(self, action: #selector(showGroup), for: .touchUpInside)
        } else {
            avatarButton.addTarget(self, action: #selector(showUserProfile), for: .touchUpInside)
        }
    }
    
    func setupChatBubbles() {
        if userDefaults.object(forKey: kBACKGROUNDIMAGE) != nil {
            outgoingBubble = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: UIEdgeInsets.zero)?.outgoingMessagesBubbleImage(with: UIColor(named: "outgoingBubbleColor"))
            incomingBubble = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: UIEdgeInsets.zero)?.incomingMessagesBubbleImage(with: UIColor(named: "incomingBubbleColor"))
        } else {
            outgoingBubble = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleRegularTailless(), capInsets: UIEdgeInsets.zero)?.outgoingMessagesBubbleImage(with: .systemGray6)
            incomingBubble = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleRegularStrokedTailless(), capInsets: UIEdgeInsets.zero)?.incomingMessagesBubbleImage(with: UIColor.tertiaryLabel)
        }
    }
    
    func setUIForSingleChat() {
        if withUsers.first == nil {
            subTitleLabel.text = "Deleted account"
            titleLabel.text = "Sllick User"
            avatarButton.setImage(UIImage(named: "avatarph"), for: .normal)
            inputToolbar.isHidden = true
            return
        }
        let withUser = withUsers.first!
        
        imageFromData(pictureData: withUser.avatar) { image in
            
            if image != nil {
                avatarButton.setImage(image!, for: .normal)
            } else {
                avatarButton.setImage(UIImage(named: "avatarph"), for: .normal)
            }
        }
        
        titleLabel.text = withUser.fullname
        
        checkActivityStatus()
        
        avatarButton.addTarget(self, action: #selector(showUserProfile), for: .touchUpInside)
    }
    
    func updateSendButton(isSend: Bool) {
        if isSend {
            var img = UIImage(systemName: "paperplane.fill")
            img = img!.imageWithColor(color1: UIColor(named: "outgoingBubbleColor")!)
            inputToolbar.contentView.rightBarButtonItem.setImage(img, for: .normal)
        } else {
            var img = UIGraphicsImageRenderer(size: CGSize(width: 22, height: 25)).image {
                _ in
                UIImage(systemName: "mic.fill")?.draw(in: CGRect(x: 0, y: 0, width: 22, height: 25))
            }
            img = img.imageWithColor(color1: UIColor(named: "outgoingBubbleColor")!)
            inputToolbar.contentView.rightBarButtonItem.setImage(img, for: .normal)
        }
        inputToolbar.contentView.rightBarButtonItem.isEnabled = true
    }
    
    func registerCustomCells() {
        incomingCellIdentifier = MessageViewIncoming.cellReuseIdentifier()
        collectionView.register(MessageViewIncoming.nib(), forCellWithReuseIdentifier: incomingCellIdentifier)
        outgoingCellIdentifier = MessageViewOutgoing.cellReuseIdentifier()
        collectionView.register(MessageViewOutgoing.nib(), forCellWithReuseIdentifier: outgoingCellIdentifier)
        
        incomingMediaCellIdentifier = MessageViewIncoming.mediaCellReuseIdentifier()
        collectionView.register(MessageViewIncoming.nib(), forCellWithReuseIdentifier: incomingMediaCellIdentifier)
        outgoingMediaCellIdentifier = MessageViewOutgoing.mediaCellReuseIdentifier()
        collectionView.register(MessageViewOutgoing.nib(), forCellWithReuseIdentifier: outgoingMediaCellIdentifier)
    }
}
