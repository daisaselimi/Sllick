//
//  ContactsTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 6.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Contacts
import DZNEmptyDataSet
import FirebaseFirestore
import ProgressHUD
import UIKit

class ContactsTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate, UsersDelegate {
    
    var users: [FUser] = []
    var matchedUsers: [FUser] = []
    var filteredMatchedUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    var isSyncing: Bool = false
    var firstLoad: Bool = false
    var workItem: DispatchWorkItem?
    var emptySetDescription: String = ""
    
    // for inviting users in group
    var isInviting = false
    var group: NSDictionary?
    var currentMembersIds: [String] = []
    var newMemberIds: [String] = []
    
    var isGroup = false
    var memberIdsOfGroupChat: [String] = []
    var membersOfGroupChat: [FUser] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var selectedUser: [String] = []
    
    lazy var contacts: [CNContact] = {
        let contactStore = CNContactStore()
        
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey,
            ] as [Any]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        return results
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        if isSyncing {
            ProgressHUD.show("Syncing contacts...")
            tableView.isUserInteractionEnabled = false
            navigationItem.rightBarButtonItems?.last?.isEnabled = false
            return
        }
        //        if !firstLoad {
        //            reloadContacts()
        //        } else {
        //            firstLoad = false
        //        }
        
        // to remove empty cell lines
        tableView.tableFooterView = UIView()
    }
    
    func didAddNewContacts() {
        reloadContacts()
    }
    
    func reloadContacts() {
        print("yessss")
        matchedUsers.removeAll()
        users.removeAll()
        sectionTitleList = []
        allUsersGrouped = [:]
        sectionTitleList = []
        filteredMatchedUsers = []
        tableView.isUserInteractionEnabled = false
        if !(isGroup || isInviting) {
            navigationItem.rightBarButtonItems?.last?.isEnabled = false
        }
        loadAddedUsers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //        DispatchQueue.main.async {
        //            self.workItem?.cancel()
        //        }
        
        ProgressHUD.dismiss()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.backItem?.title = ""
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        setupButtons()
        firstLoad = true
        currentMembersIds = isInviting ? group![kMEMBERSTOPUSH] as! [String] : [String]()
        loadAddedUsers()
    }
    
    override func viewWillLayoutSubviews() {
        tableView.separatorStyle = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {}
    
    // MARK: TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive, searchController.searchBar.text != "" {
            return 1
        } else {
            return allUsersGrouped.count
        }
    }
    
    func checkForNoData() {
        if matchedUsers.count == 0 {
            if !isGroup {
                // tableView.setEmptyMessage("No contacts to show. Tap sync button to start syncing your contacts")
            } else {
                // tableView.setEmptyMessage("No contacts to show")
            }
        } else {
            // tableView.restore()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= sectionTitleList.count {
            return 0
        }
        if searchController.isActive, searchController.searchBar.text != "" {
            return filteredMatchedUsers.count
        } else {
            // find section title
            let sectionTitle = sectionTitleList[section]
            
            // find users for given section title
            let users = allUsersGrouped[sectionTitle]
            
            // return count for users
            return users!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UserTableViewCell
        cell.accessoryType = .none
        var user: FUser
        
        if searchController.isActive, searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            let sectionTitle = sectionTitleList[indexPath.section]
            // get all users of the section
            let users = allUsersGrouped[sectionTitle]
            
            user = users![indexPath.row]
        }
        
        if selectedUser.contains(user.objectId) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        cell.delegate = self
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive, searchController.searchBar.text != "" {
            return ""
        } else {
            return section >= sectionTitleList.count ? "" : sectionTitleList[section]
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .systemBackground
        
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        
        header.textLabel?.textColor = .label
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive, searchController.searchBar.text != "" {
            return nil
        } else {
            return nil // self.sectionTitleList
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    // MARK: TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionTitle = sectionTitleList[indexPath.section]
        let userToChat: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            userToChat = filteredMatchedUsers[indexPath.row]
        } else {
            let users = allUsersGrouped[sectionTitle]
            userToChat = users![indexPath.row]
        }
        
        // for inviting
        if isInviting && currentMembersIds.contains(userToChat.objectId) {
            if currentMembersIds.contains(userToChat.objectId) {
                let cell = tableView.cellForRow(at: indexPath)
                cell!.shake()
            } else {
                memberIdsOfGroupChat.append(userToChat.objectId)
                navigationItem.rightBarButtonItem?.isEnabled = memberIdsOfGroupChat.count > 0
            }
            return
        }
        
        if isGroup || isInviting {
            if let cell = tableView.cellForRow(at: indexPath) {
                if selectedUser.contains(userToChat.objectId) {
                    cell.accessoryType = .none
                    let index = selectedUser.firstIndex(of: userToChat.objectId)
                    selectedUser.remove(at: index!)
                } else {
                    cell.accessoryType = .checkmark
                    selectedUser.append(userToChat.objectId)
                }
            }
        }
        
        if !isGroup {
            if !checkBlockedStatus(withUser: userToChat) {
                let chatVC = ChatViewController()
                chatVC.titleName = userToChat.firstname
                chatVC.memberIds = [FUser.currentId(), userToChat.objectId]
                chatVC.membersToPush = [FUser.currentId(), userToChat.objectId]
                chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
                chatVC.isGroup = false
                chatVC.initialWithUser = userToChat.fullname
                let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
                chatVC.initialImage = cell.avatarImage!.image
                chatVC.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(chatVC, animated: true)
            } else {
                ProgressHUD.showError("This user is not available for chat")
            }
        } else {
            // add/remove user from array
            let selected = memberIdsOfGroupChat.contains(userToChat.objectId)
            
            if selected {
                let objectIndex = memberIdsOfGroupChat.firstIndex(of: userToChat.objectId)
                memberIdsOfGroupChat.remove(at: objectIndex!)
                membersOfGroupChat.remove(at: objectIndex!)
            } else {
                memberIdsOfGroupChat.append(userToChat.objectId)
                membersOfGroupChat.append(userToChat)
            }
            
            navigationItem.rightBarButtonItem?.isEnabled = memberIdsOfGroupChat.count > 0
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) ->
        UISwipeActionsConfiguration? {
            var contactUser: FUser
            
            if searchController.isActive, searchController.searchBar.text != "" {
                contactUser = filteredMatchedUsers[indexPath.row]
            } else {
                contactUser = matchedUsers[indexPath.row]
            }
            
            let removeContact = UIContextualAction(style: .normal, title: nil) { _, _, _ in
                if self.searchController.isActive, self.searchController.searchBar.text != "" {
                    self.filteredMatchedUsers.remove(at: indexPath.row)
                    let objectId = contactUser.objectId
                    self.removeContact(id: objectId)
                    let contactFirstLetter = contactUser.firstname.first?.uppercased()
                    if self.allUsersGrouped[contactFirstLetter!]?.count == 1 {
                        self.sectionTitleList.removeAll { (letter) -> Bool in
                            letter == contactFirstLetter!
                        }
                    }
                    self.allUsersGrouped[contactFirstLetter!] = self.removeFromArray(array: self.allUsersGrouped[contactFirstLetter!]!, withId: objectId)
                    self.matchedUsers = self.removeFromArray(array: self.matchedUsers, withId: objectId)
                    if self.memberIdsOfGroupChat.contains(objectId) {
                        let index = self.memberIdsOfGroupChat.firstIndex(of: objectId)
                        self.memberIdsOfGroupChat.remove(at: index!)
                        self.membersOfGroupChat.remove(at: index!)
                        self.navigationItem.rightBarButtonItem?.isEnabled = self.memberIdsOfGroupChat.count > 0
                    }
                    
                    self.splitDataInToSection()
                } else {
                    let sectionTitle = self.sectionTitleList[indexPath.section]
                    let users = self.allUsersGrouped[sectionTitle]
                    let objectId = users![indexPath.row].objectId
                    self.removeContact(id: users![indexPath.row].objectId)
                    if self.allUsersGrouped[sectionTitle]?.count == 1 {
                        self.sectionTitleList.remove(at: indexPath.section)
                    }
                    self.allUsersGrouped[sectionTitle] = self.removeFromArray(array: self.allUsersGrouped[sectionTitle]!, withId: objectId)
                    self.matchedUsers = self.removeFromArray(array: self.matchedUsers, withId: objectId)
                    if self.memberIdsOfGroupChat.contains(objectId) {
                        let index = self.memberIdsOfGroupChat.firstIndex(of: objectId)
                        self.memberIdsOfGroupChat.remove(at: index!)
                        self.membersOfGroupChat.remove(at: index!)
                        self.navigationItem.rightBarButtonItem?.isEnabled = self.memberIdsOfGroupChat.count > 0
                    }
                    self.splitDataInToSection()
                }
            }
            
            removeContact.backgroundColor = UIColor.systemBackground
            var img = UIGraphicsImageRenderer(size: CGSize(width: 26, height: 25)).image {
                _ in
                UIImage(systemName: "person.badge.minus")?.draw(in: CGRect(x: 0, y: 0, width: 26, height: 25))
            }
            img = img.imageWithColor(color1: .systemRed)
            removeContact.image = img
            return UISwipeActionsConfiguration(actions: [removeContact])
    }
    
    func removeFromArray(array: [FUser], withId: String) -> [FUser] {
        var tempArr = array
        tempArr.removeAll(where: { (user) -> Bool in
            user.objectId == withId
        })
        return tempArr
    }
    
    func removeContact(id: String) {
        let arr = matchedUsers.filter { $0.objectId != id }
        let dict = ["userID": FUser.currentId(), "contacts": arr.map { $0.objectId }] as [String: Any]
        reference(.Contact).document(FUser.currentId()).setData(dict) { error in
            if error != nil {
                ProgressHUD.showError("COULD NOT DELETE")
            } else {
                ProgressHUD.showSuccess()
            }
        }
    }
    
    func compareUsers() {
        for user in users {
            if user.phoneNumber != "" {
                let contact = searchForContactUsingPhoneNumber(phoneNumber: user.phoneNumber)
                
                // if we have a match, we add to our array to display them
                if contact.count > 0 {
                    matchedUsers.append(user)
                }
            }
        }
        
        //        updateInformationLabel()
        matchedUsers.mergeElements(newElements: currentContacts!)
        matchedUsers = matchedUsers.sorted { $0.fullname < $1.fullname }
        print("MMMMAAACHHEHEDDDDDD: \(matchedUsers.count)")
        
        let dict = ["userID": FUser.currentId(), "contacts": matchedUsers.map { $0.objectId }] as [String: Any]
        
        reference(.Contact).document(FUser.currentId()).setData(dict) { error in
            if error != nil {
                ProgressHUD.showError("Couldnt save contacts")
            }
            self.tableView.isUserInteractionEnabled = true
            self.navigationItem.rightBarButtonItems?.last?.isEnabled = true
            self.isSyncing = false
            ProgressHUD.dismiss()
        }
    }
    
    // MARK: IBActions
    
    @objc func inviteButtonPressed() {
        let text = "Hey! Let's chat on Sllick: \(kAPPURL)"
        
        let objectsToShare: [Any] = [text]
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        
        // for iPad
        activityViewController.popoverPresentationController?.sourceView = view
        
        activityViewController.setValue("Let's chat on Sllick", forKey: "subject")
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func searchNearByButtonPressed() {
        let userVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "usersTableView") as! UsersTableViewController
        userVC.delegate = self
        navigationController?.pushViewController(userVC, animated: true)
    }
    
    @objc func syncButtonPressed() {
        loadUsers()
    }
    
    @objc func nextButtonPressed() {
        let newGroupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "newGroupView") as! NewGroupViewController
        
        newGroupVC.memberIds = memberIdsOfGroupChat
        newGroupVC.allMembers = membersOfGroupChat
        navigationController?.pushViewController(newGroupVC, animated: true)
    }
    
    @objc func doneButtonPressed() {
        updateGroup(group: group!)
    }
    
    var currentContacts: [FUser]?
    
    // MARK: Load users
    
    func loadUsers() {
        checkContactsAccess(viewController: self) {
            authorizationStatus in
            
            if authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    self.tableView.isUserInteractionEnabled = false
                    self.navigationItem.rightBarButtonItems?.last?.isEnabled = false
                    self.isSyncing = true
                    ProgressHUD.show("Syncing contacts...")
                    reference(.User).order(by: kFIRSTNAME, descending: false).getDocuments { snapshot, _ in
                        
                        guard let snapshot = snapshot else {
                            ProgressHUD.dismiss()
                            self.tableView.isUserInteractionEnabled = true
                            self.navigationItem.rightBarButtonItems?.last?.isEnabled = true
                            self.isSyncing = false
                            return
                        }
                        self.tableView.isUserInteractionEnabled = false
                        self.navigationItem.rightBarButtonItems?.last?.isEnabled = false
                        self.currentContacts = self.matchedUsers
                        print(self.currentContacts!.count)
                        if !snapshot.isEmpty {
                            self.matchedUsers.removeAll()
                            self.users.removeAll()
                            self.sectionTitleList = []
                            
                            for userDictionary in snapshot.documents {
                                let userDictionary = userDictionary.data() as NSDictionary
                                
                                let fUser = FUser(_dictionary: userDictionary)
                                
                                if fUser.objectId != FUser.currentId(), !(FUser.currentUser()?.blockedUsers.contains(fUser.objectId))! {
                                    self.users.append(fUser)
                                }
                            }
                        }
                        
                        self.workItem = DispatchWorkItem {
                            self.compareUsers()
                            
                            DispatchQueue.main.async {
                                self.splitDataInToSection()
                            }
                        }
                        let queue = DispatchQueue.global()
                        queue.async {
                            self.workItem?.perform()
                        }
                    }
                }
            }
        }
    }
    
    func loadAddedUsers() {
        //  ProgressHUD.show()
        reference(.Contact).whereField("userID", isEqualTo: FUser.currentId()).addSnapshotListener { snapshot, _ in
            self.tableView.emptyDataSetDelegate = self
            self.tableView.emptyDataSetSource = self
            guard let snapshot = snapshot else {
                ProgressHUD.dismiss()
                self.tableView.isUserInteractionEnabled = true
                self.navigationItem.rightBarButtonItems?.last?.isEnabled = true
                return
            }
            
            var contactsForUser = [String]()
            if !snapshot.isEmpty {
                for userDictionary in snapshot.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    
                    contactsForUser = userDictionary["contacts"] as! [String]
                }
                if contactsForUser.count == 0 {
                    self.tableView.isUserInteractionEnabled = true
                    if !(self.isGroup || self.isInviting) {
                        self.navigationItem.rightBarButtonItems?.last?.isEnabled = true
                    }
                    self.splitDataInToSection()
                } else {
                    getUsersFromFirestore(withIds: contactsForUser) { users in
                        self.matchedUsers = users.sorted { $0.fullname < $1.fullname }
                        self.tableView.isUserInteractionEnabled = true
                        if !(self.isGroup || self.isInviting) {
                            self.navigationItem.rightBarButtonItems?.last?.isEnabled = true
                        }
                        self.splitDataInToSection()
                    }
                }
            } else if snapshot.isEmpty {
                self.checkForNoData()
                self.tableView.reloadEmptyDataSet()
                
                if !(self.isGroup || self.isInviting) {
                    self.navigationItem.rightBarButtonItems?.last?.isEnabled = true
                }
                ProgressHUD.dismiss()
            }
        }
    }
    
    // MARK: Contacts
    
    func searchForContactUsingPhoneNumber(phoneNumber: String) -> [CNContact] {
        var result: [CNContact] = []
        
        // go through all contacts
        for contact in contacts {
            if !contact.phoneNumbers.isEmpty {
                // get the digits only of the phone number and replace + with 00
                let phoneNumberToCompareAgainst = updatePhoneNumber(phoneNumber: phoneNumber, replacePlusSign: true)
                
                // go through every number of each contac
                for phoneNumber in contact.phoneNumbers {
                    let fulMobNumVar = phoneNumber.value
                    let countryCode = fulMobNumVar.value(forKey: "countryCode") as? String
                    let phoneNumber = fulMobNumVar.value(forKey: "digits") as? String
                    
                    let contactNumber = removeCountryCode(countryCodeLetters: countryCode!, fullPhoneNumber: phoneNumber!)
                    
                    // compare phoneNumber of contact with given user's phone number
                    if contactNumber == phoneNumberToCompareAgainst {
                        result.append(contact)
                    }
                }
            }
        }
        
        return result
    }
    
    func updatePhoneNumber(phoneNumber: String, replacePlusSign: Bool) -> String {
        if replacePlusSign {
            return phoneNumber.replacingOccurrences(of: "+", with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
            
        } else {
            return phoneNumber.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        }
    }
    
    func removeCountryCode(countryCodeLetters: String, fullPhoneNumber: String) -> String {
        let countryCode = CountryCode()
        
        let countryCodeToRemove = countryCode.codeDictionaryShort[countryCodeLetters.uppercased()]
        
        // remove + from country code
        let updatedCode = updatePhoneNumber(phoneNumber: countryCodeToRemove!, replacePlusSign: true)
        
        // remove countryCode
        let replacedNUmber = fullPhoneNumber.replacingOccurrences(of: updatedCode, with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        
        //        print("Code \(countryCodeLetters)")
        //        print("full number \(fullPhoneNumber)")
        //        print("code to remove \(updatedCode)")
        //        print("clean number is \(replacedNUmber)")
        
        return replacedNUmber
    }
    
    fileprivate func splitDataInToSection() {
        // set section title "" at initial
        var sectionTitle: String = ""
        
        checkForNoData()
        // iterate all records from array
        print("from sdis: \(matchedUsers.count)")
        for i in 0..<matchedUsers.count {
            // get current record
            let currentUser = matchedUsers[i]
            
            // find first character from current record
            let firstChar = currentUser.firstname.first!
            
            // convert first character into string
            let firstCharString = "\(firstChar)"
            // if first character not match with past section title then create new section
            if firstCharString != sectionTitle {
                // set new title for section
                sectionTitle = firstCharString
                
                // add new section having key as section title and value as empty array of string
                allUsersGrouped[sectionTitle] = []
                
                // append title within section title list
                if !sectionTitleList.contains(sectionTitle) {
                    sectionTitleList.append(sectionTitle)
                }
            }
            
            // add record to the section
            print("NAME: \(currentUser.fullname)")
            allUsersGrouped[firstCharString]?.append(currentUser)
        }
        //    ProgressHUD.dismiss()
        UIView.transition(with: tableView, duration: 0.2, options: .transitionCrossDissolve, animations: { self.tableView.reloadData() }, completion: nil)
    }
    
    // MARK: Search controller functions
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        filteredMatchedUsers = matchedUsers.filter { (user) -> Bool in
            user.fullname.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    // MARK: UserTableViewCell delegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        var user: FUser!
        
        if searchController.isActive, searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            let sectionTitle = sectionTitleList[indexPath.section]
            
            let users = allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        
        profileVC.user = user
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    // MARK: Helpers
    
    func setupButtons() {
        emptySetDescription = "Your contacts will appear here. You can add someone by swiping or on their profile."
        if isGroup, !isInviting {
            let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextButtonPressed))
            navigationItem.rightBarButtonItem = nextButton
            navigationItem.rightBarButtonItems!.first!.isEnabled = false
        } else if isInviting {
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonPressed))
            navigationItem.rightBarButtonItem = doneButton
            navigationItem.rightBarButtonItems!.first!.isEnabled = false
        } else {
            emptySetDescription = "Your contacts will appear here. Tap sync button to sync your phone contacts or search for other users."
            let inviteImage = UIImage(systemName: "square.and.arrow.up.fill")
            let syncImage = UIImage(systemName: "arrow.2.circlepath.circle")
            let nearMeImage = UIImage(systemName: "paperplane.fill")
            
            let inviteButtonItem = createButtonItem(image: inviteImage!, selector: #selector(inviteButtonPressed), width: 35, height: 35)
            
            let searchButtonItem = createButtonItem(image: nearMeImage!, selector: #selector(searchNearByButtonPressed), width: 35, height: 35)
            
            let syncContactsButtonItem = createButtonItem(image: syncImage!, selector: #selector(syncButtonPressed), width: 35, height: 35)
            
            navigationItem.rightBarButtonItems = [inviteButtonItem, searchButtonItem, syncContactsButtonItem]
        }
    }
    
    func createButtonItem(image: UIImage, selector: Selector, width: CGFloat, height: CGFloat) -> UIBarButtonItem {
        let button: UIButton = UIButton(type: UIButton.ButtonType.custom)
        button.tintColor = .label
        button.setImage(image, for: UIControl.State.normal)
        button.addTarget(self, action: selector, for: UIControl.Event.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: width, height: height)
        return UIBarButtonItem(customView: button)
    }
    
    func updateGroup(group: NSDictionary) {
        let tempMembers = currentMembersIds + memberIdsOfGroupChat
        let tempMembersToPush = group[kMEMBERSTOPUSH] as! [String] + memberIdsOfGroupChat
        
        let withValues = [kMEMBERS: tempMembers, kMEMBERSTOPUSH: tempMembersToPush]
        
        for memberId in memberIdsOfGroupChat {
            sendSystemMessage(text: "a-" + matchedUsers.filter{$0.objectId == memberId}[0].fullname + "-" + memberId, chatRoomId: group[kGROUPID] as! String, memberIds: tempMembers, membersToPush: [], group: group)
        }
        
        Group.updateGroup(groupId: group[kGROUPID] as! String, withValues: withValues)
        
        createRecentsForNewMembers(groupId: group[kGROUPID] as! String, groupName: group[kNAME] as! String, membersToPush: tempMembersToPush, avatar: group[kAVATAR] as! String)
        
        updateExistingRecentWithNewValues(forMembers: tempMembers, chatRoomId: group[kGROUPID] as! String, withValues: withValues)
        
        let i = navigationController?.viewControllers.firstIndex(of: self)
        if let previousViewController = navigationController?.viewControllers[i! - 1] as? GroupTableViewController {
            navigationController?.popViewController(animated: true)
        }
    }
}

extension ContactsTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        if searchController.isActive && searchController.searchBar.text != "" {
            return UIImage()
        }
        return UIImage(named: "astronaut")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if searchController.isActive && searchController.searchBar.text != "" {
            return NSAttributedString(string: "NO RESULTS", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0)])
        }
        return NSAttributedString(string: "NO CONTACTS", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0)])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if searchController.isActive && searchController.searchBar.text != "" {
            return NSAttributedString(string: "No results found for \"\(searchController.searchBar.text ?? "your search")\"", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)])
        }
        return NSAttributedString(string: emptySetDescription, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)])
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        if searchController.isActive && searchController.searchBar.text != "" {
            return NSAttributedString()
        }
        return NSAttributedString(string: "Explore other users", attributes: [NSAttributedString.Key.foregroundColor: UIColor.getAppColor(.light), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)])
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        if searchController.isActive && searchController.searchBar.text != "" {
            return
        }
        let userVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "usersTableView") as! UsersTableViewController
        userVC.delegate = self
        navigationController?.pushViewController(userVC, animated: true)
    }
}
