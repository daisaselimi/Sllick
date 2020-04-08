//
//  ProfileTableViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 20.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD

class ProfileTableViewController: UITableViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var blockUserButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    
    var user: FUser?
    var fromGroup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView.backgroundColor = .systemGroupedBackground
        callButton.tintColor = UIColor.getAppColor(.light)
        messageButton.tintColor = UIColor.getAppColor(.light)
        tableView.separatorColor = .separator
        setupUI()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        callUser()
        let currentUser = FUser.currentUser()!
        
        let call = CallClass(_callerId: currentUser.objectId, _withUserId: user!.objectId, _callerFullName: currentUser.fullname, _withUserFullName: user!.fullname)
        call.saveCallInBackground()
        
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
    
    @IBAction func blockUserPressed(_ sender: Any) {
        var currentBlockedIds = FUser.currentUser()!.blockedUsers
        if currentBlockedIds.contains(user!.objectId) {
            let index = currentBlockedIds.firstIndex(of: user!.objectId)
            currentBlockedIds.remove(at: index!)
        }
        else {
            currentBlockedIds.append(user!.objectId)
        }
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : currentBlockedIds]) { (error) in
            
            if error != nil {
                print("error updating user \(error)")
                return
            }
            
            self.updateBlockStatus()
        }
        
        blockUser(userToBlock: user!)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
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
            phoneNumberLabel.text = user!.phoneNumber
            
            updateBlockStatus()
            
            
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
        self.present(callVC, animated: true, completion: nil)
    }
}
