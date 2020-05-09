//
//  ProfileTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 20.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase

enum ImageType {
    case systemImage
    case bundleImage
}

class ProfileTableViewController: UITableViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var blockUserButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    var userDictionary: [String : Any] = [:]
    var user: FUser?
    var fromGroup = false
    var profilePicture: UIImage!
    var isInContacts: Bool!
    private var observer: NSObjectProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if user == nil {
            user = FUser(_objectId: userDictionary[kOBJECTID] as! String, _pushId: nil, _createdAt: Date(), _updatedAt: Date(), _email: "", _firstname: userDictionary[kFIRSTNAME] as! String, _lastname: userDictionary[kLASTNAME] as! String, _avatar: userDictionary[kAVATAR] as! String, _loginMethod: "", _phoneNumber: "", _city: "", _country: "", _countryCode: "")
            avatarImageView.image = profilePicture
            avatarImageView.maskCircle()
        }
        //        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        //                    self.navigationController?.navigationBar.shadowImage = UIImage()
        //        self.navigationController?.navigationBar.backgroundColor = .systemBackground
        //        self.navigationController?.navigationBar.alpha = 0.9
        
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.separatorColor = .separator
        
        setupUI()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observer = NotificationCenter.default.addObserver(forName: .globalContactsVariable, object: nil, queue: .main) { [weak self] notification in
            if MyVariables.globalContactsVariable.contains(self!.user!.objectId) {
                self!.setBarButton(imageName: "person.badge.minus.fill", imageType: .systemImage, withTintColor: .systemPink)
                self!.activityLabel.isHidden = false
                self!.isInContacts = true
            } else {
                self!.setBarButton(imageName: "person.badge.plus.fill", imageType: .systemImage, withTintColor: .systemGreen)
                self!.activityLabel.isHidden = true
                self!.isInContacts = false
            }
        }
        //         isParOfContacts(user: user!.objectId) { (inContactsList) in
        //                   if inContactsList {
        //                       self.setBarButton(imageName: "person.badge.minus.fill", imageType: .systemImage, withTintColor: .systemPink)
        //                       self.activityLabel.isHidden = false
        //
        //                   } else {
        //                       self.setBarButton(imageName: "person.badge.plus.fill", imageType: .systemImage, withTintColor: .systemGreen)
        //                       self.activityLabel.isHidden = true
        //                   }
        //                      self.checkActivityStatus()
        //               }
        if MyVariables.globalContactsVariable.contains(user!.objectId) {
            self.setBarButton(imageName: "person.badge.minus.fill", imageType: .systemImage, withTintColor: .systemPink)
            self.activityLabel.isHidden = false
            self.isInContacts = true
        } else {
            
            self.setBarButton(imageName: "person.badge.plus.fill", imageType: .systemImage, withTintColor: .systemGreen)
            self.activityLabel.isHidden = true
            self.isInContacts = false
        }
        self.checkActivityStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    //MARK: IBactions
    
    @IBAction func callButtonPressed(_ sender: Any) {
        if checkMicPermission(viewController: self) {
            callUser()
            let currentUser = FUser.currentUser()!
            
            let call = CallClass(_callerId: currentUser.objectId, _withUserId: user!.objectId, _callerFullName: currentUser.fullname, _withUserFullName: user!.fullname)
            call.saveCallInBackground()
        }

        
    }
    
    @IBAction func messageButtonPressed(_ sender: Any) {
        
        let i = navigationController?.viewControllers.firstIndex(of: self)
        if (navigationController?.viewControllers[i!-1] as? ChatViewController) != nil && !fromGroup {
            self.navigationController?.popViewController(animated: true)
            return
        }
        if !checkBlockedStatus(withUser: user!){
            
            let chatVC = ChatViewController()
            chatVC.titleName = user!.firstname
            chatVC.membersToPush = [FUser.currentId(), user!.objectId]
            chatVC.memberIds = [FUser.currentId(), user!.objectId]
            chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: user!)
            chatVC.isGroup = false
            chatVC.initialWithUser = user!.fullname
            chatVC.initialImage = avatarImageView.image!
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
            
        }
        else {
            ProgressHUD.showError("This user is not available for chat")
        }
    }
    
    
    func setBarButton(imageName: String, imageType: ImageType, withTintColor: UIColor?) {
        var image = imageType == .systemImage ? UIImage(systemName: imageName) : UIImage(named: imageName)
        image = image?.withRenderingMode(.alwaysOriginal)
        if let tintColor = withTintColor {
            image = image?.withTintColor(tintColor)
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(togglePresenceInContacts))
    }
    
    @objc func togglePresenceInContacts() {
        if isInContacts {
            removeFromContacts(ofUser: FUser.currentId(), user: user!.objectId)
            
        } else {
            addToContacts(ofUser: FUser.currentId(), user: user!.objectId)
            
        }
    }
    
    func isParOfContacts(user: String, completion: @escaping(Bool) -> ()) {
        reference(.Contact).document(FUser.currentId()).getDocument { (document, error) in
            
            let data = document?.data()
            let contacts = data?["contacts"] as! [String]
            if contacts.contains(user) {
                completion(true)
                self.isInContacts = true
            } else {
                completion(false)
                self.isInContacts = false
            }
        }
    }
    
    func checkActivityStatus() {
        Firestore.firestore().collection("status").whereField("userId", isEqualTo: user?.objectId).addSnapshotListener { (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                let doc = snapshot.documents[0]
                if doc["state"] as! String == "Online" {
                    self.activityLabel.text = "Active now"
                    self.activityLabel.textColor = .systemGreen
                } else {
                    let lastChanged = (doc["last_changed"] as! Timestamp)
                    var timestamp = lastChanged.dateValue().timeIntervalSince1970
                    var date = Date(timeIntervalSince1970: timestamp)
                    
                    self.activityLabel.text = "Active \(date.timeAgoSinceDate())"
                    self.activityLabel.textColor = .secondaryLabel
                }
            }
        }
    }
    
    @IBAction func blockUserPressed(_ sender: Any) {
        let alertController = UIAlertController(title: nil,
                                                message: "Are you sure you want to block them?",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            var currentBlockedIds = FUser.currentUser()!.blockedUsers
            if currentBlockedIds.contains(self.user!.objectId) {
                let index = currentBlockedIds.firstIndex(of: self.user!.objectId)
                currentBlockedIds.remove(at: index!)
            }
            else {
                currentBlockedIds.append(self.user!.objectId)
            }
            updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : currentBlockedIds]) { (error) in
                
                if error != nil {
                    print("error updating user \(error)")
                    return
                }
                
                self.updateBlockStatus()
                blockUser(userToBlock: self.user!)
                self.removeFromContacts(ofUser: FUser.currentId(), user: self.user!.objectId)
                self.removeFromContacts(ofUser: self.user!.objectId, user: FUser.currentId())
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
        alertController.view.tintColor = UIColor(named: "outgoingBubbleColor")
        self.present(alertController, animated: true)
        
    }
    
    
    
    func removeFromContacts(ofUser: String, user: String) {
        //navigationItem.rightBarButtonItems?.first?.isEnabled = false
        reference(.Contact).document(ofUser).getDocument { (document, error) in
            
            if error != nil {
                //self.navigationItem.rightBarButtonItems?.first?.isEnabled = true
                return
            }
            //self.navigationItem.rightBarButtonItems?.first?.isEnabled = true
            let data = document?.data()
            var contacts = data?["contacts"] as! [String]
            if contacts.contains(user) {
                let idx = contacts.firstIndex(of: user)
                contacts.remove(at: idx!)
                reference(.Contact).document(ofUser).updateData(["contacts" : contacts])
                //                self.setBarButton(imageName: "person.badge.plus.fill", imageType: .systemImage, withTintColor: .systemGreen)
                //                self.isInContacts = false
                //                self.activityLabel.isHidden = true
            }
        }
    }
    
    func addToContacts(ofUser: String, user: String) {
        //navigationItem.rightBarButtonItems?.first?.isEnabled = false
        reference(.Contact).document(ofUser).getDocument { (document, error) in
            if error != nil {
                // self.navigationItem.rightBarButtonItems?.first?.isEnabled = true
                return
            }
            
            guard let document = document else { return }
            // self.navigationItem.rightBarButtonItems?.first?.isEnabled = true
            let data = document.data()
            if let data = data {
                var contacts = data["contacts"] as! [String]
                        contacts.append(user)
                        reference(.Contact).document(ofUser).updateData(["contacts" : contacts])
            } else {
                // reference(.Contact).document(ofUser).updateData(["contacts" : [user]])
                reference(.Contact).document(ofUser).setData(["userID" : ofUser, "contacts" : [user]])
            }
        
            //            self.setBarButton(imageName: "person.badge.minus.fill", imageType: .systemImage, withTintColor: .systemPink)
            //            self.isInContacts = true
            //                     self.activityLabel.isHidden = false
        }
    }
    
    //    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        return ""
    //    }
    //
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .secondarySystemGroupedBackground
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 10
    }
    
    
    //MARK: Setup UI
    
    func setupUI() {
        
        if user != nil {
            self.title = "Profile"
            
            fullNameLabel.text = user!.fullname
            activityLabel.text = ""
            updateBlockStatus()
            
            if userDictionary.isEmpty {
                imageFromData(pictureData: user!.avatar) { (avatarImage) in
                    
                    if user!.avatar == "" {
                        self.avatarImageView.image = UIImage(named: "avatarph")
                        avatarImageView.maskCircle()
                    }
                    if avatarImage != nil {
                        self.avatarImageView.image = avatarImage
                        avatarImageView.maskCircle()
                    }
                }
            }
            
            
        }
    }
    
    func updateBlockStatus() {
        
        if user!.objectId != FUser.currentId() {
            blockUserButton.isHidden = false
            messageButton.isHidden = false
            callButton.isHidden = false
        } else {
            blockUserButton.isHidden = true
            messageButton.isHidden = true
            callButton.isHidden = true
        }
        
        if FUser.currentUser()!.blockedUsers.contains(user!.objectId) {
            blockUserButton.setTitle("Ublock user", for: .normal)
        }
        else {
            blockUserButton.setTitle("Block user", for: .normal)
        }
    }
    
    //MARK: Call User
    
    func callClient() -> SINCallClient?{
        let scene = UIApplication.shared.connectedScenes.first
        if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
            return  sd._client.call()
        }
        return nil
    }
    
    func callUser() {
        let userToCall = user!.objectId
        let call = callClient()?.callUser(withId: userToCall)
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CallVC") as! CallViewController
        callVC._call = call
        callVC.callingImage = avatarImageView.image
        callVC.callingName = user!.fullname
        self.present(callVC, animated: true, completion: nil)
    }
}


extension Date {
    
    func timeAgoSinceDate() -> String {
        
        // From Time
        let fromDate = self
        
        // To Time
        let toDate = Date()
        
        // Estimation
        // Year
        if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0  {
            
            return interval == 1 ? "\(interval)" + " " + "year ago" : "\(interval)" + " " + "years ago"
        }
        
        // Month
        if let interval = Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month, interval > 0  {
            
            return interval == 1 ? "\(interval)" + " " + "month ago" : "\(interval)" + " " + "months ago"
        }
        
        // Day
        if let interval = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day, interval > 0  {
            
            return interval == 1 ? "\(interval)" + " " + "day ago" : "\(interval)" + " " + "days ago"
        }
        
        // Hours
        if let interval = Calendar.current.dateComponents([.hour], from: fromDate, to: toDate).hour, interval > 0 {
            
            return interval == 1 ? "\(interval)" + " " + "hour ago" : "\(interval)" + " " + "hours ago"
        }
        
        // Minute
        if let interval = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate).minute, interval > 0 {
            
            return interval == 1 ? "\(interval)" + " " + "minute ago" : "\(interval)" + " " + "minutes ago"
        }
        
        return "just now"
    }
}
