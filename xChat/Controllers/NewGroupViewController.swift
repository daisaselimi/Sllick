//
//  NewGroupViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 9.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import ImagePicker
import ProgressHUD
import UIKit

class NewGroupViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, GroupMemberCollectionViewCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var editAvatarButtonOutlet: UIButton!
    @IBOutlet var groupIconImageView: UIImageView!
    @IBOutlet var groupSubjectTextField: UITextField!
    @IBOutlet var participantsLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    
    var memberIds: [String] = []
    var allMembers: [FUser] = []
    var groupIcon: UIImage?
    var imageViewGestureRecognizer = UITapGestureRecognizer()
    var viewGestureRecognizer = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        participantsLabel.text = "Participants: \(allMembers.count)"
        imageViewGestureRecognizer.addTarget(self, action: #selector(avatarTapped))
        groupIconImageView.isUserInteractionEnabled = true
        groupIconImageView.image = UIImage(systemName: "camera.circle.fill")
        groupIconImageView.tintColor = .systemYellow
        groupIconImageView.addGestureRecognizer(imageViewGestureRecognizer)
        viewGestureRecognizer.addTarget(self, action: #selector(viewTapped))
        view.addGestureRecognizer(viewGestureRecognizer)
        navigationController?.navigationItem.title = "Create group"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createButtonPressed))
        
        // Do any additional setup after loading the view.
    }
    
    // MARK: CollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMembers.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! GroupMemberCollectionViewCell
        
        cell.delegate = self
        cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
        return cell
    }
    
    // MARK: IBActions
    
    @objc func createButtonPressed(_ sender: Any) {
        if groupSubjectTextField.text != "" {
            memberIds.append(FUser.currentId())
            
            var avatar = ""
            
            if groupIcon != nil {
                let avatarData = groupIcon?.jpegData(compressionQuality: 0.5)!
                avatar = avatarData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            }
            
            let groupId = UUID().uuidString
            
            // create group
            let group = Group(groupId: groupId, subject: groupSubjectTextField.text!, ownerId: FUser.currentId(), members: memberIds, avatar: avatar)
            group.saveGroup()
            
            // create group recent
            startGroupChat(group: group)
            
            // go to chat view
            let chatVC = ChatViewController()
            chatVC.titleName = (group.groupDictionary[kNAME] as! String)
            print(chatVC.titleName!)
            chatVC.memberIds = (group.groupDictionary[kMEMBERS] as! [String])
            chatVC.membersToPush = (group.groupDictionary[kMEMBERS] as! [String])
            chatVC.initialImage = groupIconImageView.image
            chatVC.initialWithUser = groupSubjectTextField.text!
            chatVC.chatRoomId = groupId
            chatVC.isGroup = true
            chatVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(chatVC, animated: true)
            
        } else {
            ProgressHUD.showError("Subject is required")
        }
    }
    
    @objc func viewTapped() {
        view.endEditing(false)
    }
    
    @objc func avatarTapped() {
        showIconOptions()
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        showIconOptions()
    }
    
    // MARK: GroupMemberCollectionViewDelegate
    
    func didClickDeleteButton(indexPath: IndexPath) {
        allMembers.remove(at: indexPath.row)
        memberIds.remove(at: indexPath.row)
        collectionView.reloadData()
        navigationItem.rightBarButtonItems!.first!.isEnabled = allMembers.count > 1
        updateParticipantsLabel()
    }
    
    func didLongPressAvatarImage(indexPath: IndexPath) {}
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: HelperFunctions
    
    func updateParticipantsLabel() {
        participantsLabel.text = "Participants: \(allMembers.count)"
        
        navigationItem.rightBarButtonItem?.isEnabled = allMembers.count > 0
    }
    
    // Mark UIPickerController delegates & code
    
    func showIconOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_: UIAlertAction) in
            self.getImage(fromSourceType: .camera)
        }))
        alert.addAction(UIAlertAction(title: "Photo Album", style: .default, handler: { (_: UIAlertAction) in
            self.getImage(fromSourceType: .photoLibrary)
        }))
        
        if groupIcon != nil || (groupIconImageView.image != nil && (groupIconImageView.image! != UIImage(systemName: "camera.circle.fill"))) {
            let resetAction = UIAlertAction(title: "Reset", style: .destructive) { _ in
                
                self.groupIcon = nil
                self.groupIconImageView.image = UIImage(systemName: "camera.circle.fill")
                self.groupIconImageView.tintColor = .systemYellow
            }
            alert.addAction(resetAction)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        if UIDevice().userInterfaceIdiom == .pad {
            if let currentPopoverpresentioncontroller = alert.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = editAvatarButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = editAvatarButtonOutlet.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                present(alert, animated: true, completion: nil)
            }
        } else {
            present(alert, animated: true, completion: nil)
        }
    }
    
    func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        // Check is source type available
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
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        let chosenImage = selectedImage.resizeTo(MB: 1) // 2
        groupIcon = chosenImage // 4
        //        let screenWidth = UIScreen.main.bounds
        //        print("*** * * * * * * * * *                  * **** ** **---------- * * * * ** * *:::::::::: \(screenWidth.size.width)")
        //        avatarImage = resizeImage(image: avatarImage!, targetSize: CGSize(width: screenWidth.size.width, height: screenWidth.size.width))
        groupIconImageView.image = groupIcon!
        groupIconImageView.maskCircle()
        
        dismiss(animated: true, completion: nil) // 5
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func didTapAvatarImage(indexPath: IndexPath) {}
}
