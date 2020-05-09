//
//  CallTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 18.3.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseFirestore

class CallTableViewController: UITableViewController, UISearchResultsUpdating {
    
    var allCalls: [CallClass] = []
    var filteredCalls: [CallClass] = []
    var firstLoadFinished = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let searchController = UISearchController(searchResultsController: nil)
    var callListener: ListenerRegistration!
    
    override func viewWillAppear(_ animated: Bool) {
       loadCalls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        callListener.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        navigationItem.searchController = searchController
                tableView.separatorInset = UIEdgeInsets(top: 0, left: 45, bottom: 0, right: 0)
        navigationItem.hidesSearchBarWhenScrolling = true
        
         self.navigationController?.navigationBar.shadowImage = UIImage()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        loadCalls()
    }
    
    var firstLoad = false
    //MARK: TableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredCalls.count
        }
        return allCalls.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CallTableViewCell
        cell.selectionStyle = .none
        var call: CallClass!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            call = filteredCalls[indexPath.row]
        } else {
            call = allCalls[indexPath.row]
        }
        
        cell.generateCellWith(call: call)
        
        return cell
    }
    
    
    //MARK: TableViewDelegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            var tempCall: CallClass!
            
            if searchController.isActive && searchController.searchBar.text != "" {
                tempCall = filteredCalls[indexPath.row]
                filteredCalls.remove(at: indexPath.row)
            } else {
                tempCall = allCalls[indexPath.row]
                allCalls.remove(at: indexPath.row)
            }
            
            tempCall.deleteCall()
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = .zero
    }
    
    //MARK: LoadCalls
    
    var lastDocumentSnapshot: DocumentSnapshot!
    var fetchingMore = false
    var allCallsNumber = 0
    
    func loadCalls() {
        
        callListener = reference(.Call).document(FUser.currentId()).collection(FUser.currentId()).order(by: kDATE, descending: true).addSnapshotListener({ (snapshot, error) in
       
            let callsToShow = self.allCalls.isEmpty ? 10 : (self.allCalls.count < 10 ? 10 : self.allCalls.count)
            print("-- - - - - ------ \(callsToShow)")
            self.allCalls = []
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                self.allCallsNumber = snapshot.documents.count
                let sortedDictionary = dictionaryFromSnapshots(snapshots: (snapshot.documents), endIndex: callsToShow)
                print("e\(sortedDictionary.count)")
                for callDictionary in sortedDictionary {
                    
//                    print("all calls --- \(self.allCalls.count)")
//                    print("calls to show  --- \(callsToShow)")
//                    print("all docs  --- \(snapshot.documents.count)")
//
                    
                    let call = CallClass(_dictionary: callDictionary)
                    self.allCalls.append(call)
                    
        
                    if self.allCalls.count == callsToShow || self.allCalls.count == snapshot.documents.count {
                        self.lastDocumentSnapshot = snapshot.documents[self.allCalls.count-1]
                        self.tableView.restore()
                        self.tableView.reloadData()
                        return
                    }
                }
                if self.allCalls.count == 0 {
                    self.tableView.setEmptyMessage("No calls")
                } else {
                    self.tableView.restore()
                }
                
            } else {
                  self.tableView.setEmptyMessage("No calls")
                
            }
        })
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
     
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        //print("offsetY: \(offsetY) | contHeight-scrollViewHeight: \(contentHeight-scrollView.frame.height)")
        if offsetY > contentHeight - scrollView.frame.height - 50 {
            // Bottom of the screen is reached
            if !fetchingMore {
                if lastDocumentSnapshot != nil && allCallsNumber != allCalls.count{
                    //print("\(allCallsNumber) ---- \(allCalls.count)")
                    paginateData()
                }
            }
        }
    }
    
    func paginateData() {
        fetchingMore = true
        print("hereeeee")
        reference(.Call).document(FUser.currentId()).collection(FUser.currentId()).order(by: kDATE, descending: true).start(afterDocument: lastDocumentSnapshot).limit(to: 5).getDocuments { (snapshot, err) in
            
            if let err = err {
                print("\(err.localizedDescription)")
                  self.tableView.setEmptyMessage("No calls")
            } else if snapshot!.isEmpty {
                self.fetchingMore = false
                  self.tableView.setEmptyMessage("No calls")
                return
            } else {
                let sortedDictionary = dictionaryFromSnapshots(snapshots: snapshot!.documents)
                
                for callDictionary in sortedDictionary {
                    let call = CallClass(_dictionary: callDictionary)
                    self.allCalls.append(call)
                    
                }
                if self.allCalls.count == 0 {
                                  self.tableView.setEmptyMessage("No calls")
                              } else {
                                  self.tableView.restore()
                              }
                              
               
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.tableView.reloadData()
                    self.fetchingMore = false
                     self.lastDocumentSnapshot = snapshot!.documents.last
                })
                
            }
        }
    }
   
    var callInProgress = true
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if checkMicPermission(viewController: self) {
            tableView.isUserInteractionEnabled = false
            
            var user: FUser!
            var userId: String!
            if searchController.isActive && searchController.searchBar.text != "" {
                if filteredCalls[indexPath.row].callerId == FUser.currentId() {
                    userId = filteredCalls[indexPath.row].withUserId
                } else {
                    userId = filteredCalls[indexPath.row].callerId
                }
                
                getUsersFromFirestore(withIds: [userId]) { (users) in
                    user = users[0]
                    self.callUser(user: user)
                    tableView.isUserInteractionEnabled = true
                }
            } else {
                if allCalls[indexPath.row].callerId == FUser.currentId() {
                    userId = allCalls[indexPath.row].withUserId
                } else {
                    userId = allCalls[indexPath.row].callerId
                }
                
                getUsersFromFirestore(withIds: [userId]) { (users) in
                    user = users[0]
                    self.callUser(user: user)
                    tableView.isUserInteractionEnabled = true
                }
            }
        }
        
        
    }
    
    func callClient() -> SINCallClient?{
        let scene = UIApplication.shared.connectedScenes.first
        if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
            return  sd._client.call()
        }
        return nil
    }
    
    func callUser(user: FUser) {
        
        if checkMicPermission(viewController: self) {
            let currentUser = FUser.currentUser()!
            
            let callToSave = CallClass(_callerId: currentUser.objectId, _withUserId: user.objectId, _callerFullName: currentUser.fullname, _withUserFullName: user.fullname)
            
            let userToCall = user.objectId
            let call = callClient()?.callUser(withId: userToCall)
            let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CallVC") as! CallViewController
            callVC._call = call
            callVC.callingName = user.fullname
            self.present(callVC, animated: true, completion: nil)
            callToSave.saveCallInBackground()
        }
        
    }
    
    
    //MARK: Search controller
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredCalls = allCalls.filter({ (call) -> Bool in
            
            var callerName: String!
            
            if call.callerId == FUser.currentId() {
                callerName = call.withUserFullName
            } else {
                callerName = call.callerFullName
            }
            
            return (callerName).lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    
    
}
