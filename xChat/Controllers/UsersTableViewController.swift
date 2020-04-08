//
//  UsersTableViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 18.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import ProgressHUD

protocol UsersDelegate {
    func didAddNewContacts()
}

class UsersTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!
    
    var delegate: UsersDelegate?
    
    var allUsers: [FUser] = []
    var filteredUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList : [String] = []
    var contacts: [String] = []
    var firstLoad = false
    let searchController = UISearchController(searchResultsController: nil)
    var searchTxt = ""
    var scope = ""
    var lastDocumentSnapshot: DocumentSnapshot!
    var fetchingMore = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.separatorStyle = .none
        getContacts()
        firstLoad = true
        loadUsers(filter: kCITY)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !firstLoad {
            getContacts()
        } else {
            firstLoad = false
        }
    }
    
    
    func getContacts()  {
        reference(.Contact).whereField("userID", isEqualTo: FUser.currentId()).getDocuments { (snapshot, error) in
            if error != nil {
                ProgressHUD.showError("Could not fetch contacts")
                return
            }
            guard snapshot != nil else {
                return
            }
            if !snapshot!.isEmpty {
                for userDictionary in snapshot!.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    
                    self.contacts = (userDictionary["contacts"] as! [String])
                }
            }
        }
    }
    
    
    // MARK: - Table view data source

    @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {
        searchController.isActive = false
        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
            scope = kCITY
            fetchingMore = false
            lastDocumentSnapshot = nil
        case 1:
            loadUsers(filter: kCOUNTRY)
            scope = kCOUNTRY
             fetchingMore = false
             lastDocumentSnapshot = nil
        case 2:
            loadUsers(filter: "")
            scope = ""
             fetchingMore = false
             lastDocumentSnapshot = nil
        default:
            return
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        }
        else {
            return allUsersGrouped.count
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUsers.count
        }
        else {
            let sectionTitle = self.sectionTitleList[section]
            let users = allUsersGrouped[sectionTitle]
            return users!.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var tempUser: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            tempUser = filteredUsers[indexPath.row]
        }
        else {
            let sectionTitle = sectionTitleList[indexPath.section]
            tempUser = allUsersGrouped[sectionTitle]![indexPath.row]
        }
        
        
        var isInContacts = false
        
        if contacts.contains(tempUser.objectId) {
            isInContacts = true
        }
        
        let contactAction = UIContextualAction(style: .normal, title: nil) { (action, view, success) in
            if isInContacts {
                self.removeContact(id: tempUser.objectId)
                
                isInContacts = false
                UIView.transition(with: tableView, duration: 0.1, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
            } else {
                self.addContact(id: tempUser.objectId)
                isInContacts = true
                UIView.transition(with: tableView, duration: 0.1, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
            }
            self.delegate?.didAddNewContacts()
        }
        
        contactAction.backgroundColor = UIColor.systemBackground
        
        var contactImg = UIGraphicsImageRenderer(size: CGSize(width: 25, height: 25)).image {
            _ in
            
            if isInContacts {
                UIImage(systemName: "person.badge.minus")?.draw(in: CGRect(x: 0, y: 0, width: 25, height: 25))
            } else {
                UIImage(systemName: "person.badge.plus")?.draw(in: CGRect(x: 0, y: 0, width: 25, height: 25))
            }
        }
        contactImg = isInContacts ? contactImg.imageWithColor(color1: UIColor.systemRed) : contactImg.imageWithColor(color1: UIColor.getAppColor(.light))
        contactAction.image = contactImg
        
        return  UISwipeActionsConfiguration(actions: [contactAction])
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func removeContact(id: String) {
        let index = contacts.firstIndex(of: id)
        contacts.remove(at: index!)
        
        let arr = contacts.filter { $0 != id }
        let dict = ["contacts" : arr] as [String : Any]
        reference(.Contact).document(FUser.currentId()).updateData(dict) { (error) in
            if error != nil {
                ProgressHUD.showError("COULD NOT DELETE")
            } else {
                ProgressHUD.showSuccess()
            }
        }
    }
    
    func addContact(id: String) {
        
        contacts.append(id)
        let dict = ["contacts" : contacts as Any, "userID" : FUser.currentId()] as [String : Any]
        
        if contacts.count == 1 {
            reference(.Contact).document(FUser.currentId()).setData(dict) { (error) in
                if error != nil {
                    print(error?.localizedDescription)
                    ProgressHUD.showError("COULD NOT ADD CONTACT")
                } else {
                    ProgressHUD.showSuccess()
                }
            }
        } else {
            reference(.Contact).document(FUser.currentId()).updateData(dict) { (error) in
                if error != nil {
                    print(error?.localizedDescription)
                    ProgressHUD.showError("COULD NOT ADD CONTACT")
                } else {
                    ProgressHUD.showSuccess()
                }
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        var user: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        }
        else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        cell.delegate = self
        return cell
    }
    
    //MARK: TableView Delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        }
        else {
            return sectionTitleList[section]
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        }
        else {
            return sectionTitleList
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

         view.tintColor = .secondarySystemBackground

         let header : UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
         
         header.textLabel?.textColor = .label

     }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var user: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        }
        else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        
        if !checkBlockedStatus(withUser: user){
            
            let chatVC = ChatViewController()
            chatVC.titleName = user.firstname
            chatVC.membersToPush = [FUser.currentId(), user.objectId]
            chatVC.memberIds = [FUser.currentId(), user.objectId]
            chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: user)
            chatVC.isGroup = false
            chatVC.initialWithUser = user.fullname
            let cell = tableView.cellForRow(at: indexPath) as! UserTableViewCell
            chatVC.initialImage = cell.avatarImage!.image
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
        else {
            ProgressHUD.showError("This user is not available for chat")
        }
    }
    
 
    
    func loadUsers(filter: String) {
        ProgressHUD.show()
        
        var query: Query!
        
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.limit(to: 10).getDocuments { (snapshot, error) in
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
                    
                    if(fUser.objectId != FUser.currentId() && !fUser.blockedUsers.contains(FUser.currentUser()!.objectId)) {
                        self.allUsers.append(fUser)
                    }
                }
                
                self.lastDocumentSnapshot = snapshot.documents.last!
                self.splitDataIntoSections()
                self.tableView.reloadData()
            }
            
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
           let offsetY = scrollView.contentOffset.y
           let contentHeight = scrollView.contentSize.height
           //print("offsetY: \(offsetY) | contHeight-scrollViewHeight: \(contentHeight-scrollView.frame.height)")
           if offsetY > contentHeight - scrollView.frame.height - 50 {
               // Bottom of the screen is reached
               if !fetchingMore {
                   if lastDocumentSnapshot != nil {
                       paginateData()
                   }
               }
           }
       }
    
    func paginateData() {
          fetchingMore = true
          print("hereeeee")
        
        var query: Query!
        
        switch scope {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.limit(to: 5).start(afterDocument: lastDocumentSnapshot).getDocuments { (snapshot, error) in
            //self.allUsers = []
        
            if error != nil {
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            
            guard let snapshot = snapshot else { ProgressHUD.dismiss(); return }
            
            if !snapshot.isEmpty {
                self.sectionTitleList = []
                        self.allUsersGrouped = [:]
                for userDictionary in snapshot.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)
                    
                    if(fUser.objectId != FUser.currentId() && !fUser.blockedUsers.contains(FUser.currentUser()!.objectId)) {
                        self.allUsers.append(fUser)
                      }
                  }
                  
                  self.lastDocumentSnapshot = snapshot.documents.last!
                  self.splitDataIntoSections()
                  self.tableView.reloadData()
              }
              
              self.tableView.reloadData()
      }
    }
    
    
    //MARK: Search controller functions
    
    
    
    func updateSearchResults(for searchController: UISearchController) {
        
      
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(filterContentForSearchText), object: nil)
         searchTxt = searchController.searchBar.text!.lowercased().removeExtraSpaces()
        self.perform(#selector(filterContentForSearchText), with: nil, afterDelay: 0.5)
   
      
    }
    
    
    @objc func filterContentForSearchText() {
        //        filteredUsers = allUsers.filter({ (user) -> Bool in
        //            return user.fullname.lowercased().contains(searchText.lowercased())
        //        })        self.filteredUsers = []
        
        
        filteredUsers = []
        tableView.reloadData()
        
       
        reference(.UserKeywords).whereField("keywords", arrayContains: searchTxt).getDocuments { (snapshot, error) in
            print("hereeeeeeeeeeee")
            if error != nil {
                ProgressHUD.showError("Could not fetch contacts")
                return
            }
            guard snapshot != nil else {
                return
            }
            if !snapshot!.isEmpty {
                var users: [String] = []
                for doc in snapshot!.documents {
                    users.append(doc["userId"] as! String)
                }
                
                getUsersFromFirestore(withIds: users) { (foundUsers) in
                    print("********\(foundUsers.count)")
                    self.filteredUsers = []
                    self.filteredUsers = foundUsers.sorted(by: { $0.fullname < $1.fullname }).filter({ (user) -> Bool in
                        switch self.scope {
                        case kCITY:
                            return user.city == FUser.currentUser()!.city
                        case kCOUNTRY:
                            return user.country == FUser.currentUser()!.country
                        default:
                            return true
                        }
                    })
                    self.tableView.reloadData()
                }
            }
        }
        
        
        
        
        
    }
    
    func splitDataIntoSections() {
        
        var sectionTitle: String = ""
        
        for i in 0..<allUsers.count {
            let currentUser = allUsers[i]
            let firstCharacter = String(currentUser.firstname.first!)
            
            if firstCharacter != sectionTitle {
                sectionTitle = firstCharacter
                self.allUsersGrouped[sectionTitle] = []
                self.sectionTitleList.append(sectionTitle)
            }
            
            self.allUsersGrouped[sectionTitle]?.append(currentUser)
        }
    }
    
    //MARK: UserTableViewCellDelegate
    func didTapAvatarImage(indexPath: IndexPath) {
        
        print("user avatar tapped at: \(indexPath)")
        let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        var user: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        }
        else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]        }
        
        viewController.user = user
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
