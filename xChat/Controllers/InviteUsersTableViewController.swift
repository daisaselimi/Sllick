//
//  InviteUsersTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 10.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Firebase
import ProgressHUD
import UIKit

class InviteUsersTableViewController: UITableViewController, UserTableViewCellDelegate {
    
    @IBOutlet var headerView: UIView!
    
    var allUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    
    var newMemberIds: [String] = []
    var currentMembersIds: [String] = []
    var group: NSDictionary!
    
    override func viewWillAppear(_ animated: Bool) {
        loadUsers(filter: kCITY)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        tableView.tableFooterView = UIView()
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonPressed))]
        navigationItem.rightBarButtonItem?.isEnabled = false
        currentMembersIds = group[kMEMBERS] as! [String]
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return allUsersGrouped.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let sectionTitle = sectionTitleList[section]
        let users = allUsersGrouped[sectionTitle]
        return users!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        let sectionTitle = sectionTitleList[indexPath.section]
        let users = allUsersGrouped[sectionTitle]
        cell.generateCellWith(fUser: users![indexPath.row], indexPath: indexPath)
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitleList[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionTitleList
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionTitle = sectionTitleList[indexPath.section]
        let users = allUsersGrouped[sectionTitle]
        
        let selectedUser = users![indexPath.row]
        
        if currentMembersIds.contains(selectedUser.objectId) {
            ProgressHUD.showError("Already in the group")
            return
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .checkmark
            }
        }
        
        // add/remove users
        let selected = newMemberIds.contains(selectedUser.objectId)
        
        if selected {
            let objectIndex = newMemberIds.firstIndex(of: selectedUser.objectId)
            newMemberIds.remove(at: objectIndex!)
        } else {
            newMemberIds.append(selectedUser.objectId)
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = newMemberIds.count > 0
    }
    
    // MARK: IBActions
    
    @IBAction func filterSengmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: kCOUNTRY)
        case 2:
            loadUsers(filter: "")
        default:
            return
        }
    }
    
    @objc func doneButtonPressed() {
        updateGroup(group: group)
    }
    
    // MARK: UserTableViewCellDelegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        print("user avatar tapped at: \(indexPath)")
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        let sectionTitle = sectionTitleList[indexPath.section]
        
        let users = allUsersGrouped[sectionTitle]
        
        viewController.user = users![indexPath.row]
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: Helper
    
    func loadUsers(filter: String) {
        ProgressHUD.show()
        
        var query: Query!
        
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.getDocuments { snapshot, error in
            self.allUsers = []
            self.sectionTitleList = []
            self.allUsersGrouped = [:]
            
            if error != nil {
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            
            guard let snapshot = snapshot else { ProgressHUD.dismiss(); return }
            
            if !snapshot.isEmpty {
                for userDictionary in snapshot.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)
                    
                    if fUser.objectId != FUser.currentId(), !fUser.blockedUsers.contains(FUser.currentUser()!.objectId) {
                        self.allUsers.append(fUser)
                    }
                }
                
                self.splitDataIntoSections()
                self.tableView.reloadData()
            }
            
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }
    
    func splitDataIntoSections() {
        var sectionTitle: String = ""
        
        for i in 0..<allUsers.count {
            let currentUser = allUsers[i]
            let firstCharacter = String(currentUser.firstname.first!)
            
            if firstCharacter != sectionTitle {
                sectionTitle = firstCharacter
                allUsersGrouped[sectionTitle] = []
                sectionTitleList.append(sectionTitle)
            }
            
            allUsersGrouped[sectionTitle]?.append(currentUser)
        }
    }
    
    func updateGroup(group: NSDictionary) {
        let tempMembers = currentMembersIds + newMemberIds
        let tempMembersToPush = group[kMEMBERSTOPUSH] as! [String] + newMemberIds
        
        let withValues = [kMEMBERS: tempMembers, kMEMBERSTOPUSH: tempMembersToPush]
        
        Group.updateGroup(groupId: group[kGROUPID] as! String, withValues: withValues)
        
        createRecentsForNewMembers(groupId: group[kGROUPID] as! String, groupName: group[kNAME] as! String, membersToPush: tempMembersToPush, avatar: group[kAVATAR] as! String)
        
        updateExistingRecentWithNewValues(forMembers: group[kMEMBERS] as! [String], chatRoomId: group[kGROUPID] as! String, withValues: withValues)
        
        goToGroupChat(membersToPush: tempMembersToPush, members: tempMembers)
    }
    
    func goToGroupChat(membersToPush: [String], members: [String]) {
        let chatVC = ChatViewController()
        chatVC.titleName = (group[kNAME] as! String)
        chatVC.memberIds = members
        chatVC.membersToPush = membersToPush
        
        chatVC.chatRoomId = (group[kGROUPID] as! String)
        chatVC.isGroup = true
        chatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatVC, animated: true)
    }
}
