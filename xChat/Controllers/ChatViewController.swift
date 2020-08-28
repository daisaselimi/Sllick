//
//  ChatViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 23.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import AVFoundation
import AVKit
import DZNEmptyDataSet
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
    
    var legitTypes = [kAUDIO, kVIDEO, kTEXT, kPICTURE, kSYSTEMMESSAGE]
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
    var groupChangedListener: ListenerRegistration!
    var firstMessagesListener: ListenerRegistration!
    
    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImageDictionary: NSMutableDictionary?
    var showAvatars = true
    var firstLoad: Bool?
    
    var isUserDeleted: Bool?
    
    var firstLoadMessages = false
    
    var outgoingBubble: JSQMessagesBubbleImage?
    var incomingBubble: JSQMessagesBubbleImage?
    var activityListener: ListenerRegistration!
    
    var fetchingNow = false
    var firstLoadingFinished = false
    var oldOffset: CGFloat = 0.0
    var oldHeight: CGFloat = 0.0
    
    let gradientLoadingBar = GradientLoadingBar()
    let gradientForMessagesUploads = GradientLoadingBar()
    
    let wavingHand = "👋"
    
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
        collectionView.contentInsetAdjustmentBehavior = .never
        checkForBackgroundImage()
        collectionView.collectionViewLayout = CustomCollectionViewFlowLayout()
        clearRecentCounter(chatRoomId: chatRoomId)
        inputToolbar.contentView.rightBarButtonItem.isEnabled = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(internetConnectionChanged),
                                               name: .internetConnectionState, object: nil)
        view.backgroundColor = .systemBackground
        showTypingIndicator = false
        gradientLoadingBar.gradientColors = [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
        gradientForMessagesUploads.gradientColors = [#colorLiteral(red: 0.2435781095, green: 0.5777899342, blue: 0.5777899342, alpha: 1), #colorLiteral(red: 0.3266429034, green: 0.7572176396, blue: 0.7572176396, alpha: 1), #colorLiteral(red: 0.3785616556, green: 0.8979834621, blue: 0.8979834621, alpha: 1), #colorLiteral(red: 0.4215686275, green: 1, blue: 1, alpha: 1)]
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
        
        registerCustomCells()
        titleLabel.text = initialWithUser ?? ""
        avatarButton.setImage(initialImage == nil ? UIImage() : initialImage, for: .normal)
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
        
        if let isPartOfGrp = isPartOfGroup {
            if isPartOfGrp {
                createTypingObserver()
            }
        } else {
            createTypingObserver()
        }
        
        loadUserDefaults()
        firstLoadMessages = true
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete))
        
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
        customizeInputToolbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // super.viewWillAppear(animated)
        
        if memberIds.count > 1, !MyVariables.globalContactsVariable.contains((memberIds.filter { $0 != FUser.currentId() })[0]) {
            if let isGroup = isGroup {
                if !isGroup { subTitleLabel.text = "Sllick Chat" }
            }
            
        } else {
            checkActivityStatus()
        }
        
        if let viewWithTag = view.viewWithTag(0) {
            viewWithTag.isHidden = false
        }
        
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
        customizeAvatarButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        inputToolbar.contentView.textView.resignFirstResponder()
        recentListener?.remove()
        
        gradientLoadingBar.fadeOut(duration: 0)
        gradientForMessagesUploads.fadeOut(duration: 0)
        if let viewWithTag = view.viewWithTag(0) {
            if userDefaults.object(forKey: kBACKGROUNDIMAGE) != nil {
                view.subviews[0].backgroundColor = .systemBackground
                view.window?.backgroundColor = .systemBackground
                viewWithTag.isHidden = true
            }
        }
        
        activityListener?.remove()
        clearRecentCounter(chatRoomId: chatRoomId)
    }
    
    @objc func internetConnectionChanged() {
        if !MyVariables.internetConnectionState {
            showMessage(kNOINTERNETCONNECTION, type: .warning, options: [.autoHide(false), .hideOnTap(false), .textColor(.label)])
            // self.loadViewIfNeeded()
        } else {
            hideMessage()
            collectionView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        perform(Selector(("jsq_updateCollectionViewInsets")))
        setupChatBubbles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.window?.backgroundColor = .black
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
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
    
    func getAvatarImages() {
        if showAvatars {
            collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
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
    
    func checkActivityStatus() {
        if let isGroup = isGroup {
            if isGroup { return }
        }
        
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
                    if let documentData = document.data() {
                        if !documentData.isEmpty {
                            if (document[kBLOCKEDUSERID] as! [String]).contains(FUser.currentId()) {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                    }
                }
            }
        }
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
            var firstMessageDate: Timestamp?
            var firstMsg = loadedMessages.first![kMESSAGE] as! String
            if let timeStamp = (loadedMessages.first![kACTUALLYSENT] as? Timestamp) {
                firstMessageDate = (loadedMessages.first![kACTUALLYSENT] as? Timestamp)
            } else {
                firstMessageDate = Timestamp()
            }
            
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kACTUALLYSENT, isLessThan: firstMessageDate!).getDocuments { snapshot, _ in
                
                guard let snapshot = snapshot else { return }
                
                var sorted = (dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray).sortedArray(using: [NSSortDescriptor(key: kACTUALLYSENT, ascending: true)]) as! [NSDictionary]
                var pendingMessages: [NSDictionary] = []
                sorted.forEach { dictionary in
                    if dictionary[kSTATUS] as! String == kSENDING {
                        pendingMessages.append(dictionary)
                        let index = sorted.firstIndex(of: dictionary)
                        sorted.remove(at: index!)
                    }
                }
                var x = sorted
                var y = pendingMessages
                pendingMessages.sort { dateFormatter().date(from: $0[kDATE] as! String)! < dateFormatter().date(from: $1[kDATE] as! String)! }
                
                sorted.append(contentsOf: pendingMessages)
                self.loadedMessages = self.removeSuspiciousMessages(allMessages: sorted) + self.loadedMessages
                
                // get the picture messages
                self.getPictureMessages()
                self.maxMessageNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard collectionView.contentOffset.y <= 20 else { return }
        
        oldOffset = collectionView.contentOffset.y
        oldHeight = collectionView.contentSize.height
        if !fetchingNow, firstLoadingFinished {
            if loadedMessagesCount != loadedMessages.count {
                if loadedMessages.count > maxMessageNumber {
                    gradientLoadingBar.fadeIn()
                    fetchingNow = true
                    loadMoreMessages(maxNumer: maxMessageNumber, minNumber: minMessageNumber)
                } else {
                    fetchingNow = false
                }
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
            print(" H E R E ")
            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        
        let oldOffset = collectionView.contentOffset.y
        let oldHeight = collectionView.contentSize.height
        let reverseOffset = oldHeight - oldOffset
        
        collectionView.reloadData()
        
        collectionView.layoutIfNeeded()
        collectionView.contentOffset = CGPoint(x: 0.0, y: collectionView.contentSize.height - reverseOffset)
        
        gradientLoadingBar.fadeOut(duration: 0)
        fetchingNow = false
        loadOld = true
        // showLoadEarlierMessagesHeader = loadedMessagesCount != loadedMessages.count
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
        if userDefaults.object(forKey: kBACKGROUNDIMAGE) != nil {
            collectionView.backgroundColor = .clear
            let width = UIScreen.main.bounds.width
            let height = UIScreen.main.bounds.height
            let imageVIew = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            imageVIew.image = UIImage(named: userDefaults.object(forKey: kBACKGROUNDIMAGE) as! String)!
            imageVIew.contentMode = .scaleAspectFill
            imageVIew.tag = 0
            view.insertSubview(imageVIew, at: 0)
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
                                    self.inputToolbar.contentView.textView.resignFirstResponder()
                                    self.typingListener?.remove()
                                } else {
                                    self.inputToolbar.isHidden = false
                                    self.avatarButton.isUserInteractionEnabled = true
                                    updateExistingRecentWithNewValues(forMembers: self.group![kMEMBERS] as! [String], chatRoomId: self.group![kGROUPID] as! String, withValues: [kAVATAR: self.group![kAVATAR] as Any, kWITHUSERFULLNAME: self.group![kNAME]!])
                                    self.createTypingObserver()
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
