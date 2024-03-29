//
//  BlockedUsersViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 5.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import ProgressHUD
import UIKit
import GradientLoadingBar

class BlockedUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UserTableViewCellDelegate {
    
    @IBOutlet var tableView: UITableView!
    var blockedUsers: [FUser] = []
    @IBOutlet var notificationLabel: UILabel!
    private let gradientLoadingBar = GradientLoadingBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        navigationItem.largeTitleDisplayMode = .never
        loadBlockedUsers()
    }
    
    // MARK: TableView data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notificationLabel.isHidden = blockedUsers.count != 0
        return blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        cell.delegate = self
        cell.selectionStyle = .none
        cell.generateCellWith(fUser: blockedUsers[indexPath.row], indexPath: indexPath)
        return cell
    }
    
    // MARK: TableView delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Unblock"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        var tempBLockedUsers = FUser.currentUser()!.blockedUsers
        let userIdToBlock = blockedUsers[indexPath.row].objectId
        
        tempBLockedUsers.remove(at: tempBLockedUsers.firstIndex(of: userIdToBlock)!)
        blockedUsers.remove(at: indexPath.row)
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID: tempBLockedUsers]) { error in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: Load blocked users
    
    func loadBlockedUsers() {
        if FUser.currentUser()!.blockedUsers.count > 0 {
            self.gradientLoadingBar.gradientColors = [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
            getUsersFromFirestore(withIds: FUser.currentUser()!.blockedUsers) { allBlockedUsers in
                
                ProgressHUD.dismiss()
                self.blockedUsers = allBlockedUsers
                self.gradientLoadingBar.fadeOut()
                self.tableView.reloadData()
            }
        }
    }
    
    // UserTableViewCell delegate
    func didTapAvatarImage(indexPath: IndexPath) {
        return
    }
}
