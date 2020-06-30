//
//  ChatViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 23.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import AVFoundation
import AVKit
import Firebase
import FirebaseFirestore
import GradientLoadingBar
import IDMPhotoBrowser
import IQAudioRecorderController
import JSQMessagesViewController
import OneSignal
import ProgressHUD
import SKPhotoBrowser
import UIKit

class ChatViewController: JSQMessagesViewController, UINavigationControllerDelegate, IQAudioRecorderViewControllerDelegate, GroupDelegate {
    
    var chatRoomId: String!
    var memberIds: [String]!
    var membersToPush: [String]!
    var titleName: String!
    
    var initialImage: UIImage?
    var initialWithUser: String?
    
    var isGroup: Bool?
    var group: NSDictionary?
    var isPartOfGroup: Bool?
    
    var legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    var allPictureMessages: [String] = []
    var initialLoadComplete = false
    var firstLoading = true
    
    var recentListener: ListenerRegistration!
    
    var withUsers: [FUser] = []
    
    var prevD: Date?
    var previousDate: Date?
    
    var maxMessageNumber = 0
    var minMessageNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    
    var typingCounter = 0
    
    var typingListener: ListenerRegistration!
    var newChatListener: ListenerRegistration!
    var updatedChatListener: ListenerRegistration!
    
    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImageDictionary: NSMutableDictionary?
    var showAvatars = true
    var firstLoad: Bool?
    
    var isUserDeleted: Bool?
    
    var firstLoadMessages = false
    
    var outgoingBubble: JSQMessagesBubbleImage?
    var incomingBubble: JSQMessagesBubbleImage?
    var activityListener: ListenerRegistration!
    
    private let gradientLoadingBar = GradientLoadingBar()
    
