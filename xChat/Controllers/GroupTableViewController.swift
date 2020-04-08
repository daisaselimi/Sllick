//
//  GroupTableViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 1.12.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD
import AMPopTip
import FirebaseFirestore

class GroupTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, GroupMemberCollectionViewCellDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var cameraButtonOutlet: UIImageView!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var editButtonOutlet: UIButton!
    @IBOutlet weak var groupMembersCollectionView: UICollectionView!
    @IBOutlet weak var saveButtonOutlet: MyButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var muteGroupButton: UIButton!
    
    var tapGestureRecognizer = UITapGestureRecognizer()
    
    var removeKeyboardGestureRecognizer = UITapGestureRecognizer()
    
    var delegate: GroupDelegate?
    
    var group: NSDictionary!
    var groupIcon: UIImage?
    var allMembers: [FUser] = []
    var allMembersToPush: [String] = []
    var firstLoad = false
    var groupChangedListener: ListenerRegistration?
    var muted = false
    
    override func viewDidLoad() {
        firstLoad = true
   
        super.viewDidLoad()
     activityIndicator.isHidden = false
          activityIndicator.hidesWhenStopped = true
          activityIndicator.startAnimating()
        setupUI()
        allMembersToPush = group[kMEMBERSTOPUSH] as! [String]
        muted = !(group[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId())
        muteGroupButton.setTitle(muted ? "Unmute Group" : "Mute Group", for: .normal)
        saveButtonOutlet.backgroundColor = UIColor.getAppColor(.light)
        groupMembersCollectionView.delegate = self
        groupMembersCollectionView.dataSource = self
        tapGestureRecognizer.addTarget(self, action: #selector(avatarImageTap))
        removeKeyboardGestureRecognizer.addTarget(self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(removeKeyboardGestureRecognizer)
        cameraButtonOutlet.addGestureRecognizer(tapGestureRecognizer)
        ProgressHUD.show()
        
        getGroupMembers(completion: { (users) in
            self.allMembers = users
            let showedGroupTips = userDefaults.bool(forKey: kSHOWEDGROUPTIPS)
            print(showedGroupTips)
            if !users.isEmpty {
                if !showedGroupTips {
                    let popTip = PopTip()
                              
                              popTip.show(text: "Long press members' pictures to delete", direction: .none, maxWidth: 200, in: self.view, from: self.view.frame, duration: 10)
                              
                              popTip.entranceAnimation = .scale
                              popTip.actionAnimation = .bounce(5)
                              popTip.bubbleColor = .systemTeal
                              popTip.textColor = .systemBackground
                              popTip.cornerRadius = 10
                              popTip.shouldDismissOnTap = true
                     userDefaults.set(true, forKey: kSHOWEDGROUPTIPS)
                }
          
            }else {
                self.groupMembersCollectionView.setEmptyMessage("No members to show")
            }
            self.groupMembersCollectionView.reloadData() {
                ProgressHUD.dismiss()
                if let activityIndic = self.activityIndicator {
                    activityIndic.stopAnimating()
                }
           
                print("xxxxxx")
            }
        })
        cameraButtonOutlet.isUserInteractionEnabled = true
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Invite users", style: .plain, target: self, action: #selector(self.inviteUsers))]
        self.navigationItem.largeTitleDisplayMode = .never
     
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        

        registerGroupListener()
    }
    
    func registerGroupListener() {
        
              self.groupChangedListener = reference(.Group).whereField(kGROUPID, isEqualTo : self.group![kGROUPID] as! String).addSnapshotListener({ (snapshot, error) in
                  
                  guard let snapshot = snapshot else { return }
                  
                  if !snapshot.isEmpty {
                      snapshot.documentChanges.forEach { (diff) in
                        if diff.type == .modified {
                            
                            self.group = diff.document.data() as NSDictionary
                            self.getGroupMembers { (users) in
                                self.allMembers = users
                                self.groupMembersCollectionView.reloadData()
                            }
//                            self.groupNameTextField.text = (self.group[kNAME] as! String)
//                            if self.group[kAVATAR] as! String == "" {
//                                self.cameraButtonOutlet.image =  UIImage(named: "groupph")
//                                self.groupIcon = nil
//                            } else {
//                                imageFromData(pictureData: self.group[kAVATAR] as! String) { (image) in
//                                    self.cameraButtonOutlet.image = image!
//                                    self.groupIcon = image!
//                                }
//                                
//                            }
                         
                            if !(self.group![kMEMBERS] as! [String]).contains(FUser.currentId()) {
                                self.navigationController?.popViewController(animated: true)
                            }
                            
                        }
                      }
                  }
              })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        groupChangedListener?.remove()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 2 {
            return 2
        }
        return 1
    }
    


    
    
    override func viewWillAppear(_ animated: Bool) {
  
        pendingToDelete.removeAll()
        if !firstLoad {
            groupMembersCollectionView.reloadData()
            self.navigationItem.rightBarButtonItems?.first?.isEnabled = false
            ProgressHUD.show()
            Group.getGroup(groupId: group[kGROUPID]! as! String, completion: { updatedGroup in
                self.group = updatedGroup
                self.navigationItem.rightBarButtonItems?.first?.isEnabled = true
                
                self.getGroupMembers(completion: { (users) in
                    if !users.isEmpty{
                        self.groupMembersCollectionView.restore()
                        self.allMembers = []
                        self.allMembersToPush = self.group[kMEMBERSTOPUSH] as! [String]
                        self.allMembers = users
                        self.groupMembersCollectionView.reloadData() {
                            ProgressHUD.dismiss()
                        }
                    } else {
                        self.groupMembersCollectionView.setEmptyMessage("No members to show")
                    }
                    
                })
            })
            
        } else {
            firstLoad = false
        }
    }
    
    
    
    //MARK: Collection view DataSource, delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
     
        return allMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! GroupMemberCollectionViewCell
        
        cell.delegate = self
        cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
        if pendingToDelete.contains(allMembers[indexPath.row].objectId) {
            cell.deleteButtonOutlet.isHidden = false
            cell.shakeDeletingCell()
        } else {
            cell.deleteButtonOutlet.isHidden = true
            cell.stopShaking()
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let totalCellWidth = 87 * collectionView.numberOfItems(inSection: section)
        let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: section) - 1)
        
        let leftInset = max(0.0, (self.groupMembersCollectionView.frame.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2)
        let rightInset = leftInset
        
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
    }
    
    
    //MARK: GroupCell delegate
    func didClickDeleteButton(indexPath: IndexPath) {
        
        allMembersToPush = group[kMEMBERSTOPUSH] as! [String]
        if allMembersToPush.contains(allMembers[indexPath.row].objectId) {
            print(allMembers[indexPath.row].fullname)
            let index = allMembersToPush.firstIndex(of: allMembers[indexPath.row].objectId)
            allMembersToPush.remove(at: index!)
        }
        
        pendingToDelete.remove(allMembers[indexPath.row].objectId)
        let removedId = allMembers[indexPath.row].objectId
        allMembers.remove(at: indexPath.row)
        if allMembers.count == 0 {
               self.groupMembersCollectionView.setEmptyMessage("No members to show")
        } else {
            self.groupMembersCollectionView.restore()
        }
        
        var members = allMembers.map { $0.objectId }
        members.append(FUser.currentId())
        Group.updateGroup(groupId: group![kGROUPID] as! String, withValues: [kMEMBERS : members, kMEMBERSTOPUSH : allMembersToPush])
        Group.getGroup(groupId: group![kGROUPID] as! String) { (updatedGroup) in
            self.delegate?.updatedGroupMembers(group: updatedGroup)
        }
       
        self.groupMembersCollectionView.reloadData()
          updateExistingRecentWithNewValues(forMembers: [removedId], chatRoomId: group![kGROUPID] as! String, withValues: [kMEMBERS : members, kMEMBERSTOPUSH : allMembersToPush])
    }
    
    var pendingToDelete: Set<String> = []
    
    func didLongPressAvatarImage(indexPath: IndexPath) {
        pendingToDelete.insert(allMembers[indexPath.row].objectId)
        let cell = groupMembersCollectionView.cellForItem(at: indexPath) as! GroupMemberCollectionViewCell
        cell.deleteButtonOutlet.isHidden = false
        cell.shakeDeletingCell()
    }
    
    func didTapAvatarImage(indexPath: IndexPath) {
        print(pendingToDelete)
        if pendingToDelete.contains(allMembers[indexPath.row].objectId){
            pendingToDelete.remove(allMembers[indexPath.row].objectId)
            print(pendingToDelete)
        }
        let cell = groupMembersCollectionView.cellForItem(at: indexPath) as! GroupMemberCollectionViewCell
        cell.stopShaking()
        cell.deleteButtonOutlet.isHidden = true
    }
    
    
    func getGroupMembers(completion: @escaping ([FUser]) -> Void) {
        
        getUsersFromFirestore(withIds: group[kMEMBERS] as! [String]){ (users) in
            completion(users.sorted(by: { $0.firstname < $1.firstname }))
            self.delegate?.updatedGroupMembers(group: self.group!)
        }
    }
    
    //MARK: IBOutlets
    
    @objc func avatarImageTap() {
        showIconOptions()
    }
    
    @objc func viewTapped() {
        self.view.endEditing(false)
        if(!pendingToDelete.isEmpty){
            pendingToDelete.removeAll()
            groupMembersCollectionView.reloadData()
        }
    }
    
    @objc func inviteUsers() {
        //
        //        let contactsVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "contactsView") as! ContactsTableViewController
        //            contactsVC.isGroup = false
        //            self.navigationController?.pushViewController(contactsVC, animated: true)
        
        
        //        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inviteUsersView") as! InviteUsersTableViewController
        //        userVC.group = group
        ////
        ////        let i = navigationController?.viewControllers.firstIndex(of: self)
        ////        let previousViewController = navigationController?.viewControllers[i!-1] as! ChatViewController
        //        self.navigationController?.pushViewController(userVC, animated: true)
        ProgressHUD.show()
        let contactsVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "contactsView") as! ContactsTableViewController
        contactsVC.isGroup = true
        contactsVC.title = "Invite from contacts"
        contactsVC.isInviting = true
        Group.getGroup(groupId: group[kGROUPID] as! String, completion: { (tgroup) in
            contactsVC.group = tgroup
            
            self.navigationController?.pushViewController(contactsVC, animated: true)
            ProgressHUD.dismiss()
        })
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        showIconOptions()
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        var withValues: [String : Any]!
        
        if groupNameTextField.text != "" {
            withValues = [kNAME : groupNameTextField.text!]
        } else {
            ProgressHUD.showError("Subject is required")
        }
        
        
        
        let avatarData = cameraButtonOutlet.image!.jpegData(compressionQuality: 0.5)
        
        var avatarString = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        if groupIcon == nil {
            avatarString = ""
        }
        
        withValues = [kNAME : groupNameTextField.text!, kAVATAR : avatarString!]
        
        Group.updateGroup(groupId: group![kGROUPID] as! String, withValues: withValues)
        
        withValues = [kWITHUSERFULLNAME : groupNameTextField.text!, kAVATAR : avatarString!]
        
        updateExistingRecentWithNewValues(forMembers: group[kMEMBERS] as! [String], chatRoomId: group[kGROUPID] as! String, withValues: withValues)
        
        
        
        let i = navigationController?.viewControllers.firstIndex(of: self)
        
        
        if let previousViewController = navigationController?.viewControllers[i!-1] as? ChatViewController {
            //let group1 = NSMutableDictionary.init(dictionary: group)
//            group1.setValue(groupNameTextField.text! as Any, forKey: kNAME)
//            group1.setValue(avatarString! as Any, forKey: kAVATAR)
//            group = group1
//            previousViewController.group = group
            Group.getGroup(groupId: group![kGROUPID] as! String) { (grp) in
                self.delegate?.updatedGroupMembers(group: grp)
                self.navigationController?.popViewController(animated: true) {
                    previousViewController.setUIForGroupChat()
                }
            }
         
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func muteGroupPressed(_ sender: Any) {
        
        var membersToPush = group[kMEMBERSTOPUSH] as! [String]
        
        if !muted {
            membersToPush = membersToPush.filter { $0 != FUser.currentId() }
            muteGroupButton.setTitle("Unmute Group", for: .normal)
            muted = true
        } else {
            membersToPush.append(FUser.currentId())
            muteGroupButton.setTitle("Mute Group", for: .normal)
            muted = false
        }

        Group.updateGroup(groupId:group[kGROUPID] as! String, withValues: [kMEMBERSTOPUSH : membersToPush])
        updateExistingRecentWithNewValues(forMembers: [FUser.currentId()], chatRoomId: group[kGROUPID] as! String, withValues: [kMEMBERSTOPUSH : membersToPush])
    }
    
    @IBAction func leaveGroupPressed(_ sender: Any) {
        
        let members = (group![kMEMBERS] as! [String]).filter { $0 != FUser.currentId() }
        let membersToPush =  (group![kMEMBERSTOPUSH] as! [String]).filter { $0 != FUser.currentId() }
        Group.updateGroup(groupId: group![kGROUPID] as! String, withValues: [kMEMBERS : members, kMEMBERSTOPUSH : membersToPush])
        updateExistingRecentWithNewValues(forMembers: [FUser.currentId()], chatRoomId: group![kGROUPID] as! String, withValues: [kMEMBERS : members, kMEMBERSTOPUSH : allMembersToPush])
        self.navigationController?.popToRootViewController(animated: true)
    
    }
    
    //MARK: Helpers
    
    func setupUI() {
        self.title = "Group"
        groupNameTextField.text = (group[kNAME] as! String)
        imageFromData(pictureData: group[kAVATAR] as! String) { (avatarImage) in
            
            if avatarImage != nil {
                
                self.cameraButtonOutlet.image = avatarImage
                self.groupIcon = avatarImage
                self.cameraButtonOutlet.maskCircle()
            } else {
                self.cameraButtonOutlet.image = UIImage(named: "groupph")
                self.cameraButtonOutlet.maskCircle()
            }
        }
    }
    
    func showIconOptions() {
        
        let alert = UIAlertController(title: nil, message: "Change group photo", preferredStyle: .actionSheet)
        
        if groupIcon != nil {
            
            let resetAction = UIAlertAction(title: "Remove Current Photo", style: .destructive) { (alert) in
                
                self.groupIcon = nil
                self.cameraButtonOutlet.image = UIImage(named: "groupph")
                self.cameraButtonOutlet.tintColor = .systemYellow
            }
            alert.addAction(resetAction)
        }
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {(action: UIAlertAction) in
            self.getImage(fromSourceType: .camera)
        }))
        alert.addAction(UIAlertAction(title: "Choose From Library", style: .default, handler: {(action: UIAlertAction) in
            self.getImage(fromSourceType: .photoLibrary)
        }))
        
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.view.tintColor = UIColor.getAppColor(.light)
        if ( UIDevice().userInterfaceIdiom == .pad ) {
            if let currentPopoverpresentioncontroller = alert.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = editButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = editButtonOutlet.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        
        //Check is source type available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = false
            imagePickerController.sourceType = sourceType
            present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    // UIImagePicker delegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        let chosenImage = selectedImage.resizeTo(MB: 1) //2
        groupIcon = chosenImage //4
        //        let screenWidth = UIScreen.main.bounds
        //        print("*** * * * * * * * * *                  * **** ** **---------- * * * * ** * *:::::::::: \(screenWidth.size.width)")
        //        avatarImage = resizeImage(image: avatarImage!, targetSize: CGSize(width: screenWidth.size.width, height: screenWidth.size.width))
        self.cameraButtonOutlet.image = self.groupIcon!
        self.cameraButtonOutlet.maskCircle()
        
        dismiss(animated:true, completion: nil) //5
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

//extension UICollectionView {
//    func reloadData(_ completion: @escaping () -> Void) {
//        reloadData()
//        DispatchQueue.main.async { completion() }
//    }
//}

