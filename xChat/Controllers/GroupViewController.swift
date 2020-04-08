//
//  GroupViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 10.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD
import AMPopTip
import FirebaseFirestore

protocol GroupDelegate {
    func updatedGroupMembers(group: NSDictionary)
}

class GroupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, GroupMemberCollectionViewCellDelegate, UIScrollViewDelegate {

    @IBOutlet weak var cameraButtonOutlet: UIImageView!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var editButtonOutlet: UIButton!
    @IBOutlet weak var groupMembersCollectionView: UICollectionView!
    
    var tapGestureRecognizer = UITapGestureRecognizer()
    
    var delegate: GroupDelegate?
    
    var group: NSDictionary!
    var groupIcon: UIImage?
    var allMembers: [FUser] = []
    var allMembersToPush: [String] = []
    var firstLoad = false
    var groupChangedListener: ListenerRegistration!
    
    override func viewDidLoad() {
        
        firstLoad = true
        super.viewDidLoad()
        setupUI()
        allMembersToPush = group[kMEMBERSTOPUSH] as! [String]
        groupMembersCollectionView.delegate = self
        groupMembersCollectionView.dataSource = self
        tapGestureRecognizer.addTarget(self, action: #selector(avatarImageTap))
        cameraButtonOutlet.addGestureRecognizer(tapGestureRecognizer)
        ProgressHUD.show()
        
        getGroupMembers(completion: { (users) in
            self.allMembers = users
            if !users.isEmpty {
                let popTip = PopTip()
                popTip.show(text: "Long press members' pictures to delete", direction: .none, maxWidth: 200, in: self.view, from: self.groupMembersCollectionView.frame, duration: 10)
                popTip.entranceAnimation = .scale
                popTip.actionAnimation = .bounce(5)
                popTip.bubbleColor = .systemTeal
                popTip.textColor = .systemBackground
                popTip.cornerRadius = 10
                popTip.shouldDismissOnTap = true
            }else {
                self.groupMembersCollectionView.setEmptyMessage("No members to show")
            }
            self.groupMembersCollectionView.reloadData() {
                ProgressHUD.dismiss()
                print("xxxxxx")
            }
        })
        cameraButtonOutlet.isUserInteractionEnabled = true
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Invite users", style: .plain, target: self, action: #selector(self.inviteUsers))]
        self.navigationItem.largeTitleDisplayMode = .always
        // Do any additional setup after loading the view.
        
        self.groupChangedListener = reference(.Group).whereField(kGROUPID, isEqualTo : self.group![kGROUPID] as! String).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                snapshot.documentChanges.forEach { (diff) in
                    
                    if diff.type == .modified {
                        self.group = diff.document.data() as NSDictionary
                        if !(self.group![kMEMBERS] as! [String]).contains(FUser.currentId()) {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        
                    }
                }
            }
        })
    }
    

    override func viewDidDisappear(_ animated: Bool) {
        groupChangedListener.remove()
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
        if allMembers.count == 0 {
            groupMembersCollectionView.setEmptyMessage("No members to show")
        } else {
            groupMembersCollectionView.restore()
        }
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
    
    //MARK: GroupCell delegate
    func didClickDeleteButton(indexPath: IndexPath) {
        
        if allMembersToPush.contains(allMembers[indexPath.row].objectId) {
            print(allMembers[indexPath.row].fullname)
            let index = allMembersToPush.firstIndex(of: allMembers[indexPath.row].objectId)
            allMembersToPush.remove(at: index!)
        }
        
        pendingToDelete.remove(allMembers[indexPath.row].objectId)
        let removedId = allMembers[indexPath.row].objectId
        allMembers.remove(at: indexPath.row)
        
        var members = allMembers.map { $0.objectId }
        members.append(FUser.currentId())
        Group.updateGroup(groupId: group![kGROUPID] as! String, withValues: [kMEMBERS : members, kMEMBERSTOPUSH : allMembersToPush])
        Group.getGroup(groupId: group![kGROUPID] as! String) { (updatedGroup) in
            self.delegate?.updatedGroupMembers(group: updatedGroup)
        }
        
        updateExistingRecentWithNewValues(forMembers: [removedId], chatRoomId: group![kGROUPID] as! String, withValues: [kMEMBERS : members, kMEMBERSTOPUSH : allMembersToPush])
        
        self.groupMembersCollectionView.reloadData()
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
            let group1 = NSMutableDictionary.init(dictionary: group)
                  group1.setValue(groupNameTextField.text! as Any, forKey: kNAME)
                  group1.setValue(avatarString! as Any, forKey: kAVATAR)
                  group = group1
            previousViewController.group = group
            self.navigationController?.popViewController(animated: true) {
                previousViewController.setUIForGroupChat()
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
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

extension UICollectionView {
    func reloadData(_ completion: @escaping () -> Void) {
        reloadData()
        DispatchQueue.main.async { completion() }
    }
}