    var leftBarButtonView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 45))
        return view
    }()
    
    var avatarButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 5, width: 35, height: 35))
        return button
    }()
    
    let titleLabel: UILabel = {
        let title = UILabel(frame: CGRect(x: 40, y: 5, width: 150, height: 20))
        title.textAlignment = .left
        title.font = UIFont(name: "Helvetica Neue", size: 18)
        return title
    }()
    
    let subTitleLabel: UILabel = {
        let subTitle = UILabel(frame: CGRect(x: 40, y: 23, width: 140, height: 16))
        subTitle.textAlignment = .left
        subTitle.textColor = UIColor(hexString: "#808080")
        subTitle.font = UIFont(name: "Helvetica Neue", size: 11)
        return subTitle
    }()
    
    //    //for iphone x<
    //    override func viewDidLayoutSubviews() {
    //        perform(Selector(("jsq_updateCollectionViewInsets")))
    //    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkForBackgroundImage()
        clearRecentCounter(chatRoomId: chatRoomId)
        inputToolbar.contentView.rightBarButtonItem.isEnabled = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(internetConnectionChanged),
                                               name: .internetConnectionState, object: nil)
        view.backgroundColor = .systemBackground
        showTypingIndicator = false
        gradientLoadingBar.gradientColors = [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
        loadMessages()
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "", style: .plain, target: nil, action: nil)
        if let isDeleted = isUserDeleted {
            if isDeleted {
                titleLabel.text = "Sllick User"
                inputToolbar.isHidden = true
                
                subTitleLabel.text = "Deleted account"
                
                avatarButton.setImage(UIImage(named: "avatarph"), for: .normal)
            }
        }
        
        titleLabel.text = initialWithUser ?? ""
        avatarButton.setImage(initialImage!, for: .normal)
        subTitleLabel.text = isGroup! ? "Group chat" : "Sllick Chat"
        
        if let isPartOfGr = isPartOfGroup {
            if !isPartOfGr {
                inputToolbar.isHidden = true
                avatarButton.isUserInteractionEnabled = false
            }
        }
        
        if !isGroup! {
            if let isDeleted = isUserDeleted {
                if !isDeleted {
                    listenForBlockStatus()
                }
            } else {
                listenForBlockStatus()
            }
        }
        gradientLoadingBar.fadeIn()
        getUsersFromFirestore(withIds: memberIds) { withUsers in
            
            self.withUsers = withUsers
            
            // get avatars
            self.getAvatarImages()
            
            if !self.isGroup! {
                self.setUIForSingleChat()
            }
        }
        createTypingObserver()
        loadUserDefaults()
        firstLoadMessages = true
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete))
        
        var imgl = UIGraphicsImageRenderer(size: CGSize(width: 22, height: 22)).image {
            _ in
            UIImage(systemName: "paperclip")?.draw(in: CGRect(x: 0, y: 0, width: 22, height: 22))
        }
        imgl = imgl.imageWithColor(color1: UIColor(named: "outgoingBubbleColor")!)
        inputToolbar.contentView.leftBarButtonItem.setImage(imgl, for: .normal)
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(backAction))]
        senderId = FUser.currentId()
        senderDisplayName = FUser.currentUser()!.firstname
        
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        jsqAvatarDictionary = [:]
        
        setCustomTitle()
        if isGroup! {
            getCurrentGroup(withId: chatRoomId)
        }
        // fix for iphone x<
        //        let constraints = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        //        constraints.priority = UILayoutPriority(rawValue: 1000)
        //        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        // custon send button
        var img = UIGraphicsImageRenderer(size: CGSize(width: 22, height: 25)).image {
            _ in
            UIImage(systemName: "mic.fill")?.draw(in: CGRect(x: 0, y: 0, width: 22, height: 25))
        }
        img = img.imageWithColor(color1: UIColor(named: "outgoingBubbleColor")!)
        inputToolbar.contentView.rightBarButtonItem.setImage(img, for: .normal)
        inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
        inputToolbar.contentView.textView.backgroundColor = .clear
        inputToolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        inputToolbar.contentView.textView.textColor = .label
        inputToolbar.contentView.textView.placeHolder = "New message"
        inputToolbar.contentView.textView.layer.borderColor = UIColor.clear.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !MyVariables.globalContactsVariable.contains((memberIds.filter { $0 != FUser.currentId() })[0]) {
            subTitleLabel.text = "Sllick Chat"
        } else {
            checkActivityStatus()
        }
        
        if let viewWithTag = view.viewWithTag(0) {
            viewWithTag.isHidden = false
        }
        //        let item = self.collectionView(self.collectionView, numberOfItemsInSection: 0) - 1
        //        let lastItemIndex = NSIndexPath(item: item, section: 0)
        //        self.collectionView.scrollToItem(at: lastItemIndex as IndexPath, at: .top, animated: true)
        //        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        
        if !isGroup! {
            recentListener = reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId as Any).addSnapshotListener { snapshot, _ in
                guard let snapshot = snapshot else { return }
                
                if !snapshot.isEmpty {
                    let docs = snapshot.documents
                    for doc in docs {
                        self.membersToPush = (doc[kMEMBERSTOPUSH] as! [String])
                    }
                }
            }
        }
        
        avatarButton.imageView?.contentMode = .scaleAspectFill
        avatarButton.layer.cornerRadius = 0.5 * avatarButton.bounds.size.width
        avatarButton.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        inputToolbar.contentView.textView.resignFirstResponder()
        recentListener?.remove()
        
        gradientLoadingBar.fadeOut(duration: 0)
        if let viewWithTag = view.viewWithTag(0) {
            if userDefaults.object(forKey: kBACKGROUBNDIMAGE) != nil {
                view.subviews[0].backgroundColor = .systemBackground
                view.window?.backgroundColor = .systemBackground
                viewWithTag.isHidden = true
            }
        }
        //        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
        //        removeListeners()
        // newChatListener.remove()
        activityListener?.remove()
        clearRecentCounter(chatRoomId: chatRoomId)
    }
    
    @objc func internetConnectionChanged() {
        if !MyVariables.internetConnectionState {
            showMessage("No internet connection", type: .warning, options: [.autoHide(false), .hideOnTap(false), .textColor(.label)])
            // self.loadViewIfNeeded()
        } else {
            hideMessage()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor(named: "outgoingBubbleColor"))
        incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: UIColor(named: "incomingBubbleColor"))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.window?.backgroundColor = .black
    }
    
    override func viewWillLayoutSubviews() {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    func createTypingObserver() {
        typingListener = reference(.Typing).document(chatRoomId).addSnapshotListener { snapshot, _ in
            
            guard let snapshot = snapshot else { return }
            
            if snapshot.exists {
                for data in snapshot.data()! {
                    if data.key != FUser.currentId() {
                        let typing = data.value as! Bool
                        self.showTypingIndicator = typing
                        
                        if typing {
                            self.scrollToBottom(animated: true)
                        }
                    }
                }
            } else {
                reference(.Typing).document(self.chatRoomId).setData([FUser.currentId(): false])
            }
        }
    }
    
    // MARK: Group delegate
    
    func updatedGroupMembers(group: NSDictionary) {
        print("hihihihh:  \((group[kMEMBERS] as! [String]).count)")
        self.group = group
    }
    
    func typingCounterStart() {
        typingCounter += 1
        saveTypingCounter(type: true)
        perform(#selector(typingCounterStop), with: nil, afterDelay: 2.0)
    }
    
    @objc func typingCounterStop() {
        typingCounter -= 1
        
        if typingCounter == 0 {
            saveTypingCounter(type: false)
        }
    }
    
    func saveTypingCounter(type: Bool) {
        reference(.Typing).document(chatRoomId).updateData([FUser.currentId(): type])
    }
    
    func setCustomTitle() {
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subTitleLabel)
        
        let img = UIImage(systemName: "ellipsis")
        
        
        let infoButton = UIBarButtonItem(image: img?.rotate(radians: .pi/2), style: .plain, target: self, action: #selector(infoButtonPressed))
        
        navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        if isGroup! {
            avatarButton.addTarget(self, action: #selector(showGroup), for: .touchUpInside)
        } else {
            avatarButton.addTarget(self, action: #selector(showUserProfile), for: .touchUpInside)
        }
    }
    
    func getAvatarImages() {
        if showAvatars {
            collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
            
            // get current user avatar
            avatarImageFrom(fUser: FUser.currentUser()!)
            
            for user in withUsers {
                avatarImageFrom(fUser: user)
            }
            collectionView.reloadData()
        }
    }
    
    func avatarImageFrom(fUser: FUser) {
        if fUser.avatar != "" {
            dataImageFromString(pictureString: fUser.avatar) { imageData in
                
                if imageData == nil {
                    return
                }
                
                if self.avatarImageDictionary != nil {
                    self.avatarImageDictionary!.removeObject(forKey: fUser.objectId)
                    self.avatarImageDictionary?.setObject(imageData!, forKey: fUser.objectId as NSCopying)
                } else {
                    self.avatarImageDictionary = [fUser.objectId: imageData!]
                }
                
                // create JSQAvatars
                createJSQAvatars(avatarDictionary: avatarImageDictionary!)
            }
        }
    }
    
    func createJSQAvatars(avatarDictionary: NSMutableDictionary?) {
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarph"), diameter: 70)
        
        if avatarDictionary != nil {
            var tempMemberIds = memberIds
            if !tempMemberIds!.contains(FUser.currentId()) {
                tempMemberIds!.append(FUser.currentId())
            }
            for memberId in tempMemberIds! {
                if let avatarImageData = avatarDictionary![memberId] {
                    var image = UIImage(data: avatarImageData as! Data)
                    image = image?.cropsToSquare()
                    let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 70)
                    
                    jsqAvatarDictionary!.setValue(jsqAvatar, forKey: memberId)
                } else {
                    jsqAvatarDictionary!.setValue(defaultAvatar, forKey: memberId)
                }
            }
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
    
    func checkActivityStatus() {
        if firstLoading {
            firstLoading = false
            return
        }
        if !MyVariables.globalContactsVariable.contains((memberIds.filter { $0 != FUser.currentId() })[0]) {
            return
        }
        
        activityListener = Firestore.firestore().collection("status").whereField("userId", isEqualTo: withUsers.first!.objectId).addSnapshotListener { snapshot, _ in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                let doc = snapshot.documents[0]
                if doc["state"] as! String == "Online" {
                    self.subTitleLabel.text = "Active now"
                } else {
                    let lastChanged = (doc["last_changed"] as! Timestamp)
                    let timestamp = lastChanged.dateValue().timeIntervalSince1970
                    let date = Date(timeIntervalSince1970: timestamp)
                    self.subTitleLabel.text = "Active \(date.timeAgoSinceDate())"
                }
            }
        }
    }
    
    func setUIForGroupChat() {
        imageFromData(pictureData: group![kAVATAR] as! String) { image in
            if image != nil {
                avatarButton.setImage(image!, for: .normal)
            } else {
                avatarButton.setImage(UIImage(named: "groupph"), for: .normal)
            }
        }
        
        titleLabel.text = (group![kNAME] as! String)
    }
    
    @objc func infoButtonPressed() {
        let mediaVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mediaView") as! PicturesCollectionViewController
        mediaVC.allImageLinks = allPictureMessages
        
        navigationController?.pushViewController(mediaVC, animated: true)
    }
    
    @objc func showGroup() {
        if let group = group {
            let groupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "groupView") as! GroupTableViewController
            groupVC.group = group
            groupVC.delegate = self
            navigationController?.pushViewController(groupVC, animated: true)
        }
    }
    
    @objc func showUserProfile() {
        if withUsers.first == nil {
            return
        }
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileTableViewController
        
        profileVC.user = withUsers.first!
        
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func addNewPictureMessageLink(link: String) {
        allPictureMessages.append(link)
    }
    
    func getPictureMessages() {
        allPictureMessages = []
        for message in loadedMessages {
            if message[kTYPE] as! String == kPICTURE {
                allPictureMessages.append(message[kPICTURE] as! String)
            }
        }
    }
    
    // MARK: IQAudioDelegate
    
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        controller.dismiss(animated: true, completion: nil)
        sendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
    }
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func backAction() {
        removeListeners()
        // clearRecentCounter(chatRoomId: chatRoomId)
        let i = navigationController?.viewControllers.firstIndex(of: self)
        if (navigationController?.viewControllers[i! - 1] as? NewGroupViewController) != nil {
            navigationController?.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func listenForBlockStatus() {
        if let member = memberIds.filter({ $0 != FUser.currentId() }).first {
            reference(.User).document(member).addSnapshotListener { document, error in
                if error != nil {
                    return
                }
                if let document = document {
                    if !document.data()!.isEmpty {
                        if (document[kBLOCKEDUSERID] as! [String]).contains(FUser.currentId()) {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Custom send button
    
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
    
    // MARK: Send messages
    
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        var outgoingMessage: OutgoingMessage?
        let currentUser = FUser.currentUser()
        if isGroup! {
            membersToPush = (group![kMEMBERSTOPUSH] as! [String])
            memberIds = (group![kMEMBERS] as! [String])
        }
        
        if let text = text {
            let encryptedText = Encryption.encryptText(chatRoomId: chatRoomId, message: text)
            outgoingMessage = OutgoingMessage(message: encryptedText, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: date, status: kDELIVERED, type: kTEXT)
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            finishSendingMessage()
            outgoingMessage!.sendMessage(chatRoomID: chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: memberIds, membersToPush: membersToPush, lastMessageType: kTEXT, isGroup: isGroup! ? true : false, groupName: isGroup! ? (group![kNAME] as! String) : "", chatTitle: titleLabel.text!, plainMessage: text)
        }
        
        if let pic = picture {
            uploadImage(image: pic, chatRoomId: chatRoomId, view: navigationController!.view) { imageLink in
                
                if imageLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: kPICTURE)
                    outgoingMessage = OutgoingMessage(message: encryptedText, pictureLink: imageLink!, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage?.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush, lastMessageType: kPICTURE, isGroup: self.isGroup! ? true : false, groupName: self.isGroup! ? (self.group![kNAME] as! String) : "", chatTitle: self.titleLabel.text!)
                }
            }
            return
        }
        
        if let video = video {
            let videoData = NSData(contentsOfFile: video.path!)
            let dataThumbnail = videoThumbnail(video: video).jpegData(compressionQuality: 0.3)
            
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: navigationController!.view) { videoLink in
                
                if videoLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: kVIDEO)
                    outgoingMessage = OutgoingMessage(message: encryptedText, video: videoLink!, thumbnail: dataThumbnail! as NSData, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage?.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush, lastMessageType: kVIDEO, isGroup: self.isGroup! ? true : false, groupName: self.isGroup! ? (self.group![kNAME] as! String) : "", chatTitle: self.titleLabel.text!)
                }
            }
        }
        
        if let audio = audio {
            uploadAudio(audioPath: audio, chatRoomId: chatRoomId, view: navigationController!.view) { audioLink in
                
                if audioLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: kAUDIO)
                    
                    outgoingMessage = OutgoingMessage(message: encryptedText, audio: audioLink!, senderId: currentUser!.objectId, senderName: currentUser!.firstname, date: date, status: kDELIVERED, type: kAUDIO)
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    outgoingMessage?.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush, lastMessageType: kAUDIO, isGroup: self.isGroup! ? true : false, groupName: self.isGroup! ? (self.group![kNAME] as! String) : "", chatTitle: self.titleLabel.text!)
                }
            }
        }
    }
    
    // MARK: Load messages
    
    var groupChangedListener: ListenerRegistration!
    
    func loadMessages() {
        // update message status
        updatedChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener { snapshot, _ in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                snapshot.documentChanges.forEach { diff in
                    
                    if diff.type == .modified {
                        self.updateMessage(messageDictionary: diff.document.data() as NSDictionary)
                    }
                }
            }
        }
        
        // get last 21 messages
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 21).getDocuments(completion: { snapshot, error in
            self.internetConnectionChanged()
            if let error = error {
                self.gradientLoadingBar.fadeOut(duration: 0)
                if let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode.rawValue {
                    case 8: self.showMessage("Transaction limit exceeded. Try again later.", type: .error, options: [.autoHide(false), .hideOnTap(false)])
                    default: self.showMessage(kSOMETHINGWENTWRONG, type: .error, options: [.autoHide(false), .hideOnTap(false)]); print("LOCALIZED DESC: \(errorCode)")
                    }
                }
                self.inputToolbar.isUserInteractionEnabled = false
                return
            }
            guard let snapshot = snapshot else {
                self.initialLoadComplete = true
                self.listenForNewChat()
                return
            }
            
            let sorted = (dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            // remove bad messages
            self.loadedMessages = sorted
            self.insertMessages()
            self.finishReceivingMessage(animated: true)
            self.initialLoadComplete = true
            print("we have \(self.messages.count) messages loaded")
            // get pictures
            
            self.listenForNewChat()
            self.getPictureMessages()
            // get old messages in background
            self.getOldMessagesInBackground()
            self.gradientLoadingBar.fadeOut()
            
        })
    }
    
    func updateMessage(messageDictionary: NSDictionary) {
        for index in 0..<objectMessages.count {
            let temp = objectMessages[index]
            
            if messageDictionary[kMESSAGE] as! String == temp[kMESSAGE] as! String {
                objectMessages[index] = messageDictionary
                collectionView!.reloadData()
            }
        }
    }
    
    func listenForNewChat() {
        var lastMessageDate = "0"
        
        if loadedMessages.count > 0 {
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }
        
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener { snapshot, _ in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                for diff in snapshot.documentChanges {
                    if diff.type == .added {
                        let item = diff.document.data() as NSDictionary
                        
                        if let type = item[kTYPE] {
                            if self.legitTypes.contains(type as! String) {
                                if type as! String == kPICTURE {
                                    self.addNewPictureMessageLink(link: item[kPICTURE] as! String)
                                }
                                if self.insertInitialLoadMessages(messageDictionary: item) {
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                self.finishReceivingMessage()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // insert messages
    func insertMessages() {
        maxMessageNumber = loadedMessages.count - loadedMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in minMessageNumber..<maxMessageNumber {
            let messageDictionary = loadedMessages[i]
            
            _ = insertInitialLoadMessages(messageDictionary: messageDictionary)
            
            loadedMessagesCount += 1
        }
        
        showLoadEarlierMessagesHeader = loadedMessagesCount != loadedMessages.count
    }
    
    func insertInitialLoadMessages(messageDictionary: NSDictionary) -> Bool {
        let incomingMessage = IncomingMessage(collectionVIew_: collectionView!)
        
        // check if incoming
        if messageDictionary[kSENDERID] as! String != FUser.currentId() {
            OutgoingMessage.updateMessage(withId: messageDictionary[kMESSAGEID] as! String,
                                          chatRoomId: chatRoomId, memberIds: memberIds)
        }
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        
        return isIncoming(messageDictionary: messageDictionary)
    }
    
    func isIncoming(messageDictionary: NSDictionary) -> Bool {
        if FUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        } else {
            return true
        }
    }
    
    func readTimeFrom(dateString: String) -> String {
        let date = dateFormatter().date(from: dateString)
        
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:mm"
        return currentDateFormat.string(from: date!)
    }
    
    func removeSuspiciousMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
        var tempMessages = allMessages
        
        for message in tempMessages {
            if message[kTYPE] != nil {
                if !legitTypes.contains(message[kTYPE] as! String) {
                    tempMessages.remove(at: tempMessages.firstIndex(of: message)!)
                }
            }
        }
        return tempMessages
    }
    
    func getOldMessagesInBackground() {
        if loadedMessages.count > kNUMBEROFMESSAGES {
            let firstMessageDate = loadedMessages.first![kDATE] as! String
            
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { snapshot, _ in
                
                guard let snapshot = snapshot else { return }
                
                let sorted = (dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                self.loadedMessages = self.removeSuspiciousMessages(allMessages: sorted) + self.loadedMessages
                
                // get the picture messages
                self.getPictureMessages()
                self.maxMessageNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
            }
        }
    }
    
    func loadMoreMessages(maxNumer: Int, minNumber: Int) {
        if loadOld {
            maxMessageNumber = minNumber - 1
            minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        }
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in (minMessageNumber...maxMessageNumber).reversed() {
            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        
        loadOld = true
        showLoadEarlierMessagesHeader = loadedMessagesCount != loadedMessages.count
    }
    
    func insertNewMessage(messageDictionary: NSDictionary) {
        let incomingMessage = IncomingMessage(collectionVIew_: collectionView!)
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
    }
    
    func removeListeners() {
        if typingListener != nil {
            typingListener.remove()
        }
        
        if newChatListener != nil {
            newChatListener.remove()
        }
        
        if updatedChatListener != nil {
            updatedChatListener.remove()
        }
    }
    
    func loadUserDefaults() {
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(showAvatars, forKey: kSHOWAVATAR)
            userDefaults.synchronize()
        }
        
        showAvatars = userDefaults.bool(forKey: kSHOWAVATAR)
    }
    
    func checkForBackgroundImage() {
        // navigationController?.navigationBar.setBackgroundImage(imageVIew.image!, for: .compact)
        //        navigationController?.navigationBar.shadowImage = UIImage()
        //        navigationController?.navigationBar.isTranslucent = true
        //        navigationController?.view.backgroundColor = UIColor.clear
        //        navigationController?.navigationBar.backgroundColor = UIColor.clear
        if userDefaults.object(forKey: kBACKGROUBNDIMAGE) != nil {
            collectionView.backgroundColor = .clear
            let width = UIScreen.main.bounds.width
            let height = UIScreen.main.bounds.height
            let imageVIew = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            imageVIew.image = UIImage(named: userDefaults.object(forKey: kBACKGROUBNDIMAGE) as! String)!
            imageVIew.contentMode = .scaleAspectFill
            imageVIew.tag = 0
            view.insertSubview(imageVIew, at: 0)
            // self.view.backgroundColor = UIColor(patternImage: imageVIew.image!)
            
        } else {
            collectionView?.backgroundColor = .systemBackground
        }
    }
    
    func getCurrentGroup(withId: String) {
        reference(.Group).document(withId).getDocument { snapshot, _ in
            
            guard let snapshot = snapshot else { return }
            
            if snapshot.exists {
                self.group = (snapshot.data()! as NSDictionary)
                
                if !(self.group![kMEMBERS] as! [String]).contains(FUser.currentId()) {
                    self.inputToolbar.isHidden = true
                } else {
                    self.inputToolbar.isHidden = false
                }
                
                print("---------^^^^^^" + (self.group![kOWNERID] as! String))
                
                if self.group![kOWNERID] as! String == FUser.currentId() {
                    self.subTitleLabel.text = "Created by you"
                } else {
                    getUsersFromFirestore(withIds: [self.group![kOWNERID] as! String]) {
                        print($0.count)
                        self.subTitleLabel.text = "Created by \($0.count == 0 ? "a Sent user" : $0[0].firstname)"
                    }
                }
                
                self.groupChangedListener = reference(.Group).whereField(kGROUPID, isEqualTo: self.group![kGROUPID] as! String).addSnapshotListener { snapshot, _ in
                    
                    guard let snapshot = snapshot else { return }
                    
                    if !snapshot.isEmpty {
                        snapshot.documentChanges.forEach { diff in
                            
                            if diff.type == .modified {
                                self.group = diff.document.data() as NSDictionary
                                if !(self.group![kMEMBERS] as! [String]).contains(FUser.currentId()) {
                                    self.inputToolbar.isHidden = true
                                    self.avatarButton.isUserInteractionEnabled = false
                                } else {
                                    self.inputToolbar.isHidden = false
                                    self.avatarButton.isUserInteractionEnabled = true
                                    updateExistingRecentWithNewValues(forMembers: self.group![kMEMBERS] as! [String], chatRoomId: self.group![kGROUPID] as! String, withValues: [kAVATAR: self.group![kAVATAR] as Any, kWITHUSERFULLNAME: self.group![kNAME]!])
                                }
                            }
                        }
                    }
                }
            }
            self.setUIForGroupChat()
        }
    }
    
    // MARK: Supporting  only portrait mode
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
}

// MARK: Iphone X Layout FIX

extension JSQMessagesInputToolbar {
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else { return }
        if #available(iOS 11.0, *) {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        sendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        
        picker.dismiss(animated: true, completion: nil)
    }
}

// CollectionView delegates/data source
extension ChatViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId() {
            cell.textView?.textColor = .white
        } else {
            cell.textView?.textColor = .label
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        self.collectionView.reloadData()
        
        loadMoreMessages(maxNumer: maxMessageNumber, minNumber: minMessageNumber)
        
        print("load more....")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId() {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if messages[indexPath.row].senderId != FUser.currentId(), isGroup! {
            return 30
        }
        return 5
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if messages[indexPath.row].senderId == FUser.currentId() || !isGroup! {
            return NSAttributedString(string: "")
        }
        return NSAttributedString(string: messages[indexPath.row].senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if prevD == nil {
            prevD = messages[indexPath.row].date()
        }
        
        if indexPath.item % 5 == 0 || prevD!.stripTime() < messages[indexPath.row].date.stripTime() {
            let message = messages[indexPath.row]
            prevD = message.date
            
            return NSAttributedString(string: message.date.timeAgoInMessages())
            // return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
        } else {
            return nil
        }
    }
    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView?, attributedTextForCellTopLabelAt indexPath: IndexPath?) -> NSAttributedString? {
//
//        let message = self.messages[indexPath!.item]
//        if indexPath!.item == 0 {
//                            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
//                        }
//
//        if indexPath!.item -  1 > 0{
//            let previousMessage = self.messages[indexPath!.item - 1 ]
//
//                            if  ( ( message.date.timeIntervalSince(previousMessage.date) / 60 ) > 1){
//                                return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
//                            }
//                        }
//
//                        return nil
//        }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = objectMessages[indexPath.row]
        
        let status: NSAttributedString
        
        let attributetStringColor = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)
            status = NSAttributedString(string: statusText, attributes: attributetStringColor)
        default:
            status = NSAttributedString(string: "✔️")
        }
        
        if indexPath.row == (messages.count - 1) {
            return status
        } else {
            return NSAttributedString(string: "")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        var avatar: JSQMessageAvatarImageDataSource
        if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId!) {
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        } else {
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarph"), diameter: 70)
        }
        
        return avatar
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId(), indexPath.row == objectMessages.count - 1 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
//    override func collectionView(
//        _ collectionView: JSQMessagesCollectionView?,
//        layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout?,
//        heightForCellTopLabelAt indexPath: IndexPath?
//    ) -> CGFloat {
//
//        if indexPath!.item == 0 {
//            return kJSQMessagesCollectionViewCellLabelHeightDefault
//        }
//
//        if indexPath!.item -  1 > 0{
//            let message = self.messages[indexPath!.item]
//            let previousMessage = self.messages[indexPath!.item - 1 ]
//
//            if  ( ( message.date.timeIntervalSince(previousMessage.date) / 60 ) > 1){
//                return kJSQMessagesCollectionViewCellLabelHeightDefault
//            }
//        }
//        return 0.0
//    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if previousDate == nil {
            previousDate = messages[indexPath.row].date()
        }
        
        if indexPath.item % 5 == 0 || previousDate!.stripTime() < messages[indexPath.row].date.stripTime() {
            previousDate = messages[indexPath.row].date
            
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        switch messageType {
        case kPICTURE:
            let message = messages[indexPath.row]
            var images = [SKPhoto]()
            let mediaItem = message.media as! JSQPhotoMediaItem
            if mediaItem.image == nil {
                return
            }
            let photo = SKPhoto.photoWithImage(mediaItem.image!)
            images.append(photo)
            let browser = SKPhotoBrowser(photos: images)
            present(browser, animated: true, completion: nil)
        case kLOCATION: print("location message tapped")
        case kVIDEO:
            print("location message tapped")
            let message = messages[indexPath.row]
            let mediaItem = message.media as! VideoMessage
            let player = AVPlayer(url: mediaItem.fileURL! as URL)
            let moviePlayer = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            
            moviePlayer.player = player
            present(moviePlayer, animated: true) {
                moviePlayer.player!.play()
            }
        default: print("unknown message tapped")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        if withUsers.first == nil && !isGroup! {
            return
        }
        
        let senderID = messages[indexPath.row].senderId
        var selectedUser: FUser?
        
        if senderID == FUser.currentId() {
            selectedUser = FUser.currentUser()
        } else {
            for user in withUsers {
                if user.objectId == senderID {
                    selectedUser = user
                }
            }
        }
        
        if selectedUser == nil || selectedUser == FUser.currentUser() {
            return
        }
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileTableViewController
        
        profileVC.user = selectedUser
        profileVC.fromGroup = isGroup! ? true : false
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    // for multimedia messages delete option
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        // super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if messages[indexPath.row].isMediaMessage {
            if action.description == "delete:" {
                return true
            } else {
                return false
            }
        } else {
            if action.description == "delete:" || action.description == "copy:" {
                return true
            } else {
                return false
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        let messageId = objectMessages[indexPath.row][kMESSAGEID] as! String
        
        objectMessages.remove(at: indexPath.row)
        messages.remove(at: indexPath.row)
        
        // delete message from firebase
        OutgoingMessage.deleteMessage(withId: messageId, chatRoomId: chatRoomId)
        if indexPath.row == messages.count {
            updateExistingRecentWithNewValues(forMembers: [FUser.currentId()], chatRoomId: chatRoomId, withValues: [kLASTMESSAGETYPE: "removed_message", kDATE: dateFormatter().string(from: Date())])
        }
    }
}

// JSQMessage delegates
extension ChatViewController {
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        typingCounterStart()
        return true
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        if !MyVariables.internetConnectionState {
            showMessage("No internet connection", type: .warning, options: [.autoHide(false), .hideOnTap(false), .textColor(.label)])
            return
        }
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let camera = Camera(delegate_: self)
        
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { _ in
            checkCameraAccess(viewController: self) {
                accessStatus in
                if accessStatus == .authorized {
                    DispatchQueue.main.async {
                        camera.PresentMultyCamera(target: self, canEdit: false)
                    }
                }
            }
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { _ in
            checkCameraAccess(viewController: self) {
                accessStatus in
                if accessStatus == .authorized {
                    DispatchQueue.main.async {
                        camera.PresentPhotoLibrary(target: self, canEdit: false)
                    }
                }
            }
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { _ in
            checkCameraAccess(viewController: self) {
                accessStatus in
                if accessStatus == .authorized {
                    DispatchQueue.main.async {
                        camera.PresentVideoLibrary(target: self, canEdit: false)
                    }
                }
            }
        }
        
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { _ in
            
            print("share location")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        }
        
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(cancelAction)
        
        // for iPad compatibility mode
        optionMenu.view.tintColor = UIColor.getAppColor(.light)
        if UIDevice().userInterfaceIdiom == .pad {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                present(optionMenu, animated: true, completion: nil)
            }
        }
        present(optionMenu, animated: true, completion: nil)
    }
    
    // send button
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
            print(text!)
            sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            updateSendButton(isSend: false)
            collectionView.reloadData()
        } else {
            if !MyVariables.internetConnectionState {
                showMessage("No internet connection", type: .warning, options: [.autoHide(false), .hideOnTap(false), .textColor(.label)])
                return
            }
            internetConnectionChanged()
            let audioVC = AudioViewController(delegate_: self)
            audioVC.presentAudioRecorder(target: self)
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        //        if textView.text.trimmingCharacters(in: .whitespaces).isEmpty  {
        //            return
        //        }
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
    }
}
